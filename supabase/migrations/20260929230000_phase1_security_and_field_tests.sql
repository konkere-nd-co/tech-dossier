-- Phase 1 Migration: Backend Security, Row Level Security, and submit_field_test RPC

-- 1. Enforce strict Row Level Security (RLS) on public.dossiers
-- Users can only SELECT dossiers where required_clearance <= their clearance_level in public.users
DROP POLICY IF EXISTS "Public dossiers are viewable by everyone" ON public.dossiers;
DROP POLICY IF EXISTS "Users can only select dossiers up to their clearance level" ON public.dossiers;
DROP POLICY IF EXISTS "Users can select dossiers up to their clearance level" ON public.dossiers;

CREATE POLICY "Users can only select dossiers up to their clearance level"
  ON public.dossiers FOR SELECT
  USING (
    required_clearance <= COALESCE(
      (SELECT clearance_level FROM public.users WHERE id = auth.uid()),
      1
    )
  );

-- 2. Seed Field Tests for transitioning between clearance tiers
-- Insert field tests linked to Level 2, Level 3, and Level 4 dossiers
DO $$
DECLARE
  v_web_arch_id UUID;
  v_api_id UUID;
  v_db_id UUID;
  v_ai_id UUID;
  v_iot_id UUID;
  v_browser_wars_id UUID;
BEGIN
  SELECT id INTO v_web_arch_id FROM public.dossiers WHERE slug = 'web-architecture';
  SELECT id INTO v_api_id FROM public.dossiers WHERE slug = 'what-is-an-api';
  SELECT id INTO v_db_id FROM public.dossiers WHERE slug = 'databases-explained';
  SELECT id INTO v_ai_id FROM public.dossiers WHERE slug = 'ai-and-llms';
  SELECT id INTO v_iot_id FROM public.dossiers WHERE slug = 'iot-hardware';
  SELECT id INTO v_browser_wars_id FROM public.dossiers WHERE slug = 'browser-wars';

  -- Level 2 Transition Test: Web Architecture
  IF v_web_arch_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.field_tests WHERE dossier_id = v_web_arch_id) THEN
    INSERT INTO public.field_tests (dossier_id, scenario_description, test_type, passing_criteria)
    VALUES (
      v_web_arch_id,
      'Field Assessment: Identify the core browser technology responsible for event-driven behavior, real-time DOM manipulation, and dynamic client-side logic.',
      'multiple_choice',
      jsonb_build_object(
        'options', jsonb_build_array('HTML', 'CSS', 'JavaScript', 'SQL'),
        'correct_answer', 'JavaScript'
      )
    );
  END IF;

  -- Level 2 Transition Test: API Logic
  IF v_api_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.field_tests WHERE dossier_id = v_api_id) THEN
    INSERT INTO public.field_tests (dossier_id, scenario_description, test_type, passing_criteria)
    VALUES (
      v_api_id,
      'Field Assessment: In modern distributed architectures, which protocol is universally used by RESTful APIs to transport client requests and JSON payloads?',
      'multiple_choice',
      jsonb_build_object(
        'options', jsonb_build_array('FTP', 'HTTP/HTTPS', 'SMTP', 'SSH'),
        'correct_answer', 'HTTP/HTTPS'
      )
    );
  END IF;

  -- Level 2 Transition Test: Databases
  IF v_db_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.field_tests WHERE dossier_id = v_db_id) THEN
    INSERT INTO public.field_tests (dossier_id, scenario_description, test_type, passing_criteria)
    VALUES (
      v_db_id,
      'Field Assessment: An operative requires ACID guarantees, foreign key relational integrity, and structured SQL schemas. Which persistence engine should be deployed?',
      'multiple_choice',
      jsonb_build_object(
        'options', jsonb_build_array('MongoDB', 'PostgreSQL', 'Redis Key-Value', 'CSV File'),
        'correct_answer', 'PostgreSQL'
      )
    );
  END IF;

  -- Level 3 Transition Test: AI & LLMs
  IF v_ai_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.field_tests WHERE dossier_id = v_ai_id) THEN
    INSERT INTO public.field_tests (dossier_id, scenario_description, test_type, passing_criteria)
    VALUES (
      v_ai_id,
      'Field Assessment: Large Language Models (LLMs) do not possess biological consciousness. Mechanistically, how do they produce coherent sentences?',
      'multiple_choice',
      jsonb_build_object(
        'options', jsonb_build_array(
          'By reading the operator''s thoughts via telemetry',
          'By calculating the statistically most probable next token/word',
          'By pulling static encyclopedia articles from ROM',
          'By executing random CPU instructions'
        ),
        'correct_answer', 'By calculating the statistically most probable next token/word'
      )
    );
  END IF;

  -- Level 3 Transition Test: IoT
  IF v_iot_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.field_tests WHERE dossier_id = v_iot_id) THEN
    INSERT INTO public.field_tests (dossier_id, scenario_description, test_type, passing_criteria)
    VALUES (
      v_iot_id,
      'Field Assessment: Which hardware subsystem bridges physical reality with software by translating analog temperature or light into digital data?',
      'multiple_choice',
      jsonb_build_object(
        'options', jsonb_build_array('Sensor', 'Compiler', 'CSS Stylesheet', 'DNS Resolver'),
        'correct_answer', 'Sensor'
      )
    );
  END IF;

  -- Level 4 Transition Test: Browser Wars
  IF v_browser_wars_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.field_tests WHERE dossier_id = v_browser_wars_id) THEN
    INSERT INTO public.field_tests (dossier_id, scenario_description, test_type, passing_criteria)
    VALUES (
      v_browser_wars_id,
      'Field Assessment: What international standards organization was established to preserve open, interoperable web specifications and prevent proprietary fragmentation?',
      'multiple_choice',
      jsonb_build_object(
        'options', jsonb_build_array(
          'W3C (World Wide Web Consortium)',
          'Netscape Communications',
          'Microsoft Corporation',
          'IEEE Robotics Committee'
        ),
        'correct_answer', 'W3C (World Wide Web Consortium)'
      )
    );
  END IF;
