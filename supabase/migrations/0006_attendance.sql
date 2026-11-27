-- Attendance, Leave Requests, Absence Notifications & Reports (Single-Institute)
-- Depends on 0001_v1_schema.sql, 0002_student_admission.sql, 0005_academic_years_and_mappings.sql

-- ============================================================================
-- 1. Enums
-- ============================================================================

DO $$ BEGIN
  CREATE TYPE public.attendance_status AS ENUM (
    'present', 'absent', 'late', 'half_day', 'leave'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.leave_request_status AS ENUM (
    'pending', 'approved', 'rejected'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- 2. Tables
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.student_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  section_id UUID NOT NULL REFERENCES public.sections(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status public.attendance_status NOT NULL,
  marked_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  marked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, date)
);

CREATE INDEX IF NOT EXISTS idx_attendance_section_date
  ON public.student_attendance(section_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_student_date
  ON public.student_attendance(student_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_attendance_year
  ON public.student_attendance(academic_year_id);

CREATE TABLE IF NOT EXISTS public.leave_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  section_id UUID NOT NULL REFERENCES public.sections(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
  requested_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  from_date DATE NOT NULL,
  to_date DATE NOT NULL,
  reason TEXT NOT NULL,
  status public.leave_request_status NOT NULL DEFAULT 'pending',
  reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  review_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (to_date >= from_date)
);

CREATE INDEX IF NOT EXISTS idx_leave_requests_student
  ON public.leave_requests(student_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_leave_requests_section_status
  ON public.leave_requests(section_id, status);

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient
  ON public.notifications(recipient_id, is_read, created_at DESC);

-- ============================================================================
-- 3. Row-Level Security (fee_clerk intentionally has NO access to attendance)
-- ============================================================================

ALTER TABLE public.student_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- student_attendance policies
CREATE POLICY attendance_admin_all ON public.student_attendance
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY attendance_teacher_select ON public.student_attendance
  FOR SELECT
  USING (
    public.get_my_role() = 'teacher'
    AND section_id IN (
      SELECT id FROM public.sections WHERE class_teacher_id = auth.uid()
    )
  );

CREATE POLICY attendance_teacher_insert ON public.student_attendance
  FOR INSERT
  WITH CHECK (
    public.get_my_role() = 'teacher'
    AND section_id IN (
      SELECT id FROM public.sections WHERE class_teacher_id = auth.uid()
    )
  );

CREATE POLICY attendance_teacher_update ON public.student_attendance
  FOR UPDATE
  USING (
    public.get_my_role() = 'teacher'
    AND section_id IN (
      SELECT id FROM public.sections WHERE class_teacher_id = auth.uid()
    )
  )
  WITH CHECK (
    public.get_my_role() = 'teacher'
    AND section_id IN (
      SELECT id FROM public.sections WHERE class_teacher_id = auth.uid()
    )
  );

CREATE POLICY attendance_parent_student_select ON public.student_attendance
  FOR SELECT
  USING (student_id IN (SELECT public.get_my_student_ids()));

-- leave_requests policies
CREATE POLICY leave_admin_all ON public.leave_requests
  FOR ALL
  USING (public.get_my_role() IN ('super_admin', 'principal'))
  WITH CHECK (public.get_my_role() IN ('super_admin', 'principal'));

CREATE POLICY leave_teacher_select ON public.leave_requests
  FOR SELECT
  USING (
    public.get_my_role() = 'teacher'
    AND section_id IN (
      SELECT id FROM public.sections WHERE class_teacher_id = auth.uid()
    )
  );

CREATE POLICY leave_teacher_update ON public.leave_requests
  FOR UPDATE
  USING (
    public.get_my_role() = 'teacher'
    AND section_id IN (
      SELECT id FROM public.sections WHERE class_teacher_id = auth.uid()
    )
  )
  WITH CHECK (
    public.get_my_role() = 'teacher'
    AND section_id IN (
      SELECT id FROM public.sections WHERE class_teacher_id = auth.uid()
    )
  );

CREATE POLICY leave_parent_select ON public.leave_requests
  FOR SELECT
  USING (student_id IN (SELECT public.get_my_student_ids()));

CREATE POLICY leave_parent_insert ON public.leave_requests
  FOR INSERT
  WITH CHECK (
    public.get_my_role() = 'parent'
    AND student_id IN (SELECT public.get_my_student_ids())
    AND requested_by = auth.uid()
  );

-- notifications policies
CREATE POLICY notifications_self_select ON public.notifications
  FOR SELECT
  USING (
    recipient_id = auth.uid()
    OR public.get_my_role() IN ('super_admin', 'principal')
  );

CREATE POLICY notifications_self_update ON public.notifications
  FOR UPDATE
  USING (recipient_id = auth.uid())
  WITH CHECK (recipient_id = auth.uid());

-- ============================================================================
-- 4. Attendance RPCs
-- ============================================================================

-- 4a. Sections the logged-in user can mark attendance for
CREATE OR REPLACE FUNCTION public.get_attendance_sections()
RETURNS TABLE (
  id UUID,
  label TEXT,
  class_name TEXT,
  section_name TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role := public.get_my_role();
BEGIN
  IF v_role NOT IN ('super_admin', 'principal', 'teacher') THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    s.id,
    (c.name || '-' || s.name) AS label,
    c.name AS class_name,
    s.name AS section_name
  FROM public.sections s
  JOIN public.classes c ON c.id = s.class_id
  WHERE (
    v_role IN ('super_admin', 'principal')
    OR s.class_teacher_id = auth.uid()
  )
  ORDER BY c.display_order ASC, c.name ASC, s.name ASC;
END;
$$;

-- 4b. Roster for a section & date (approved leave defaults to 'leave', else 'present')
CREATE OR REPLACE FUNCTION public.get_section_attendance_roster(
  p_section_id UUID,
  p_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  student_id UUID,
  roll_number INT,
  student_name TEXT,
  status public.attendance_status
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role := public.get_my_role();
BEGIN
  IF v_role NOT IN ('super_admin', 'principal', 'teacher') THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF v_role = 'teacher' AND NOT EXISTS (
    SELECT 1 FROM public.sections
    WHERE id = p_section_id AND class_teacher_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Unauthorized for this section';
  END IF;

  RETURN QUERY
  SELECT
    st.id AS student_id,
    COALESCE(se.roll_number, 0) AS roll_number,
    TRIM(st.first_name || ' ' || st.last_name) AS student_name,
    COALESCE(
      sa.status,
      CASE
        WHEN EXISTS (
          SELECT 1 FROM public.leave_requests lr
          WHERE lr.student_id = st.id
            AND lr.status = 'approved'
            AND p_date BETWEEN lr.from_date AND lr.to_date
        ) THEN 'leave'::public.attendance_status
        ELSE 'present'::public.attendance_status
      END
    ) AS status
  FROM public.student_enrollments se
  JOIN public.academic_years ay ON ay.id = se.academic_year_id
  JOIN public.students st ON st.id = se.student_id
  LEFT JOIN public.student_attendance sa
    ON sa.student_id = st.id
    AND sa.date = p_date
  WHERE se.section_id = p_section_id
    AND ay.is_current = TRUE
    AND st.is_active = TRUE
  ORDER BY se.roll_number ASC NULLS LAST, st.first_name ASC, st.last_name ASC;
END;
$$;

-- 4c. Idempotent bulk submit RPC (accepts exceptions; defaults everyone else to present)
CREATE OR REPLACE FUNCTION public.submit_section_attendance(
  p_section_id UUID,
  p_date DATE,
  p_exceptions JSONB DEFAULT '[]'::JSONB
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role := public.get_my_role();
  v_year_id UUID;
  v_section_label TEXT;
  v_rec RECORD;
  v_status public.attendance_status;
  v_exception_status TEXT;
  v_count INT := 0;
BEGIN
  IF v_role NOT IN ('super_admin', 'principal', 'teacher') THEN
    RAISE EXCEPTION 'Unauthorized to mark attendance';
  END IF;

  IF v_role = 'teacher' AND NOT EXISTS (
    SELECT 1 FROM public.sections
    WHERE id = p_section_id AND class_teacher_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only the class teacher, principal, or super_admin can submit attendance for this section';
  END IF;

  SELECT id INTO v_year_id
  FROM public.academic_years
  WHERE is_current = TRUE
  LIMIT 1;

  IF v_year_id IS NULL THEN
    RAISE EXCEPTION 'No current academic year is set';
  END IF;

  SELECT (c.name || '-' || s.name) INTO v_section_label
  FROM public.sections s
  JOIN public.classes c ON c.id = s.class_id
  WHERE s.id = p_section_id;

  FOR v_rec IN
    SELECT st.id AS student_id, TRIM(st.first_name || ' ' || st.last_name) AS student_name
    FROM public.student_enrollments se
    JOIN public.students st ON st.id = se.student_id
    WHERE se.section_id = p_section_id
      AND se.academic_year_id = v_year_id
      AND st.is_active = TRUE
  LOOP
    SELECT elem->>'status' INTO v_exception_status
    FROM jsonb_array_elements(COALESCE(p_exceptions, '[]'::JSONB)) elem
    WHERE (elem->>'student_id')::UUID = v_rec.student_id
    LIMIT 1;

    IF v_exception_status IS NOT NULL THEN
      v_status := v_exception_status::public.attendance_status;
    ELSIF EXISTS (
      SELECT 1 FROM public.leave_requests lr
      WHERE lr.student_id = v_rec.student_id
        AND lr.status = 'approved'
        AND p_date BETWEEN lr.from_date AND lr.to_date
    ) THEN
      v_status := 'leave'::public.attendance_status;
    ELSE
      v_status := 'present'::public.attendance_status;
    END IF;

    INSERT INTO public.student_attendance (
      student_id, section_id, academic_year_id, date, status, marked_by, marked_at
    )
    VALUES (
      v_rec.student_id, p_section_id, v_year_id, p_date, v_status, auth.uid(), NOW()
    )
    ON CONFLICT (student_id, date) DO UPDATE SET
      section_id = EXCLUDED.section_id,
      academic_year_id = EXCLUDED.academic_year_id,
      status = EXCLUDED.status,
      marked_by = auth.uid(),
      marked_at = NOW(),
      updated_at = NOW();

    -- Create absence notification for linked parents (avoid duplicates on resubmit)
    IF v_status = 'absent'::public.attendance_status THEN
      INSERT INTO public.notifications (
        recipient_id, student_id, type, title, message
      )
      SELECT DISTINCT
        parent_uid,
        v_rec.student_id,
        'attendance_absent',
        'Absence Alert',
        v_rec.student_name || ' (' || COALESCE(v_section_label, '') || ') was marked absent on ' || TO_CHAR(p_date, 'DD Mon YYYY') || '.'
      FROM (
        SELECT COALESCE(sp.parent_profile_id, g.profile_id) AS parent_uid
        FROM public.student_parents sp
        LEFT JOIN public.guardians g ON g.id = sp.guardian_id
        WHERE sp.student_id = v_rec.student_id
      ) parents
      WHERE parent_uid IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM public.notifications n
          WHERE n.recipient_id = parent_uid
            AND n.student_id = v_rec.student_id
            AND n.type = 'attendance_absent'
            AND n.created_at::DATE = CURRENT_DATE
            AND n.message LIKE '%' || TO_CHAR(p_date, 'DD Mon YYYY') || '%'
        );
    END IF;

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

-- ============================================================================
-- 5. Leave Request RPCs
-- ============================================================================

CREATE OR REPLACE FUNCTION public.submit_leave_request(
  p_student_id UUID,
  p_from_date DATE,
  p_to_date DATE,
  p_reason TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role := public.get_my_role();
  v_year_id UUID;
  v_section_id UUID;
  v_leave_id UUID;
BEGIN
  IF v_role <> 'parent' OR p_student_id NOT IN (SELECT public.get_my_student_ids()) THEN
    RAISE EXCEPTION 'Unauthorized to submit leave request for this student';
  END IF;

  IF p_to_date < p_from_date THEN
    RAISE EXCEPTION 'End date cannot be before start date';
  END IF;

  IF TRIM(p_reason) = '' THEN
    RAISE EXCEPTION 'Reason is required';
  END IF;

  SELECT id INTO v_year_id FROM public.academic_years WHERE is_current = TRUE LIMIT 1;
  IF v_year_id IS NULL THEN
    RAISE EXCEPTION 'No current academic year is set';
  END IF;

  SELECT section_id INTO v_section_id
  FROM public.student_enrollments
  WHERE student_id = p_student_id AND academic_year_id = v_year_id
  LIMIT 1;

  IF v_section_id IS NULL THEN
    RAISE EXCEPTION 'Student is not enrolled in any section for the current academic year';
  END IF;

  INSERT INTO public.leave_requests (
    student_id, section_id, academic_year_id, requested_by, from_date, to_date, reason
  )
  VALUES (
    p_student_id, v_section_id, v_year_id, auth.uid(), p_from_date, p_to_date, TRIM(p_reason)
  )
  RETURNING id INTO v_leave_id;

  RETURN v_leave_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.review_leave_request(
  p_leave_id UUID,
  p_status public.leave_request_status,
  p_note TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role := public.get_my_role();
  v_leave public.leave_requests%ROWTYPE;
  v_day DATE;
BEGIN
  IF v_role NOT IN ('super_admin', 'principal', 'teacher') THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF p_status = 'pending' THEN
    RAISE EXCEPTION 'Review status must be approved or rejected';
  END IF;

  SELECT * INTO v_leave FROM public.leave_requests WHERE id = p_leave_id;
  IF v_leave.id IS NULL THEN
    RAISE EXCEPTION 'Leave request not found';
  END IF;

  IF v_role = 'teacher' AND NOT EXISTS (
    SELECT 1 FROM public.sections
    WHERE id = v_leave.section_id AND class_teacher_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only the class teacher or principal can review this leave request';
  END IF;

  UPDATE public.leave_requests
  SET
    status = p_status,
    reviewed_by = auth.uid(),
    reviewed_at = NOW(),
    review_note = NULLIF(TRIM(COALESCE(p_note, '')), ''),
    updated_at = NOW()
  WHERE id = p_leave_id;

  IF p_status = 'approved' THEN
    v_day := v_leave.from_date;
    WHILE v_day <= v_leave.to_date LOOP
      INSERT INTO public.student_attendance (
        student_id, section_id, academic_year_id, date, status, marked_by, marked_at
      )
      VALUES (
        v_leave.student_id, v_leave.section_id, v_leave.academic_year_id,
        v_day, 'leave'::public.attendance_status, auth.uid(), NOW()
      )
      ON CONFLICT (student_id, date) DO UPDATE SET
        status = 'leave'::public.attendance_status,
        marked_by = auth.uid(),
        marked_at = NOW(),
        updated_at = NOW();

      v_day := v_day + 1;
    END LOOP;
  END IF;
END;
$$;

-- ============================================================================
-- 6. Reporting & Dashboard RPCs
-- ============================================================================

-- 6a. Daily summary per section
CREATE OR REPLACE FUNCTION public.get_daily_attendance_summary(
  p_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  section_id UUID,
  section_label TEXT,
  total_students BIGINT,
  present_count BIGINT,
  absent_count BIGINT,
  late_count BIGINT,
  half_day_count BIGINT,
  leave_count BIGINT,
  is_marked BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role := public.get_my_role();
BEGIN
  IF v_role NOT IN ('super_admin', 'principal', 'teacher') THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  SELECT
    s.id AS section_id,
    (c.name || '-' || s.name) AS section_label,
    COUNT(DISTINCT se.student_id) AS total_students,
    COUNT(DISTINCT CASE WHEN sa.status = 'present' THEN sa.student_id END) AS present_count,
    COUNT(DISTINCT CASE WHEN sa.status = 'absent' THEN sa.student_id END) AS absent_count,
    COUNT(DISTINCT CASE WHEN sa.status = 'late' THEN sa.student_id END) AS late_count,
    COUNT(DISTINCT CASE WHEN sa.status = 'half_day' THEN sa.student_id END) AS half_day_count,
    COUNT(DISTINCT CASE WHEN sa.status = 'leave' THEN sa.student_id END) AS leave_count,
    (COUNT(sa.id) > 0) AS is_marked
  FROM public.sections s
  JOIN public.classes c ON c.id = s.class_id
  LEFT JOIN public.academic_years ay ON ay.is_current = TRUE
  LEFT JOIN public.student_enrollments se
    ON se.section_id = s.id AND se.academic_year_id = ay.id
  LEFT JOIN public.student_attendance sa
    ON sa.student_id = se.student_id AND sa.date = p_date
  WHERE (
    v_role IN ('super_admin', 'principal')
    OR s.class_teacher_id = auth.uid()
  )
  GROUP BY s.id, c.name, s.name, c.display_order
  ORDER BY c.display_order ASC, c.name ASC, s.name ASC;
END;
$$;

-- 6b. Monthly percentage per student
CREATE OR REPLACE FUNCTION public.get_student_monthly_attendance(
  p_student_id UUID,
  p_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT,
  p_month INT DEFAULT EXTRACT(MONTH FROM CURRENT_DATE)::INT
)
RETURNS TABLE (
  total_days BIGINT,
  present_days BIGINT,
  absent_days BIGINT,
  late_days BIGINT,
  half_day_days BIGINT,
  leave_days BIGINT,
  percentage NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role := public.get_my_role();
BEGIN
  IF v_role NOT IN ('super_admin', 'principal', 'teacher')
     AND p_student_id NOT IN (SELECT public.get_my_student_ids()) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  SELECT
    COUNT(*) AS total_days,
    COUNT(*) FILTER (WHERE status = 'present') AS present_days,
    COUNT(*) FILTER (WHERE status = 'absent') AS absent_days,
    COUNT(*) FILTER (WHERE status = 'late') AS late_days,
    COUNT(*) FILTER (WHERE status = 'half_day') AS half_day_days,
    COUNT(*) FILTER (WHERE status = 'leave') AS leave_days,
    CASE
      WHEN COUNT(*) = 0 THEN 100.0
      ELSE ROUND(
        (
          COUNT(*) FILTER (WHERE status IN ('present', 'late'))
          + COUNT(*) FILTER (WHERE status = 'half_day') * 0.5
        ) * 100.0 / COUNT(*),
        1
      )
    END AS percentage
  FROM public.student_attendance
  WHERE student_id = p_student_id
    AND EXTRACT(YEAR FROM date) = p_year
    AND EXTRACT(MONTH FROM date) = p_month;
END;
$$;

-- 6c. Students below threshold percentage (default 75%)
CREATE OR REPLACE FUNCTION public.get_low_attendance_students(
  p_threshold NUMERIC DEFAULT 75.0
)
RETURNS TABLE (
  student_id UUID,
  admission_number TEXT,
  student_name TEXT,
  class_section TEXT,
  marked_days BIGINT,
  attended_days NUMERIC,
  percentage NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role public.user_role := public.get_my_role();
BEGIN
  IF v_role NOT IN ('super_admin', 'principal', 'teacher') THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  WITH stats AS (
    SELECT
      st.id AS student_id,
      st.admission_number,
      TRIM(st.first_name || ' ' || st.last_name) AS student_name,
      (c.name || '-' || s.name) AS class_section,
      COUNT(sa.id) AS marked_days,
      (
        COUNT(sa.id) FILTER (WHERE sa.status IN ('present', 'late'))
        + COUNT(sa.id) FILTER (WHERE sa.status = 'half_day') * 0.5
      )::NUMERIC AS attended_days
    FROM public.student_enrollments se
    JOIN public.academic_years ay ON ay.id = se.academic_year_id AND ay.is_current = TRUE
    JOIN public.students st ON st.id = se.student_id AND st.is_active = TRUE
    JOIN public.sections s ON s.id = se.section_id
    JOIN public.classes c ON c.id = se.class_id
    JOIN public.student_attendance sa
      ON sa.student_id = st.id AND sa.academic_year_id = ay.id
    WHERE (
      v_role IN ('super_admin', 'principal')
      OR s.class_teacher_id = auth.uid()
    )
    GROUP BY st.id, st.admission_number, st.first_name, st.last_name, c.name, s.name
    HAVING COUNT(sa.id) > 0
  )
  SELECT
    stats.student_id,
    stats.admission_number,
    stats.student_name,
    stats.class_section,
    stats.marked_days,
    stats.attended_days,
    ROUND(stats.attended_days * 100.0 / stats.marked_days, 1) AS percentage
  FROM stats
  WHERE ROUND(stats.attended_days * 100.0 / stats.marked_days, 1) < p_threshold
  ORDER BY percentage ASC, stats.student_name ASC;
END;
$$;

-- 6d. Home dashboard attendance stats
CREATE OR REPLACE FUNCTION public.get_attendance_dashboard_stats(
  p_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_sections INT := 0;
  v_marked_sections INT := 0;
  v_total_marked INT := 0;
  v_present_like INT := 0;
  v_pct NUMERIC := 0;
BEGIN
  SELECT
    COUNT(*)::INT,
    COUNT(*) FILTER (WHERE is_marked)::INT,
    COALESCE(SUM(present_count + absent_count + late_count + half_day_count + leave_count), 0)::INT,
    COALESCE(SUM(present_count + late_count), 0)::INT
  INTO v_total_sections, v_marked_sections, v_total_marked, v_present_like
  FROM public.get_daily_attendance_summary(p_date);

  IF v_total_marked > 0 THEN
    v_pct := ROUND(v_present_like * 100.0 / v_total_marked, 1);
  END IF;

  RETURN jsonb_build_object(
    'total_sections', v_total_sections,
    'marked_sections', v_marked_sections,
    'pending_sections', GREATEST(v_total_sections - v_marked_sections, 0),
    'total_marked', v_total_marked,
    'attendance_percent', v_pct
  );
END;
$$;
