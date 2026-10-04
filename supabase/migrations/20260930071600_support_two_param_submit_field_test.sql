-- Migration: Support 2-parameter and 3-parameter submit_field_test RPC calls
-- Resolves "Could not find the function public.submit_field_test(p_answer, p_test_id) in the schema cache"
-- Allows client to submit without explicitly sending p_user_id (uses auth.uid() automatically, or accepts p_user_id)

-- 1. Create or replace the 2-parameter / defaulted version: submit_field_test(p_test_id, p_answer, p_user_id)
CREATE OR REPLACE FUNCTION public.submit_field_test(
  p_test_id UUID,
  p_answer TEXT,
  p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_effective_user_id UUID;
  v_test RECORD;
  v_current_user RECORD;
  v_expected_answer TEXT;
  v_submitted_answer TEXT;
  v_new_clearance INT;
  v_new_points INT;
BEGIN
  -- Determine user ID securely from parameter or auth session
  v_effective_user_id := COALESCE(p_user_id, auth.uid());

  IF v_effective_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Operative authentication required. Re-authenticate to submit assessment.'
    );
  END IF;

  -- Locate field test and parent dossier
  SELECT 
    ft.id,
    ft.dossier_id,
    ft.scenario_description,
    ft.test_type,
    ft.passing_criteria,
    d.required_clearance,
    d.title AS dossier_title
  INTO v_test
  FROM public.field_tests ft
  JOIN public.dossiers d ON d.id = ft.dossier_id
  WHERE ft.id = p_test_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Field test assessment record not found.'
    );
  END IF;

  -- Retrieve current user profile
  SELECT clearance_level, intel_points INTO v_current_user
  FROM public.users
  WHERE id = v_effective_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Operative record not found in system directory.'
    );
  END IF;

  -- Validate answer against secret passing_criteria (case-insensitive & trimmed)
  v_expected_answer := LOWER(TRIM(COALESCE(
    v_test.passing_criteria->>'correct_answer',
    v_test.passing_criteria->>'expected',
    ''
  )));

  v_submitted_answer := LOWER(TRIM(COALESCE(p_answer, '')));

  IF v_submitted_answer = '' OR v_submitted_answer <> v_expected_answer THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Assessment Failed: Submitted operational answer is incorrect. Review foundational briefs and reattempt.',
      'error_code', 'INCORRECT_ANSWER'
    );
  END IF;

  -- Compute upgraded clearance and points
  v_new_clearance := LEAST(4, GREATEST(v_current_user.clearance_level, v_test.required_clearance));
  v_new_points := v_current_user.intel_points + 100;

  -- Update users table
  UPDATE public.users
  SET 
    clearance_level = v_new_clearance,
    intel_points = v_new_points
  WHERE id = v_effective_user_id;

  -- Record user progress
  INSERT INTO public.user_progress (user_id, dossier_id, status, completed_at)
  VALUES (v_effective_user_id, v_test.dossier_id, 'completed', timezone('utc'::text, now()))
  ON CONFLICT (user_id, dossier_id) DO UPDATE
  SET status = 'completed', completed_at = timezone('utc'::text, now());

  -- Return success payload
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Field test passed successfully! Security clearance elevated.',
    'previous_clearance', v_current_user.clearance_level,
    'new_clearance_level', v_new_clearance,
    'new_intel_points', v_new_points,
    'dossier_id', v_test.dossier_id,
    'dossier_title', v_test.dossier_title
  );
END;
$$;

-- 2. Also ensure the 3-parameter overload with p_user_id as second argument forwards cleanly
CREATE OR REPLACE FUNCTION public.submit_field_test(
  p_test_id UUID,
  p_user_id UUID,
  p_answer TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN public.submit_field_test(
    p_test_id := p_test_id,
    p_answer := p_answer,
    p_user_id := p_user_id
  );
END;
$$;
