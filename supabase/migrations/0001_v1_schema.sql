-- V1 Base Schema (Single-Institute: Core + Students + RLS Helpers)
-- Attendance, Fees, and Notices will be added in later migrations as each module is built.
-- Run BEFORE 0002_student_admission.sql and 0003_teachers.sql

-- ============================================================================
-- 1. Custom PostgreSQL Enums
-- ============================================================================

DO $$ BEGIN
  CREATE TYPE public.user_role AS ENUM (
    'super_admin', 'principal', 'fee_clerk', 'teacher', 'student', 'parent'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- 2. Core Academic & User Tables
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.academic_years (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_current BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.user_role NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL DEFAULT '',
  phone TEXT,
  avatar_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

CREATE TABLE IF NOT EXISTS public.classes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  class_teacher_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (class_id, name)
);

CREATE INDEX IF NOT EXISTS idx_sections_class ON public.sections(class_id);

CREATE TABLE IF NOT EXISTS public.subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  code TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.class_subject_teachers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
  section_id UUID NOT NULL REFERENCES public.sections(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (academic_year_id, section_id, subject_id, teacher_id)
);

CREATE INDEX IF NOT EXISTS idx_cst_teacher ON public.class_subject_teachers(teacher_id);

-- ============================================================================
-- 3. Students, Enrollments & Parent Links
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  admission_number TEXT NOT NULL UNIQUE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL DEFAULT '',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_students_profile ON public.students(profile_id);

CREATE TABLE IF NOT EXISTS public.student_enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  section_id UUID NOT NULL REFERENCES public.sections(id) ON DELETE CASCADE,
  roll_number INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, academic_year_id)
);

CREATE INDEX IF NOT EXISTS idx_enrollments_section ON public.student_enrollments(section_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_student ON public.student_enrollments(student_id);

CREATE TABLE IF NOT EXISTS public.student_parents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  parent_profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  relationship TEXT,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_parents_student ON public.student_parents(student_id);
CREATE INDEX IF NOT EXISTS idx_student_parents_profile ON public.student_parents(parent_profile_id);

-- ============================================================================
-- 4. RLS Helper Functions
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS public.user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_my_student_ids()
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT student_id
  FROM public.student_parents
  WHERE parent_profile_id = auth.uid()
  UNION
  SELECT id
  FROM public.students
  WHERE profile_id = auth.uid();
$$;

-- ============================================================================
-- 5. Enable Row-Level Security
-- ============================================================================

ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_subject_teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_parents ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 6. RLS Policies
-- ============================================================================

-- Profiles
CREATE POLICY profiles_auth_select ON public.profiles
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY profiles_admin_all ON public.profiles
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY profiles_self_update ON public.profiles
  FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Academic Years, Classes, Sections, Subjects, Class-Subject-Teachers
CREATE POLICY academic_years_select ON public.academic_years
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY academic_years_admin_all ON public.academic_years
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY classes_select ON public.classes
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY classes_admin_all ON public.classes
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY sections_select ON public.sections
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY sections_admin_all ON public.sections
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY subjects_select ON public.subjects
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY subjects_admin_all ON public.subjects
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY cst_select ON public.class_subject_teachers
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY cst_admin_all ON public.class_subject_teachers
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

-- Students
CREATE POLICY students_admin_all ON public.students
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY students_staff_select ON public.students
  FOR SELECT
  USING (public.get_my_role() IN ('fee_clerk', 'teacher'));

CREATE POLICY students_parent_student_select ON public.students
  FOR SELECT
  USING (id IN (SELECT public.get_my_student_ids()));

-- Student Enrollments
CREATE POLICY enrollments_admin_all ON public.student_enrollments
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY enrollments_staff_select ON public.student_enrollments
  FOR SELECT
  USING (public.get_my_role() IN ('fee_clerk', 'teacher'));

CREATE POLICY enrollments_parent_student_select ON public.student_enrollments
  FOR SELECT
  USING (student_id IN (SELECT public.get_my_student_ids()));

-- Student Parents
CREATE POLICY student_parents_admin_all ON public.student_parents
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk'));

CREATE POLICY student_parents_staff_parent_select ON public.student_parents
  FOR SELECT
  USING (
    public.get_my_role() = 'teacher'
    OR student_id IN (SELECT public.get_my_student_ids())
  );
