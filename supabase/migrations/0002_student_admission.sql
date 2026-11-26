-- Student Admission Schema & Transactional RPC
-- Depends on V1 tables & RLS helpers: get_my_institute_id(), get_my_role(), get_my_student_ids()

-- 1. Extend students table with full admission, basic, and address fields
ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS middle_name TEXT,
  ADD COLUMN IF NOT EXISTS date_of_birth DATE,
  ADD COLUMN IF NOT EXISTS gender TEXT,
  ADD COLUMN IF NOT EXISTS photo_url TEXT,
  ADD COLUMN IF NOT EXISTS blood_group TEXT,
  ADD COLUMN IF NOT EXISTS nationality TEXT DEFAULT 'Indian',
  ADD COLUMN IF NOT EXISTS religion TEXT,
  ADD COLUMN IF NOT EXISTS mother_tongue TEXT,
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS aadhaar_number TEXT,
  ADD COLUMN IF NOT EXISTS admission_date DATE DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS gr_number TEXT,
  ADD COLUMN IF NOT EXISTS admission_type TEXT DEFAULT 'new',
  ADD COLUMN IF NOT EXISTS student_type TEXT DEFAULT 'day_scholar',
  ADD COLUMN IF NOT EXISTS medium_of_instruction TEXT DEFAULT 'English',
  ADD COLUMN IF NOT EXISTS current_address TEXT,
  ADD COLUMN IF NOT EXISTS permanent_address TEXT,
  ADD COLUMN IF NOT EXISTS city TEXT,
  ADD COLUMN IF NOT EXISTS state TEXT,
  ADD COLUMN IF NOT EXISTS pincode TEXT,
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS emergency_contact_name TEXT,
  ADD COLUMN IF NOT EXISTS emergency_contact_phone TEXT,
  ADD COLUMN IF NOT EXISTS emergency_contact_relationship TEXT,
  ADD COLUMN IF NOT EXISTS transport_needed BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS transport_route_stop TEXT,
  ADD COLUMN IF NOT EXISTS special_needs TEXT,
  ADD COLUMN IF NOT EXISTS sibling_ids UUID[] DEFAULT '{}';

