-- V1 Base Schema, RLS Helper Functions, and Row-Level Security Policies
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

DO $$ BEGIN
  CREATE TYPE public.attendance_status AS ENUM (
    'present', 'absent', 'late', 'half_day'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.fee_payment_mode AS ENUM (
    'cash', 'upi', 'cheque', 'bank_transfer', 'online'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.fee_status AS ENUM (
    'pending', 'partial', 'paid', 'overdue'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- 2. Core Multi-Tenant & Academic Tables
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.institutes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  phone TEXT,
  email TEXT,
  address TEXT,
  logo_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.academic_years (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_current BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (institute_id, name)
);

CREATE INDEX IF NOT EXISTS idx_academic_years_institute
  ON public.academic_years(institute_id);

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  role public.user_role NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL DEFAULT '',
  phone TEXT,
  avatar_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_institute ON public.profiles(institute_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(institute_id, role);

CREATE TABLE IF NOT EXISTS public.classes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (institute_id, name)
);

CREATE INDEX IF NOT EXISTS idx_classes_institute ON public.classes(institute_id);

CREATE TABLE IF NOT EXISTS public.sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  class_teacher_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (class_id, name)
);

CREATE INDEX IF NOT EXISTS idx_sections_institute ON public.sections(institute_id);
CREATE INDEX IF NOT EXISTS idx_sections_class ON public.sections(class_id);

CREATE TABLE IF NOT EXISTS public.subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (institute_id, name)
);

CREATE INDEX IF NOT EXISTS idx_subjects_institute ON public.subjects(institute_id);

CREATE TABLE IF NOT EXISTS public.class_subject_teachers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
  section_id UUID NOT NULL REFERENCES public.sections(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (academic_year_id, section_id, subject_id, teacher_id)
);

CREATE INDEX IF NOT EXISTS idx_cst_institute ON public.class_subject_teachers(institute_id);
CREATE INDEX IF NOT EXISTS idx_cst_teacher ON public.class_subject_teachers(teacher_id);

-- ============================================================================
-- 3. Students, Enrollments & Parent Links
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  admission_number TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL DEFAULT '',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (institute_id, admission_number)
);

CREATE INDEX IF NOT EXISTS idx_students_institute ON public.students(institute_id);
CREATE INDEX IF NOT EXISTS idx_students_profile ON public.students(profile_id);

CREATE TABLE IF NOT EXISTS public.student_enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  section_id UUID NOT NULL REFERENCES public.sections(id) ON DELETE CASCADE,
  roll_number INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, academic_year_id)
);

CREATE INDEX IF NOT EXISTS idx_enrollments_institute ON public.student_enrollments(institute_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_section ON public.student_enrollments(section_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_student ON public.student_enrollments(student_id);

CREATE TABLE IF NOT EXISTS public.student_parents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  parent_profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  relationship TEXT,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_parents_student ON public.student_parents(student_id);
CREATE INDEX IF NOT EXISTS idx_student_parents_profile ON public.student_parents(parent_profile_id);

-- ============================================================================
-- 4. Attendance, Fees & Notices
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.student_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  section_id UUID NOT NULL REFERENCES public.sections(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status public.attendance_status NOT NULL,
  marked_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  remarks TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, date)
);

CREATE INDEX IF NOT EXISTS idx_attendance_section_date ON public.student_attendance(section_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_student ON public.student_attendance(student_id);

CREATE TABLE IF NOT EXISTS public.fee_heads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (institute_id, name)
);

CREATE TABLE IF NOT EXISTS public.fee_structures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  fee_head_id UUID NOT NULL REFERENCES public.fee_heads(id) ON DELETE CASCADE,
  amount NUMERIC(12, 2) NOT NULL,
  due_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (academic_year_id, class_id, fee_head_id)
);

CREATE TABLE IF NOT EXISTS public.student_fees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
  fee_head_id UUID NOT NULL REFERENCES public.fee_heads(id) ON DELETE RESTRICT,
  original_amount NUMERIC(12, 2) NOT NULL,
  discount_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
  fine_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
  paid_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
  status public.fee_status NOT NULL DEFAULT 'pending',
  due_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_fees_student ON public.student_fees(student_id);
CREATE INDEX IF NOT EXISTS idx_student_fees_status ON public.student_fees(institute_id, status);

CREATE TABLE IF NOT EXISTS public.fee_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  student_fee_id UUID NOT NULL REFERENCES public.student_fees(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  receipt_number TEXT NOT NULL,
  amount_paid NUMERIC(12, 2) NOT NULL,
  payment_mode public.fee_payment_mode NOT NULL,
  transaction_ref TEXT,
  payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  collected_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  remarks TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (institute_id, receipt_number)
);

CREATE INDEX IF NOT EXISTS idx_fee_payments_student ON public.fee_payments(student_id);

CREATE TABLE IF NOT EXISTS public.notices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  target_role public.user_role,
  target_class_id UUID REFERENCES public.classes(id) ON DELETE CASCADE,
  published_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  published_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notices_institute ON public.notices(institute_id, published_at DESC);

-- ============================================================================
-- 5. RLS Helper Functions
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_my_institute_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT institute_id FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$;

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
-- 6. Enable Row-Level Security
-- ============================================================================

ALTER TABLE public.institutes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_subject_teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_parents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fee_heads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fee_structures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fee_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 7. RLS Policies
-- ============================================================================

-- Institutes
CREATE POLICY institutes_member_select ON public.institutes
  FOR SELECT
  USING (id = public.get_my_institute_id());

