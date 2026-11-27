-- Teachers & Staff Management Schema, RLS Policies, and Transactional RPCs (Single-Institute)
-- Depends on V1 tables & RLS helper: get_my_role()

-- 1. Custom Enums
DO $$ BEGIN
  CREATE TYPE public.teacher_employment_type AS ENUM (
    'full_time', 'part_time', 'contract', 'guest'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.teacher_status AS ENUM (
    'active', 'on_leave', 'resigned', 'inactive'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 2. Teachers table (1:1 with profiles where role = 'teacher')
CREATE TABLE IF NOT EXISTS public.teachers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  employee_id TEXT NOT NULL UNIQUE,
  middle_name TEXT,
  date_of_birth DATE,
  gender TEXT,
  blood_group TEXT,
  marital_status TEXT,
  nationality TEXT DEFAULT 'Indian',
  religion TEXT,
  aadhaar_number TEXT,
  pan_number TEXT,
  alternate_phone TEXT,
  email TEXT NOT NULL,
  current_address TEXT,
  permanent_address TEXT,
  city TEXT,
  state TEXT,
  pincode TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  emergency_contact_relationship TEXT,
  designation TEXT NOT NULL,
  department TEXT,
  employment_type public.teacher_employment_type NOT NULL DEFAULT 'full_time',
  joining_date DATE NOT NULL DEFAULT CURRENT_DATE,
  probation_end_date DATE,
  reporting_to UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  status public.teacher_status NOT NULL DEFAULT 'active',
  resignation_date DATE,
  teaching_license_number TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_teachers_profile ON public.teachers(profile_id);
CREATE INDEX IF NOT EXISTS idx_teachers_status ON public.teachers(status);

-- 3. Teacher Qualifications
CREATE TABLE IF NOT EXISTS public.teacher_qualifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  degree TEXT NOT NULL,
  specialization TEXT,
  institution TEXT NOT NULL,
  year_of_passing TEXT,
  percentage_or_grade TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_teacher_quals_teacher ON public.teacher_qualifications(teacher_id);

-- 4. Teacher Previous Experience
CREATE TABLE IF NOT EXISTS public.teacher_experience (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  organization TEXT NOT NULL,
  designation TEXT,
  from_date DATE NOT NULL,
  to_date DATE NOT NULL,
  reason_for_leaving TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_teacher_exp_teacher ON public.teacher_experience(teacher_id);

-- 5. Teacher Documents (Supabase Storage references)
CREATE TABLE IF NOT EXISTS public.teacher_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  doc_type TEXT NOT NULL,
  file_name TEXT,
  file_url TEXT NOT NULL,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_teacher_docs_teacher ON public.teacher_documents(teacher_id);

-- 6. Teacher Teachable Subjects (capability, separate from class_subject_teachers)
CREATE TABLE IF NOT EXISTS public.teacher_subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (teacher_id, subject_id)
);

CREATE INDEX IF NOT EXISTS idx_teacher_subjects_teacher ON public.teacher_subjects(teacher_id);

-- 7. Teacher Salary & Bank Details (isolated for strict principal/super_admin RLS)
CREATE TABLE IF NOT EXISTS public.teacher_bank_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL UNIQUE REFERENCES public.teachers(id) ON DELETE CASCADE,
  basic_salary NUMERIC(12, 2) NOT NULL DEFAULT 0,
  allowances NUMERIC(12, 2) NOT NULL DEFAULT 0,
  deductions NUMERIC(12, 2) NOT NULL DEFAULT 0,
  bank_name TEXT,
  account_number TEXT,
  ifsc_code TEXT,
  account_holder_name TEXT,
  pf_number TEXT,
  esi_number TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_teacher_bank_teacher ON public.teacher_bank_details(teacher_id);

-- 8. Enable Row-Level Security
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_qualifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_experience ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_bank_details ENABLE ROW LEVEL SECURITY;

-- 9. RLS Policies
-- Principal & Super Admin: full access
CREATE POLICY "teachers_admin_all" ON public.teachers
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

-- Teachers: read own full teacher record
CREATE POLICY "teachers_self_select" ON public.teachers
  FOR SELECT
  USING (profile_id = auth.uid());

-- Safe basic directory view for other roles (name, photo, designation)
CREATE OR REPLACE VIEW public.teacher_directory AS
SELECT
  t.id,
  t.profile_id,
  p.first_name,
  p.last_name,
  p.avatar_url,
  t.designation,
  t.status,
  p.is_active
FROM public.teachers t
JOIN public.profiles p ON p.id = t.profile_id;

-- Qualifications, Experience, Documents, Teachable Subjects:
-- Admin full CRUD; Teacher read own
CREATE POLICY "teacher_quals_admin_all" ON public.teacher_qualifications
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY "teacher_quals_self_select" ON public.teacher_qualifications
  FOR SELECT
  USING (teacher_id IN (SELECT id FROM public.teachers WHERE profile_id = auth.uid()));

CREATE POLICY "teacher_exp_admin_all" ON public.teacher_experience
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY "teacher_exp_self_select" ON public.teacher_experience
  FOR SELECT
  USING (teacher_id IN (SELECT id FROM public.teachers WHERE profile_id = auth.uid()));

CREATE POLICY "teacher_docs_admin_all" ON public.teacher_documents
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY "teacher_docs_self_select" ON public.teacher_documents
  FOR SELECT
  USING (teacher_id IN (SELECT id FROM public.teachers WHERE profile_id = auth.uid()));

CREATE POLICY "teacher_subjects_admin_all" ON public.teacher_subjects
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY "teacher_subjects_auth_select" ON public.teacher_subjects
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Salary & Bank Details: STRICTLY principal & super_admin only
CREATE POLICY "teacher_bank_admin_only" ON public.teacher_bank_details
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

-- 10. Transactional RPC: create_teacher(payload jsonb)
CREATE OR REPLACE FUNCTION public.create_teacher(payload JSONB)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role := public.get_my_role();
  v_profile_id UUID;
  v_teacher_id UUID;
  v_employee_id TEXT;
  v_seq INT;
  v_item JSONB;
  v_class_teacher_section_id UUID;
BEGIN
  IF v_role NOT IN ('super_admin', 'principal') THEN
    RAISE EXCEPTION 'Unauthorized: only principal or super_admin can create teachers';
  END IF;

  v_profile_id := COALESCE((payload->>'profile_id')::UUID, gen_random_uuid());

  -- Generate employee ID: EMP-YYYY-NNN
  SELECT COUNT(*) + 1 INTO v_seq FROM public.teachers;
  v_employee_id := 'EMP-' || TO_CHAR(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_seq::TEXT, 3, '0');

  -- Upsert profile
  INSERT INTO public.profiles (
    id, role, first_name, last_name, phone, avatar_url, is_active
  ) VALUES (
    v_profile_id,
    'teacher',
    payload->>'first_name',
    payload->>'last_name',
    NULLIF(payload->>'phone', ''),
    NULLIF(payload->>'avatar_url', ''),
    COALESCE((payload->>'is_active')::BOOLEAN, TRUE)
  )
  ON CONFLICT (id) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    phone = EXCLUDED.phone,
    avatar_url = EXCLUDED.avatar_url,
    is_active = EXCLUDED.is_active;

  -- Insert teacher row
  INSERT INTO public.teachers (
    profile_id, employee_id, middle_name, date_of_birth, gender,
    blood_group, marital_status, nationality, religion, aadhaar_number, pan_number,
    alternate_phone, email, current_address, permanent_address, city, state, pincode,
    emergency_contact_name, emergency_contact_phone, emergency_contact_relationship,
    designation, department, employment_type, joining_date, probation_end_date,
    reporting_to, status, resignation_date, teaching_license_number
  ) VALUES (
    v_profile_id,
    v_employee_id,
    NULLIF(payload->>'middle_name', ''),
    NULLIF(payload->>'date_of_birth', '')::DATE,
    NULLIF(payload->>'gender', ''),
    NULLIF(payload->>'blood_group', ''),
    NULLIF(payload->>'marital_status', ''),
    COALESCE(NULLIF(payload->>'nationality', ''), 'Indian'),
    NULLIF(payload->>'religion', ''),
    NULLIF(payload->>'aadhaar_number', ''),
    NULLIF(payload->>'pan_number', ''),
    NULLIF(payload->>'alternate_phone', ''),
    payload->>'email',
    NULLIF(payload->>'current_address', ''),
    NULLIF(payload->>'permanent_address', ''),
    NULLIF(payload->>'city', ''),
    NULLIF(payload->>'state', ''),
    NULLIF(payload->>'pincode', ''),
    NULLIF(payload->>'emergency_contact_name', ''),
    NULLIF(payload->>'emergency_contact_phone', ''),
    NULLIF(payload->>'emergency_contact_relationship', ''),
    payload->>'designation',
    NULLIF(payload->>'department', ''),
    COALESCE(NULLIF(payload->>'employment_type', '')::public.teacher_employment_type, 'full_time'),
    COALESCE(NULLIF(payload->>'joining_date', '')::DATE, CURRENT_DATE),
    NULLIF(payload->>'probation_end_date', '')::DATE,
    NULLIF(payload->>'reporting_to', '')::UUID,
    COALESCE(NULLIF(payload->>'status', '')::public.teacher_status, 'active'),
    NULLIF(payload->>'resignation_date', '')::DATE,
    NULLIF(payload->>'teaching_license_number', '')
  )
  RETURNING id INTO v_teacher_id;

  -- Qualifications
  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'qualifications', '[]'::JSONB))
  LOOP
    INSERT INTO public.teacher_qualifications (
      teacher_id, degree, specialization, institution, year_of_passing, percentage_or_grade
    ) VALUES (
      v_teacher_id,
      v_item->>'degree',
      NULLIF(v_item->>'specialization', ''),
      v_item->>'institution',
      NULLIF(v_item->>'year_of_passing', ''),
      NULLIF(v_item->>'percentage_or_grade', '')
    );
  END LOOP;

  -- Previous Experience
  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'experiences', '[]'::JSONB))
  LOOP
    INSERT INTO public.teacher_experience (
      teacher_id, organization, designation, from_date, to_date, reason_for_leaving
    ) VALUES (
      v_teacher_id,
      v_item->>'organization',
      NULLIF(v_item->>'designation', ''),
      (v_item->>'from_date')::DATE,
      (v_item->>'to_date')::DATE,
      NULLIF(v_item->>'reason_for_leaving', '')
    );
  END LOOP;

  -- Teachable Subjects
  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'teachable_subject_ids', '[]'::JSONB))
  LOOP
    INSERT INTO public.teacher_subjects (teacher_id, subject_id)
    VALUES (v_teacher_id, (v_item#>>'{}')::UUID)
    ON CONFLICT DO NOTHING;
  END LOOP;

  -- Class-Subject-Teacher Assignments (current academic year)
  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'assignments', '[]'::JSONB))
  LOOP
    INSERT INTO public.class_subject_teachers (
      academic_year_id, section_id, subject_id, teacher_id
    ) VALUES (
      (v_item->>'academic_year_id')::UUID,
      (v_item->>'section_id')::UUID,
      (v_item->>'subject_id')::UUID,
      v_profile_id
    )
    ON CONFLICT DO NOTHING;
  END LOOP;

  -- Optional Class Teacher assignment (one class teacher per section)
  v_class_teacher_section_id := NULLIF(payload->>'class_teacher_section_id', '')::UUID;
  IF v_class_teacher_section_id IS NOT NULL THEN
    UPDATE public.sections
    SET class_teacher_id = v_profile_id
    WHERE id = v_class_teacher_section_id;
  END IF;

  -- Documents
  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'documents', '[]'::JSONB))
  LOOP
    INSERT INTO public.teacher_documents (teacher_id, doc_type, file_name, file_url)
    VALUES (
      v_teacher_id,
      v_item->>'doc_type',
      NULLIF(v_item->>'file_name', ''),
      v_item->>'file_url'
    );
  END LOOP;

  -- Salary & Bank Details
  IF payload ? 'bank_details' AND payload->'bank_details' IS NOT NULL THEN
    INSERT INTO public.teacher_bank_details (
      teacher_id, basic_salary, allowances, deductions,
      bank_name, account_number, ifsc_code, account_holder_name, pf_number, esi_number
    ) VALUES (
      v_teacher_id,
      COALESCE((payload->'bank_details'->>'basic_salary')::NUMERIC, 0),
      COALESCE((payload->'bank_details'->>'allowances')::NUMERIC, 0),
      COALESCE((payload->'bank_details'->>'deductions')::NUMERIC, 0),
      NULLIF(payload->'bank_details'->>'bank_name', ''),
      NULLIF(payload->'bank_details'->>'account_number', ''),
      NULLIF(payload->'bank_details'->>'ifsc_code', ''),
      NULLIF(payload->'bank_details'->>'account_holder_name', ''),
      NULLIF(payload->'bank_details'->>'pf_number', ''),
      NULLIF(payload->'bank_details'->>'esi_number', '')
    );
  END IF;

  RETURN v_teacher_id;
END;
$$;

-- 11. Transactional RPC: set_teacher_active(p_teacher_id uuid, p_is_active boolean)
CREATE OR REPLACE FUNCTION public.set_teacher_active(
  p_teacher_id UUID,
  p_is_active BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile_id UUID;
BEGIN
  IF public.get_my_role() NOT IN ('super_admin', 'principal') THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT profile_id INTO v_profile_id
  FROM public.teachers
  WHERE id = p_teacher_id;

  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Teacher not found';
  END IF;

  UPDATE public.profiles
  SET is_active = p_is_active
  WHERE id = v_profile_id;

  UPDATE public.teachers
  SET
    status = CASE WHEN p_is_active THEN 'active'::public.teacher_status ELSE 'inactive'::public.teacher_status END,
    updated_at = NOW()
  WHERE id = p_teacher_id;
END;
$$;
