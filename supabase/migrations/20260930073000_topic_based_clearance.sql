-- Migration: Topic-Based Clearances and Area of Interest Specialization

-- 1. Add selected_topics and topic_clearances to public.users
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS selected_topics TEXT[] NOT NULL DEFAULT ARRAY['ALL'],
  ADD COLUMN IF NOT EXISTS topic_clearances JSONB NOT NULL DEFAULT '{}'::jsonb;

-- Initialize topic_clearances for existing users if empty
UPDATE public.users
SET 
  selected_topics = COALESCE(selected_topics, ARRAY['ALL']),
  topic_clearances = CASE 
    WHEN topic_clearances IS NULL OR topic_clearances = '{}'::jsonb THEN
      jsonb_build_object(
        'Internet Basics', jsonb_build_object('level', clearance_level, 'points', intel_points),
        'Security', jsonb_build_object('level', clearance_level, 'points', intel_points),
        'Workspace Ops', jsonb_build_object('level', clearance_level, 'points', intel_points),
        'Web Architecture', jsonb_build_object('level', clearance_level, 'points', intel_points),
        'System Architecture', jsonb_build_object('level', clearance_level, 'points', intel_points),
        'Design', jsonb_build_object('level', clearance_level, 'points', intel_points),
        'Artificial Intelligence', jsonb_build_object('level', clearance_level, 'points', intel_points),
        'Hardware & IoT', jsonb_build_object('level', clearance_level, 'points', intel_points),
        'Tech History', jsonb_build_object('level', clearance_level, 'points', intel_points)
      )
    ELSE topic_clearances
  END;

-- 2. Update user signup trigger to initialize selected_topics & topic_clearances
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (
    id,
    email,
    clearance_level,
    intel_points,
    selected_topics,
    topic_clearances
  )
  VALUES (
    NEW.id,
    NEW.email,
    1,
    0,
    ARRAY['ALL'],
    jsonb_build_object(
      'Internet Basics', jsonb_build_object('level', 1, 'points', 0),
      'Security', jsonb_build_object('level', 1, 'points', 0),
      'Workspace Ops', jsonb_build_object('level', 1, 'points', 0),
      'Web Architecture', jsonb_build_object('level', 1, 'points', 0),
      'System Architecture', jsonb_build_object('level', 1, 'points', 0),
      'Design', jsonb_build_object('level', 1, 'points', 0),
      'Artificial Intelligence', jsonb_build_object('level', 1, 'points', 0),
      'Hardware & IoT', jsonb_build_object('level', 1, 'points', 0),
      'Tech History', jsonb_build_object('level', 1, 'points', 0)
    )
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Update Row Level Security on public.dossiers to honor topic clearances
DROP POLICY IF EXISTS "Users can only select dossiers up to their clearance level" ON public.dossiers;

CREATE POLICY "Users can only select dossiers up to their clearance level"
  ON public.dossiers FOR SELECT
  USING (
    required_clearance <= COALESCE(
      (SELECT (topic_clearances->dossiers.category->>'level')::int FROM public.users WHERE id = auth.uid()),
      (SELECT clearance_level FROM public.users WHERE id = auth.uid()),
      1
    )
  );

-- 4. Add Design field test for Level 2 transition
DO $$
DECLARE
  v_design_id UUID;
BEGIN
  SELECT id INTO v_design_id FROM public.dossiers WHERE slug = 'design-literacy';
  IF v_design_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.field_tests WHERE dossier_id = v_design_id) THEN
    INSERT INTO public.field_tests (dossier_id, scenario_description, test_type, passing_criteria)
    VALUES (
      v_design_id,
      'Field Assessment: An operative is designing a tactical HUD with dense telemetry. Which core design principle should be applied to prevent cognitive overload and emphasize critical alert hierarchies?',
      'multiple_choice',
      jsonb_build_object(
        'options', jsonb_build_array(
          'Fill every pixel with flashing red banners',
          'Strategic Whitespace and Clear Typographic Hierarchy',
          'Use 6 different decorative fonts simultaneously',
          'Remove all borders and labels entirely'
        ),
        'correct_answer', 'Strategic Whitespace and Clear Typographic Hierarchy'
      )
    );
  END IF;
END;
$$;

