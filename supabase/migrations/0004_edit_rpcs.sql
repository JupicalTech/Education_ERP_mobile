-- Edit RPCs for Students and Teachers (Single-Institute)
-- Depends on 0001_v1_schema.sql, 0002_student_admission.sql, 0003_teachers.sql

-- ============================================================================
-- 1. update_student_admission(p_student_id uuid, payload jsonb)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_student_admission(
  p_student_id UUID,
  payload JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role := public.get_my_role();
  v_student JSONB := payload -> 'student';
  v_enrollment JSONB := payload -> 'enrollment';
  v_medical JSONB := payload -> 'medical_info';
  v_admission_number TEXT;
  v_academic_year_id UUID;
  v_class_id UUID;
  v_section_id UUID;
  v_guardian JSONB;
  v_guardian_id UUID;
  v_school JSONB;
  v_doc JSONB;
  v_sibling_ids UUID[];
  v_old_guardian_ids UUID[];
BEGIN
  IF v_role NOT IN ('super_admin', 'principal', 'fee_clerk') THEN
    RAISE EXCEPTION 'Unauthorized to update student admission';
  END IF;

  SELECT ARRAY(
    SELECT jsonb_array_elements_text(COALESCE(v_student->'sibling_ids', '[]'::JSONB))::UUID
  ) INTO v_sibling_ids;

  UPDATE public.students
  SET
    first_name = COALESCE(NULLIF(v_student->>'first_name', ''), first_name),
    middle_name = v_student->>'middle_name',
    last_name = COALESCE(v_student->>'last_name', last_name),
    date_of_birth = (v_student->>'date_of_birth')::DATE,
    gender = v_student->>'gender',
    photo_url = v_student->>'photo_url',
    blood_group = v_student->>'blood_group',
    nationality = COALESCE(NULLIF(v_student->>'nationality', ''), 'Indian'),
    religion = v_student->>'religion',
    mother_tongue = v_student->>'mother_tongue',
    category = v_student->>'category',
    aadhaar_number = v_student->>'aadhaar_number',
    admission_date = COALESCE((v_student->>'admission_date')::DATE, admission_date),
    gr_number = v_student->>'gr_number',
    admission_type = COALESCE(NULLIF(v_student->>'admission_type', ''), admission_type),
    student_type = COALESCE(NULLIF(v_student->>'student_type', ''), student_type),
    medium_of_instruction = COALESCE(NULLIF(v_student->>'medium_of_instruction', ''), medium_of_instruction),
    current_address = v_student->>'current_address',
    permanent_address = v_student->>'permanent_address',
    city = v_student->>'city',
    state = v_student->>'state',
    pincode = v_student->>'pincode',
    phone = v_student->>'phone',
    email = v_student->>'email',
    emergency_contact_name = v_student->>'emergency_contact_name',
    emergency_contact_phone = v_student->>'emergency_contact_phone',
    emergency_contact_relationship = v_student->>'emergency_contact_relationship',
    transport_needed = COALESCE((v_student->>'transport_needed')::BOOLEAN, FALSE),
    transport_route_stop = v_student->>'transport_route_stop',
    special_needs = v_student->>'special_needs',
    sibling_ids = COALESCE(v_sibling_ids, '{}'),
    updated_at = NOW()
  WHERE id = p_student_id
  RETURNING admission_number INTO v_admission_number;

  IF v_admission_number IS NULL THEN
    RAISE EXCEPTION 'Student not found';
  END IF;

  -- Resolve academic year, class, section and upsert enrollment
  SELECT id INTO v_academic_year_id
  FROM public.academic_years
  WHERE (name = v_enrollment->>'academic_year' OR is_current = TRUE)
  ORDER BY (name = v_enrollment->>'academic_year') DESC
  LIMIT 1;

  SELECT id INTO v_class_id
  FROM public.classes
  WHERE name = v_enrollment->>'class_name'
  LIMIT 1;

  SELECT id INTO v_section_id
  FROM public.sections
  WHERE class_id = v_class_id
    AND name = v_enrollment->>'section_name'
  LIMIT 1;

  IF v_academic_year_id IS NOT NULL AND v_class_id IS NOT NULL AND v_section_id IS NOT NULL THEN
    INSERT INTO public.student_enrollments (
      student_id, academic_year_id, class_id, section_id, roll_number
    )
    VALUES (
      p_student_id,
      v_academic_year_id,
      v_class_id,
      v_section_id,
      (v_enrollment->>'roll_number')::INT
    )
    ON CONFLICT (student_id, academic_year_id) DO UPDATE SET
      class_id = EXCLUDED.class_id,
      section_id = EXCLUDED.section_id,
      roll_number = EXCLUDED.roll_number;
  END IF;

  -- Replace guardians & student_parents links
  SELECT ARRAY(
    SELECT guardian_id FROM public.student_parents
    WHERE student_id = p_student_id AND guardian_id IS NOT NULL
  ) INTO v_old_guardian_ids;

  DELETE FROM public.student_parents WHERE student_id = p_student_id;

  IF v_old_guardian_ids IS NOT NULL AND array_length(v_old_guardian_ids, 1) > 0 THEN
    DELETE FROM public.guardians g
    WHERE g.id = ANY(v_old_guardian_ids)
      AND NOT EXISTS (
        SELECT 1 FROM public.student_parents sp WHERE sp.guardian_id = g.id
      );
  END IF;

  FOR v_guardian IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'guardians', '[]'::JSONB))
  LOOP
    INSERT INTO public.guardians (
      name, phone, email, occupation, qualification, annual_income, relationship
    )
    VALUES (
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
      student_id, guardian_id, relationship, is_primary
    )
    VALUES (
      p_student_id,
      v_guardian_id,
      v_guardian->>'relationship',
      COALESCE((v_guardian->>'is_primary')::BOOLEAN, FALSE)
    );
  END LOOP;

  -- Replace previous schools
  DELETE FROM public.student_previous_schools WHERE student_id = p_student_id;

  FOR v_school IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'previous_schools', '[]'::JSONB))
  LOOP
    INSERT INTO public.student_previous_schools (
      student_id, school_name, board, last_class_attended,
      year_of_passing, percentage_or_grade, reason_for_leaving, tc_number, tc_date
    )
    VALUES (
      p_student_id,
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

  -- Medical info: restricted to super_admin & principal (fee_clerk must not touch medical info)
  IF v_role IN ('super_admin', 'principal') THEN
    IF v_medical IS NOT NULL AND (
      NULLIF(v_medical->>'allergies', '') IS NOT NULL
      OR NULLIF(v_medical->>'conditions', '') IS NOT NULL
      OR NULLIF(v_medical->>'doctor_contact', '') IS NOT NULL
    ) THEN
      INSERT INTO public.student_medical_info (
        student_id, allergies, conditions, doctor_contact
      )
      VALUES (
        p_student_id,
        v_medical->>'allergies',
        v_medical->>'conditions',
        v_medical->>'doctor_contact'
      )
      ON CONFLICT (student_id) DO UPDATE SET
        allergies = EXCLUDED.allergies,
        conditions = EXCLUDED.conditions,
        doctor_contact = EXCLUDED.doctor_contact,
        updated_at = NOW();
    ELSE
      DELETE FROM public.student_medical_info WHERE student_id = p_student_id;
    END IF;
  END IF;

  -- Replace document records
  DELETE FROM public.student_documents WHERE student_id = p_student_id;

  FOR v_doc IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'documents', '[]'::JSONB))
  LOOP
    INSERT INTO public.student_documents (
      student_id, doc_type, file_name, file_url
    )
    VALUES (
      p_student_id,
      v_doc->>'doc_type',
      v_doc->>'file_name',
      v_doc->>'file_url'
    );
  END LOOP;

  RETURN jsonb_build_object(
    'student_id', p_student_id,
    'admission_number', v_admission_number
  );