-- 2. Guardians table (parents/guardians may not have auth profiles at admission)
CREATE TABLE IF NOT EXISTS public.guardians (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  occupation TEXT,
  qualification TEXT,
  annual_income TEXT,
  relationship TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Keep student_parents compatible with guardians while preserving optional parent_profile_id
ALTER TABLE public.student_parents
  ADD COLUMN IF NOT EXISTS guardian_id UUID REFERENCES public.guardians(id) ON DELETE CASCADE,
  ALTER COLUMN parent_profile_id DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_guardians_institute ON public.guardians(institute_id);
CREATE INDEX IF NOT EXISTS idx_guardians_phone ON public.guardians(institute_id, phone);
CREATE INDEX IF NOT EXISTS idx_student_parents_guardian ON public.student_parents(guardian_id);

-- 3. Previous schools table
CREATE TABLE IF NOT EXISTS public.student_previous_schools (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  school_name TEXT NOT NULL,
  board TEXT,
  last_class_attended TEXT,
  year_of_passing TEXT,
  percentage_or_grade TEXT,
  reason_for_leaving TEXT,
  tc_number TEXT,
  tc_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prev_schools_student ON public.student_previous_schools(student_id);

-- 4. Student documents table (Supabase Storage references)
CREATE TABLE IF NOT EXISTS public.student_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  doc_type TEXT NOT NULL,
  file_name TEXT,
  file_url TEXT NOT NULL,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_docs_student ON public.student_documents(student_id);

-- 5. Student medical info table (isolated for stricter RLS)
CREATE TABLE IF NOT EXISTS public.student_medical_info (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL UNIQUE REFERENCES public.students(id) ON DELETE CASCADE,
  allergies TEXT,
  conditions TEXT,
  doctor_contact TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Row-Level Security (RLS)
ALTER TABLE public.guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_previous_schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_medical_info ENABLE ROW LEVEL SECURITY;

-- Guardians RLS
CREATE POLICY guardians_staff_all ON public.guardians
  FOR ALL
  USING (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk')
  )
  WITH CHECK (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk')
  );

CREATE POLICY guardians_teacher_read ON public.guardians
  FOR SELECT
  USING (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() = 'teacher'
  );

CREATE POLICY guardians_parent_self ON public.guardians
  FOR SELECT
  USING (
    institute_id = public.get_my_institute_id()
    AND (
      profile_id = auth.uid()
      OR id IN (
        SELECT sp.guardian_id FROM public.student_parents sp
        WHERE sp.student_id IN (SELECT public.get_my_student_ids())
      )
    )
  );

-- Previous schools RLS
CREATE POLICY prev_schools_admin_all ON public.student_previous_schools
  FOR ALL
  USING (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk')
  )
  WITH CHECK (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk')
  );

CREATE POLICY prev_schools_parent_student_read ON public.student_previous_schools
  FOR SELECT
  USING (
    institute_id = public.get_my_institute_id()
    AND (
      public.get_my_role() = 'teacher'
      OR student_id IN (SELECT public.get_my_student_ids())
    )
  );

-- Student documents RLS
CREATE POLICY student_docs_admin_all ON public.student_documents
  FOR ALL
  USING (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk')
  )
  WITH CHECK (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() IN ('super_admin', 'principal', 'fee_clerk')
  );

CREATE POLICY student_docs_parent_student_read ON public.student_documents
  FOR SELECT
  USING (
    institute_id = public.get_my_institute_id()
    AND student_id IN (SELECT public.get_my_student_ids())
  );

-- Medical info RLS (stricter: excludes fee_clerk from reading medical notes)
CREATE POLICY medical_info_principal_all ON public.student_medical_info
  FOR ALL
  USING (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() IN ('super_admin', 'principal')
  )
  WITH CHECK (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() IN ('super_admin', 'principal')
  );

CREATE POLICY medical_info_clerk_insert ON public.student_medical_info
  FOR INSERT
  WITH CHECK (
    institute_id = public.get_my_institute_id()
    AND public.get_my_role() = 'fee_clerk'
  );

CREATE POLICY medical_info_teacher_parent_read ON public.student_medical_info
  FOR SELECT
  USING (
    institute_id = public.get_my_institute_id()
    AND (
      public.get_my_role() = 'teacher'
      OR student_id IN (SELECT public.get_my_student_ids())
    )
  );

-- 7. Single-transaction admission RPC
CREATE OR REPLACE FUNCTION public.create_student_admission(payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_institute_id UUID := public.get_my_institute_id();
  v_role public.user_role := public.get_my_role();
  v_student JSONB := payload -> 'student';
  v_enrollment JSONB := payload -> 'enrollment';
  v_medical JSONB := payload -> 'medical_info';
  v_student_id UUID;
  v_admission_number TEXT;
  v_seq INT;
  v_academic_year_id UUID;
  v_class_id UUID;
  v_section_id UUID;
  v_guardian JSONB;
  v_guardian_id UUID;
  v_school JSONB;
  v_doc JSONB;
  v_sibling_ids UUID[];
BEGIN
  IF v_institute_id IS NULL OR v_role NOT IN ('super_admin', 'principal', 'fee_clerk') THEN
    RAISE EXCEPTION 'Unauthorized to create student admission';
  END IF;

  -- Generate sequential admission number per institute & year
  SELECT COUNT(*) + 1 INTO v_seq
  FROM public.students
  WHERE institute_id = v_institute_id;

  v_admission_number := 'ADM-' || EXTRACT(YEAR FROM COALESCE((v_student->>'admission_date')::DATE, CURRENT_DATE))::TEXT
    || '-' || LPAD(v_seq::TEXT, 4, '0');

  SELECT ARRAY(
    SELECT jsonb_array_elements_text(COALESCE(v_student->'sibling_ids', '[]'::JSONB))::UUID
  ) INTO v_sibling_ids;

  INSERT INTO public.students (
    institute_id, admission_number, first_name, middle_name, last_name,
    date_of_birth, gender, photo_url, blood_group, nationality, religion,
    mother_tongue, category, aadhaar_number, admission_date, gr_number,
    admission_type, student_type, medium_of_instruction,
    current_address, permanent_address, city, state, pincode, phone, email,
    emergency_contact_name, emergency_contact_phone, emergency_contact_relationship,
    transport_needed, transport_route_stop, special_needs, sibling_ids
  )
  VALUES (
    v_institute_id,
    v_admission_number,
    v_student->>'first_name',
    v_student->>'middle_name',
    v_student->>'last_name',
    (v_student->>'date_of_birth')::DATE,
    v_student->>'gender',
    v_student->>'photo_url',
    v_student->>'blood_group',
    COALESCE(v_student->>'nationality', 'Indian'),
    v_student->>'religion',
    v_student->>'mother_tongue',
    v_student->>'category',
    v_student->>'aadhaar_number',
    COALESCE((v_student->>'admission_date')::DATE, CURRENT_DATE),
    v_student->>'gr_number',
    COALESCE(v_student->>'admission_type', 'new'),
    COALESCE(v_student->>'student_type', 'day_scholar'),
    COALESCE(v_student->>'medium_of_instruction', 'English'),
    v_student->>'current_address',
    v_student->>'permanent_address',
    v_student->>'city',
    v_student->>'state',
    v_student->>'pincode',
    v_student->>'phone',
    v_student->>'email',
    v_student->>'emergency_contact_name',
    v_student->>'emergency_contact_phone',
    v_student->>'emergency_contact_relationship',
    COALESCE((v_student->>'transport_needed')::BOOLEAN, FALSE),
    v_student->>'transport_route_stop',
    v_student->>'special_needs',
    COALESCE(v_sibling_ids, '{}')
  )
  RETURNING id INTO v_student_id;

  -- Resolve academic year, class, section and insert enrollment
  SELECT id INTO v_academic_year_id
  FROM public.academic_years
  WHERE institute_id = v_institute_id
    AND (name = v_enrollment->>'academic_year' OR is_current = TRUE)
  ORDER BY (name = v_enrollment->>'academic_year') DESC
  LIMIT 1;

  SELECT id INTO v_class_id
  FROM public.classes
  WHERE institute_id = v_institute_id AND name = v_enrollment->>'class_name'
  LIMIT 1;

  SELECT id INTO v_section_id
  FROM public.sections
  WHERE institute_id = v_institute_id
    AND class_id = v_class_id
    AND name = v_enrollment->>'section_name'
  LIMIT 1;

  IF v_academic_year_id IS NOT NULL AND v_class_id IS NOT NULL AND v_section_id IS NOT NULL THEN
    INSERT INTO public.student_enrollments (
      institute_id, student_id, academic_year_id, class_id, section_id, roll_number
    )
    VALUES (
      v_institute_id,
      v_student_id,
      v_academic_year_id,
      v_class_id,
      v_section_id,
      (v_enrollment->>'roll_number')::INT
    );
  END IF;

  -- Insert guardians & link via student_parents
  FOR v_guardian IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'guardians', '[]'::JSONB))
  LOOP
    INSERT INTO public.guardians (
      institute_id, name, phone, email, occupation, qualification, annual_income, relationship
    )
    VALUES (
      v_institute_id,
      v_guardian->>'name',
      v_guardian->>'phone',
      v_guardian->>'email',
      v_guardian->>'occupation',
      v_guardian->>'qualification',
      v_guardian->>'annual_income',
      v_guardian->>'relationship'
    )
    RETURNING id INTO v_guardian_id;

    INSERT INTO public.student_parents (
      institute_id, student_id, guardian_id, relationship, is_primary
    )
    VALUES (
      v_institute_id,
      v_student_id,
      v_guardian_id,
      v_guardian->>'relationship',
      COALESCE((v_guardian->>'is_primary')::BOOLEAN, FALSE)
    );
  END LOOP;

  -- Insert previous schools
  FOR v_school IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'previous_schools', '[]'::JSONB))
  LOOP
    INSERT INTO public.student_previous_schools (
      institute_id, student_id, school_name, board, last_class_attended,
      year_of_passing, percentage_or_grade, reason_for_leaving, tc_number, tc_date
    )
    VALUES (
      v_institute_id,
      v_student_id,
      v_school->>'school_name',
      v_school->>'board',
      v_school->>'last_class_attended',
      v_school->>'year_of_passing',
      v_school->>'percentage_or_grade',
      v_school->>'reason_for_leaving',
      v_school->>'tc_number',
      (v_school->>'tc_date')::DATE
    );
  END LOOP;

  -- Insert medical info if any field is provided
  IF v_medical IS NOT NULL AND (
    v_medical->>'allergies' IS NOT NULL
    OR v_medical->>'conditions' IS NOT NULL
    OR v_medical->>'doctor_contact' IS NOT NULL
  ) THEN
    INSERT INTO public.student_medical_info (
      institute_id, student_id, allergies, conditions, doctor_contact
    )
    VALUES (
      v_institute_id,
      v_student_id,
      v_medical->>'allergies',
      v_medical->>'conditions',
      v_medical->>'doctor_contact'
    );
  END IF;

  -- Insert uploaded document records
  FOR v_doc IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'documents', '[]'::JSONB))
  LOOP
    INSERT INTO public.student_documents (
      institute_id, student_id, doc_type, file_name, file_url
    )
    VALUES (
      v_institute_id,
      v_student_id,
      v_doc->>'doc_type',
      v_doc->>'file_name',
      v_doc->>'file_url'
    );
  END LOOP;

  RETURN jsonb_build_object(
    'student_id', v_student_id,
    'admission_number', v_admission_number
  );
END;
$$;