-- 5. RPC to update user's areas of interest
CREATE OR REPLACE FUNCTION public.update_user_interests(p_selected_topics TEXT[])
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_user_email TEXT;
  v_updated_user public.users%ROWTYPE;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'Unauthorized: User session required.');
  END IF;

  -- Ensure user profile exists (upsert)
  SELECT email INTO v_user_email FROM auth.users WHERE id = v_user_id;

  INSERT INTO public.users (
    id,
    email,
    clearance_level,
    intel_points,
    selected_topics,
    topic_clearances
  )
  VALUES (
    v_user_id,
    COALESCE(v_user_email, ''),
    1,
    0,
    p_selected_topics,
    jsonb_build_object(
      'Internet Basics', jsonb_build_object('level', 1, 'points', 0),
      'Security', jsonb_build_object('level', 1, 'points', 0),
      'Workspace Ops', jsonb_build_object('level', 1, 'points', 0),
      'Web Architecture', jsonb_build_object('level', 1, 'points', 0),
      'System Architecture', jsonb_build_object('level', 1, 'points', 0),
      'Design', jsonb_build_object('level', 1, 'points', 0),
      'Artificial Intelligence', jsonb_build_object('level', 1, 'points', 0),
      'Hardware & IoT', jsonb_build_object('level', 1, 'points', 0),
      'Tech History', jsonb_build_object('level', 1, 'points', 0)
    )
  )
  ON CONFLICT (id) DO UPDATE
  SET selected_topics = EXCLUDED.selected_topics
  RETURNING * INTO v_updated_user;

  RETURN jsonb_build_object(
    'success', true,
    'selected_topics', v_updated_user.selected_topics
  );
END;
$$;

-- 6. Unified submit_field_test honoring topic-based clearance
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
  v_target_user_id UUID;
  v_test RECORD;
  v_current_user RECORD;
  v_expected_answer TEXT;
  v_submitted_answer TEXT;
  v_current_topic_level INT;
  v_new_topic_level INT;
  v_current_topic_points INT;
  v_new_topic_points INT;
  v_updated_topic_clearances JSONB;
  v_overall_clearance INT;
  v_new_points INT;
BEGIN
  -- Determine target user ID (use explicit parameter or fallback to auth.uid())
  v_target_user_id := COALESCE(p_user_id, auth.uid());

  IF v_target_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Unauthorized: User identification missing.'
    );
  END IF;

  -- Fetch field test, linked dossier details, and category
  SELECT 
    ft.id AS test_id,
    ft.passing_criteria,
    ft.test_type,
    d.id AS dossier_id,
    d.title AS dossier_title,
    d.category AS dossier_category,
    d.required_clearance
  INTO v_test
  FROM public.field_tests ft
  JOIN public.dossiers d ON d.id = ft.dossier_id
  WHERE ft.id = p_test_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Assessment protocol not found in intelligence registry.'
    );
  END IF;

  -- Fetch current user record
  SELECT clearance_level, intel_points, topic_clearances INTO v_current_user
  FROM public.users
  WHERE id = v_target_user_id;

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

  -- Read current topic level and points for this category
  v_current_topic_level := COALESCE((v_current_user.topic_clearances->v_test.dossier_category->>'level')::int, v_current_user.clearance_level, 1);
  v_current_topic_points := COALESCE((v_current_user.topic_clearances->v_test.dossier_category->>'points')::int, 0);

  -- Compute upgraded clearance for this topic
  v_new_topic_level := LEAST(4, GREATEST(v_current_topic_level, v_test.required_clearance));
  v_new_topic_points := v_current_topic_points + 100;
  v_new_points := v_current_user.intel_points + 100;

  -- Build updated topic_clearances JSONB
  v_updated_topic_clearances := jsonb_set(
    COALESCE(v_current_user.topic_clearances, '{}'::jsonb),
    ARRAY[v_test.dossier_category],
    jsonb_build_object('level', v_new_topic_level, 'points', v_new_topic_points),
    true
  );

  -- Compute overall clearance as max across all topics
  SELECT COALESCE(MAX((val->>'level')::int), v_new_topic_level)
  INTO v_overall_clearance
  FROM jsonb_each(v_updated_topic_clearances) AS kv(key, val);

  -- Update users table with tailored topic clearance
  UPDATE public.users
  SET 
    clearance_level = GREATEST(clearance_level, v_overall_clearance),
    intel_points = v_new_points,
    topic_clearances = v_updated_topic_clearances
  WHERE id = v_target_user_id;

  -- Record user progress
  INSERT INTO public.user_progress (user_id, dossier_id, status, completed_at)
  VALUES (v_target_user_id, v_test.dossier_id, 'completed', timezone('utc'::text, now()))
  ON CONFLICT (user_id, dossier_id) DO UPDATE
  SET status = 'completed', completed_at = timezone('utc'::text, now());

  -- Return comprehensive payload tailored to topic
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Field test passed successfully! Security clearance elevated in ' || v_test.dossier_category || '.',
    'category', v_test.dossier_category,
    'previous_topic_clearance', v_current_topic_level,
    'new_topic_clearance', v_new_topic_level,
    'previous_clearance', v_current_user.clearance_level,
    'new_clearance_level', GREATEST(v_current_user.clearance_level, v_overall_clearance),
    'new_intel_points', v_new_points,
    'dossier_id', v_test.dossier_id,
    'dossier_title', v_test.dossier_title,
    'topic_clearances', v_updated_topic_clearances
  );
END;
$$;