END $$;

-- 3. Validation RPC: submit_field_test
-- Accepts p_test_id, p_user_id, p_answer.
-- Validates answer against field_tests, updates user_progress, increments clearance_level, returns status.
CREATE OR REPLACE FUNCTION public.submit_field_test(
  p_test_id UUID,
  p_user_id UUID,
  p_answer TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_test RECORD;
  v_current_user RECORD;
  v_expected_answer TEXT;
  v_submitted_answer TEXT;
  v_new_clearance INT;
  v_new_points INT;
BEGIN
  -- Authenticate operative
  IF p_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Operative ID cannot be null.'
    );
  END IF;

  IF auth.uid() IS NOT NULL AND auth.uid() <> p_user_id THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Security violation: Operative credentials mismatch.'
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
  WHERE id = p_user_id;

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
  WHERE id = p_user_id;

  -- Record user progress
  INSERT INTO public.user_progress (user_id, dossier_id, status, completed_at)
  VALUES (p_user_id, v_test.dossier_id, 'completed', timezone('utc'::text, now()))
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

-- 4. Secure RPC to fetch sanitized field test data (without leaking answer keys)
CREATE OR REPLACE FUNCTION public.get_field_test(p_test_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'id', ft.id,
    'dossier_id', ft.dossier_id,
    'scenario_description', ft.scenario_description,
    'test_type', ft.test_type,
    'options', ft.passing_criteria->'options',
    'dossier_title', d.title,
    'dossier_category', d.category,
    'required_clearance', d.required_clearance
  )
  INTO v_result
  FROM public.field_tests ft
  JOIN public.dossiers d ON d.id = ft.dossier_id
  WHERE ft.id = p_test_id;

  RETURN v_result;
END;
$$;

-- 5. Secure RPC to fetch catalog for the dashboard
-- Allows user to view all dossier metadata (title, category, clearance, summary, and field_test_id)
-- without leaking classified content_markdown
CREATE OR REPLACE FUNCTION public.get_dossier_catalog()
RETURNS TABLE (
  id UUID,
  title TEXT,
  slug TEXT,
  category TEXT,
  required_clearance INT,
  is_code_related BOOLEAN,
  briefing_summary TEXT,
  has_field_test BOOLEAN,
  field_test_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    d.id,
    d.title,
    d.slug,
    d.category,
    d.required_clearance,
    d.is_code_related,
    d.briefing_summary,
    (ft.id IS NOT NULL) AS has_field_test,
    ft.id AS field_test_id
  FROM public.dossiers d
  LEFT JOIN public.field_tests ft ON ft.dossier_id = d.id
  ORDER BY d.required_clearance ASC, d.title ASC;
END;
$$;