CREATE POLICY institutes_admin_update ON public.institutes
  FOR UPDATE
  USING (
    id = public.get_my_institute_id()
    AND public.get_my_role() IN ('super_admin', 'principal')
  )
  WITH CHECK (
    id = public.get_my_institute_id()
    AND public.get_my_role() IN ('super_admin', 'principal')
  );

-- Profiles
CREATE POLICY profiles_institute_select ON public.profiles
  FOR SELECT
  USING (institute_id = public.get_my_institute_id());

CREATE POLICY profiles_admin_all ON public.profiles
  FOR ALL
  USING (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() IN ('super_admin', 'principal')
  )
  WITH CHECK (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() IN ('super_admin', 'principal')
  );

CREATE POLICY profiles_self_update ON public.profiles
  FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Academic Years, Classes, Sections, Subjects, Class-Subject-Teachers
CREATE POLICY academic_years_select ON public.academic_years
  FOR SELECT USING (institute_id = public.get_my_institute_id());

CREATE POLICY academic_years_admin_all ON public.academic_years
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY classes_select ON public.classes
  FOR SELECT USING (institute_id = public.get_my_institute_id());

CREATE POLICY classes_admin_all ON public.classes
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY sections_select ON public.sections
  FOR SELECT USING (institute_id = public.get_my_institute_id());

CREATE POLICY sections_admin_all ON public.sections
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY subjects_select ON public.subjects
  FOR SELECT USING (institute_id = public.get_my_institute_id());

CREATE POLICY subjects_admin_all ON public.subjects
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY cst_select ON public.class_subject_teachers
  FOR SELECT USING (institute_id = public.get_my_institute_id());

CREATE POLICY cst_admin_all ON public.class_subject_teachers
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'));

-- Students
CREATE POLICY students_admin_all ON public.students
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY students_staff_select ON public.students
  FOR SELECT
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('fee_clerk', 'teacher'));

CREATE POLICY students_parent_student_select ON public.students
  FOR SELECT
  USING (institute_id = public.get_my_institute_id() AND id IN (SELECT public.get_my_student_ids()));

-- Student Enrollments
CREATE POLICY enrollments_admin_all ON public.student_enrollments
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY enrollments_staff_select ON public.student_enrollments
  FOR SELECT
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('fee_clerk', 'teacher'));

CREATE POLICY enrollments_parent_student_select ON public.student_enrollments
  FOR SELECT
  USING (institute_id = public.get_my_institute_id() AND student_id IN (SELECT public.get_my_student_ids()));

-- Student Parents
CREATE POLICY student_parents_admin_all ON public.student_parents
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk'));

CREATE POLICY student_parents_staff_parent_select ON public.student_parents
  FOR SELECT
  USING (
    institute_id = public.get_my_institute_id()
    AND (
      public.get_my_role() = 'teacher'
      OR student_id IN (SELECT public.get_my_student_ids())
    )
  );

-- Student Attendance
CREATE POLICY attendance_admin_all ON public.student_attendance
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY attendance_teacher_select ON public.student_attendance
  FOR SELECT
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() = 'teacher');

CREATE POLICY attendance_teacher_write ON public.student_attendance
  FOR INSERT
  WITH CHECK (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() = 'teacher'
    AND (
      section_id IN (SELECT id FROM public.sections WHERE class_teacher_id = auth.uid())
      OR section_id IN (SELECT section_id FROM public.class_subject_teachers WHERE teacher_id = auth.uid())
    )
  );

CREATE POLICY attendance_teacher_update ON public.student_attendance
  FOR UPDATE
  USING (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() = 'teacher'
    AND (
      section_id IN (SELECT id FROM public.sections WHERE class_teacher_id = auth.uid())
      OR section_id IN (SELECT section_id FROM public.class_subject_teachers WHERE teacher_id = auth.uid())
    )
  )
  WITH CHECK (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() = 'teacher'
    AND (
      section_id IN (SELECT id FROM public.sections WHERE class_teacher_id = auth.uid())
      OR section_id IN (SELECT section_id FROM public.class_subject_teachers WHERE teacher_id = auth.uid())
    )
  );

CREATE POLICY attendance_parent_student_select ON public.student_attendance
  FOR SELECT
  USING (institute_id = public.get_my_institute_id() AND student_id IN (SELECT public.get_my_student_ids()));

-- Fees (Heads, Structures, Student Fees, Fee Payments)
CREATE POLICY fee_heads_select ON public.fee_heads
  FOR SELECT USING (institute_id = public.get_my_institute_id());

CREATE POLICY fee_heads_staff_all ON public.fee_heads
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk'));

CREATE POLICY fee_structures_select ON public.fee_structures
  FOR SELECT USING (institute_id = public.get_my_institute_id());

CREATE POLICY fee_structures_staff_all ON public.fee_structures
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk'));

CREATE POLICY student_fees_staff_all ON public.student_fees
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk'));

CREATE POLICY student_fees_parent_student_select ON public.student_fees
  FOR SELECT
  USING (institute_id = public.get_my_institute_id() AND student_id IN (SELECT public.get_my_student_ids()));

CREATE POLICY fee_payments_staff_all ON public.fee_payments
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk'));

CREATE POLICY fee_payments_parent_student_select ON public.fee_payments
  FOR SELECT
  USING (institute_id = public.get_my_institute_id() AND student_id IN (SELECT public.get_my_student_ids()));

-- Notices
CREATE POLICY notices_admin_all ON public.notices
  FOR ALL
  USING (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (institute_id = public.get_my_institute_id() AND public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY notices_member_select ON public.notices
  FOR SELECT
  USING (
    institute_id = public.get_my_institute_id()
    AND (target_role IS NULL OR target_role = public.get_my_role())
  );
