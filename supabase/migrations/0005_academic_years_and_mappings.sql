-- Academic Year Management & Class-Subject-Teacher Mapping RPCs
-- Depends on 0001_v1_schema.sql

-- ============================================================================
-- 1. Enforce at most one current academic year at the database level
-- ============================================================================

CREATE UNIQUE INDEX IF NOT EXISTS idx_academic_years_single_current
  ON public.academic_years (is_current)
  WHERE is_current = TRUE;

-- ============================================================================
-- 2. Academic Year RPCs
-- ============================================================================

CREATE OR REPLACE FUNCTION public.save_academic_year(
  p_id UUID DEFAULT NULL,
  p_name TEXT DEFAULT '',
  p_start_date DATE DEFAULT CURRENT_DATE,
  p_end_date DATE DEFAULT CURRENT_DATE,
  p_is_current BOOLEAN DEFAULT FALSE
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role := public.get_my_role();
  v_id UUID;
BEGIN
  IF v_role NOT IN ('super_admin', 'principal') THEN
    RAISE EXCEPTION 'Unauthorized: only principal or super_admin can manage academic years';
  END IF;

  IF TRIM(p_name) = '' THEN
    RAISE EXCEPTION 'Academic year name is required';
  END IF;

  IF p_end_date <= p_start_date THEN
    RAISE EXCEPTION 'End date must be after start date';
  END IF;

  IF p_is_current THEN
    UPDATE public.academic_years
    SET is_current = FALSE, updated_at = NOW()
    WHERE is_current = TRUE AND (p_id IS NULL OR id <> p_id);
  END IF;

  IF p_id IS NULL THEN
    INSERT INTO public.academic_years (name, start_date, end_date, is_current)
    VALUES (TRIM(p_name), p_start_date, p_end_date, p_is_current)
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.academic_years
    SET
      name = TRIM(p_name),
      start_date = p_start_date,
      end_date = p_end_date,
      is_current = p_is_current,
      updated_at = NOW()
    WHERE id = p_id
    RETURNING id INTO v_id;

    IF v_id IS NULL THEN
      RAISE EXCEPTION 'Academic year not found';
    END IF;
  END IF;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_current_academic_year(
  p_academic_year_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.get_my_role() NOT IN ('super_admin', 'principal') THEN
    RAISE EXCEPTION 'Unauthorized: only principal or super_admin can set current academic year';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.academic_years WHERE id = p_academic_year_id) THEN
    RAISE EXCEPTION 'Academic year not found';
  END IF;

  UPDATE public.academic_years
  SET is_current = FALSE, updated_at = NOW()
  WHERE is_current = TRUE AND id <> p_academic_year_id;

  UPDATE public.academic_years
  SET is_current = TRUE, updated_at = NOW()
  WHERE id = p_academic_year_id;
END;
$$;

-- ============================================================================
-- 3. Class-Subject-Teacher Mapping RPC (for current or specified academic year)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.assign_section_subject_teacher(
  p_section_id UUID,
  p_subject_id UUID,
  p_teacher_profile_id UUID,
  p_academic_year_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year_id UUID := p_academic_year_id;
  v_id UUID;
BEGIN
  IF public.get_my_role() NOT IN ('super_admin', 'principal') THEN
    RAISE EXCEPTION 'Unauthorized: only principal or super_admin can assign subject teachers';
  END IF;

  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id
    FROM public.academic_years
    WHERE is_current = TRUE
    LIMIT 1;
  END IF;

  IF v_year_id IS NULL THEN
    RAISE EXCEPTION 'No current academic year is set. Please create or activate an academic year first.';
  END IF;

  INSERT INTO public.class_subject_teachers (
    academic_year_id, section_id, subject_id, teacher_id
  )
  VALUES (
    v_year_id, p_section_id, p_subject_id, p_teacher_profile_id
  )
  ON CONFLICT (academic_year_id, section_id, subject_id, teacher_id) DO NOTHING
  RETURNING id INTO v_id;

  IF v_id IS NULL THEN
    SELECT id INTO v_id
    FROM public.class_subject_teachers
    WHERE academic_year_id = v_year_id
      AND section_id = p_section_id
      AND subject_id = p_subject_id
      AND teacher_id = p_teacher_profile_id
    LIMIT 1;
  END IF;

  RETURN v_id;
END;
$$;