END;
$$;

-- ============================================================================
-- 2. update_teacher(p_teacher_id uuid, payload jsonb)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_teacher(
  p_teacher_id UUID,
  payload JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role := public.get_my_role();
  v_profile_id UUID;
  v_item JSONB;
  v_subj_text TEXT;
  v_subj_id UUID;
  v_year_id UUID;
  v_sec_id UUID;
  v_class_teacher_raw TEXT;
  v_class_teacher_section_id UUID;
  v_uuid_regex CONSTANT TEXT := '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
BEGIN
  IF v_role NOT IN ('super_admin', 'principal') THEN
    RAISE EXCEPTION 'Unauthorized: only principal or super_admin can update teachers';
  END IF;

  SELECT profile_id INTO v_profile_id
  FROM public.teachers
  WHERE id = p_teacher_id;

  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Teacher not found';
  END IF;

  -- Update profile
  UPDATE public.profiles
  SET
    first_name = COALESCE(NULLIF(payload->>'first_name', ''), first_name),
    last_name = COALESCE(payload->>'last_name', last_name),
    phone = NULLIF(payload->>'phone', ''),
    avatar_url = NULLIF(payload->>'avatar_url', ''),
    is_active = COALESCE((payload->>'is_active')::BOOLEAN, is_active),
    updated_at = NOW()
  WHERE id = v_profile_id;

  -- Update teacher record
  UPDATE public.teachers
  SET
    middle_name = NULLIF(payload->>'middle_name', ''),
    date_of_birth = NULLIF(payload->>'date_of_birth', '')::DATE,
    gender = NULLIF(payload->>'gender', ''),
    blood_group = NULLIF(payload->>'blood_group', ''),
    marital_status = NULLIF(payload->>'marital_status', ''),
    nationality = COALESCE(NULLIF(payload->>'nationality', ''), 'Indian'),
    religion = NULLIF(payload->>'religion', ''),
    aadhaar_number = NULLIF(payload->>'aadhaar_number', ''),
    pan_number = NULLIF(payload->>'pan_number', ''),
    alternate_phone = NULLIF(payload->>'alternate_phone', ''),
    email = COALESCE(NULLIF(payload->>'email', ''), email),
    current_address = NULLIF(payload->>'current_address', ''),
    permanent_address = NULLIF(payload->>'permanent_address', ''),
    city = NULLIF(payload->>'city', ''),
    state = NULLIF(payload->>'state', ''),
    pincode = NULLIF(payload->>'pincode', ''),
    emergency_contact_name = NULLIF(payload->>'emergency_contact_name', ''),
    emergency_contact_phone = NULLIF(payload->>'emergency_contact_phone', ''),
    emergency_contact_relationship = NULLIF(payload->>'emergency_contact_relationship', ''),
    designation = COALESCE(NULLIF(payload->>'designation', ''), designation),
    department = NULLIF(payload->>'department', ''),
    employment_type = COALESCE(NULLIF(payload->>'employment_type', '')::public.teacher_employment_type, employment_type),
    joining_date = COALESCE(NULLIF(payload->>'joining_date', '')::DATE, joining_date),
    probation_end_date = NULLIF(payload->>'probation_end_date', '')::DATE,
    reporting_to = NULLIF(payload->>'reporting_to', '')::UUID,
    status = COALESCE(NULLIF(payload->>'status', '')::public.teacher_status, status),
    resignation_date = NULLIF(payload->>'resignation_date', '')::DATE,
    teaching_license_number = NULLIF(payload->>'teaching_license_number', ''),
    updated_at = NOW()
  WHERE id = p_teacher_id;

  -- Replace qualifications
  DELETE FROM public.teacher_qualifications WHERE teacher_id = p_teacher_id;
  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'qualifications', '[]'::JSONB))
  LOOP
    INSERT INTO public.teacher_qualifications (
      teacher_id, degree, specialization, institution, year_of_passing, percentage_or_grade
    ) VALUES (
      p_teacher_id,
      v_item->>'degree',
      NULLIF(v_item->>'specialization', ''),
      v_item->>'institution',
      NULLIF(v_item->>'year_of_passing', ''),
      NULLIF(v_item->>'percentage_or_grade', '')
    );
  END LOOP;

  -- Replace previous experience
  DELETE FROM public.teacher_experience WHERE teacher_id = p_teacher_id;
  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'experiences', '[]'::JSONB))
  LOOP
    INSERT INTO public.teacher_experience (
      teacher_id, organization, designation, from_date, to_date, reason_for_leaving
    ) VALUES (
      p_teacher_id,
      v_item->>'organization',
      NULLIF(v_item->>'designation', ''),
      (v_item->>'from_date')::DATE,
      (v_item->>'to_date')::DATE,
      NULLIF(v_item->>'reason_for_leaving', '')
    );
  END LOOP;

  -- Replace teachable subjects (accepts UUID or subject name)
  DELETE FROM public.teacher_subjects WHERE teacher_id = p_teacher_id;
  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'teachable_subject_ids', '[]'::JSONB))
  LOOP
    v_subj_text := v_item#>>'{}';
    IF v_subj_text ~ v_uuid_regex THEN
      v_subj_id := v_subj_text::UUID;
    ELSE
      SELECT id INTO v_subj_id FROM public.subjects WHERE name = v_subj_text LIMIT 1;
    END IF;

    IF v_subj_id IS NOT NULL THEN
      INSERT INTO public.teacher_subjects (teacher_id, subject_id)
      VALUES (p_teacher_id, v_subj_id)
      ON CONFLICT DO NOTHING;
    END IF;
  END LOOP;

  -- Replace class-subject-teacher assignments for current academic year
  SELECT id INTO v_year_id FROM public.academic_years WHERE is_current = TRUE LIMIT 1;
  IF v_year_id IS NOT NULL THEN
    DELETE FROM public.class_subject_teachers
    WHERE teacher_id = v_profile_id AND academic_year_id = v_year_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'assignments', '[]'::JSONB))
    LOOP
      -- Resolve section_id
      IF COALESCE(v_item->>'section_id', '') ~ v_uuid_regex THEN
        v_sec_id := (v_item->>'section_id')::UUID;
      ELSE
        SELECT s.id INTO v_sec_id
        FROM public.sections s
        JOIN public.classes c ON c.id = s.class_id
        WHERE c.name = v_item->>'class_name' AND s.name = v_item->>'section_name'
        LIMIT 1;
      END IF;

      -- Resolve subject_id
      IF COALESCE(v_item->>'subject_id', '') ~ v_uuid_regex THEN
        v_subj_id := (v_item->>'subject_id')::UUID;
      ELSE
        SELECT id INTO v_subj_id
        FROM public.subjects
        WHERE name = COALESCE(NULLIF(v_item->>'subject', ''), v_item->>'subject_id')
        LIMIT 1;
      END IF;

      IF v_sec_id IS NOT NULL AND v_subj_id IS NOT NULL THEN
        INSERT INTO public.class_subject_teachers (
          academic_year_id, section_id, subject_id, teacher_id
        ) VALUES (
          v_year_id, v_sec_id, v_subj_id, v_profile_id
        )
        ON CONFLICT DO NOTHING;
      END IF;
    END LOOP;
  END IF;

  -- Update Class Teacher assignment (one class teacher per section)
  UPDATE public.sections
  SET class_teacher_id = NULL
  WHERE class_teacher_id = v_profile_id;

  v_class_teacher_raw := NULLIF(payload->>'class_teacher_section_id', '');
  IF v_class_teacher_raw IS NOT NULL THEN
    IF v_class_teacher_raw ~ v_uuid_regex THEN
      v_class_teacher_section_id := v_class_teacher_raw::UUID;
    ELSE
      SELECT s.id INTO v_class_teacher_section_id
      FROM public.sections s
      JOIN public.classes c ON c.id = s.class_id
      WHERE (c.name || '-' || s.name) = v_class_teacher_raw
      LIMIT 1;
    END IF;

    IF v_class_teacher_section_id IS NOT NULL THEN
      UPDATE public.sections
      SET class_teacher_id = v_profile_id
      WHERE id = v_class_teacher_section_id;
    END IF;
  END IF;

  -- Replace documents
  DELETE FROM public.teacher_documents WHERE teacher_id = p_teacher_id;
  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(payload->'documents', '[]'::JSONB))
  LOOP
    INSERT INTO public.teacher_documents (teacher_id, doc_type, file_name, file_url)
    VALUES (
      p_teacher_id,
      v_item->>'doc_type',
      NULLIF(v_item->>'file_name', ''),
      v_item->>'file_url'
    );
  END LOOP;

  -- Upsert Salary & Bank Details (principal / super_admin only)
  IF payload ? 'bank_details' AND payload->'bank_details' IS NOT NULL THEN
    INSERT INTO public.teacher_bank_details (
      teacher_id, basic_salary, allowances, deductions,
      bank_name, account_number, ifsc_code, account_holder_name, pf_number, esi_number
    ) VALUES (
      p_teacher_id,
      COALESCE((payload->'bank_details'->>'basic_salary')::NUMERIC, 0),
      COALESCE((payload->'bank_details'->>'allowances')::NUMERIC, 0),
      COALESCE((payload->'bank_details'->>'deductions')::NUMERIC, 0),
      NULLIF(payload->'bank_details'->>'bank_name', ''),
      NULLIF(payload->'bank_details'->>'account_number', ''),
      NULLIF(payload->'bank_details'->>'ifsc_code', ''),
      NULLIF(payload->'bank_details'->>'account_holder_name', ''),
      NULLIF(payload->'bank_details'->>'pf_number', ''),
      NULLIF(payload->'bank_details'->>'esi_number', '')
    )
    ON CONFLICT (teacher_id) DO UPDATE SET
      basic_salary = EXCLUDED.basic_salary,
      allowances = EXCLUDED.allowances,
      deductions = EXCLUDED.deductions,
      bank_name = EXCLUDED.bank_name,
      account_number = EXCLUDED.account_number,
      ifsc_code = EXCLUDED.ifsc_code,
      account_holder_name = EXCLUDED.account_holder_name,
      pf_number = EXCLUDED.pf_number,
      esi_number = EXCLUDED.esi_number,
      updated_at = NOW();
  END IF;

  RETURN p_teacher_id;
END;
$$;
