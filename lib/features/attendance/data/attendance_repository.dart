import 'package:supabase_flutter/supabase_flutter.dart';

import 'attendance_model.dart';

abstract interface class AttendanceRepository {
  Future<List<AttendanceSection>> fetchSections();
  Future<List<AttendanceRosterEntry>> fetchRoster({
    required String sectionId,
    required DateTime date,
  });
  Future<void> submitSectionAttendance({
    required String sectionId,
    required DateTime date,
    required List<AttendanceRosterEntry> entries,
  });

  Future<List<MyStudentSummary>> fetchMyStudents();
  Future<MonthlyAttendanceSummary> fetchMonthlySummary({
    required String studentId,
    required int year,
    required int month,
  });
  Future<List<StudentAttendanceRecord>> fetchStudentHistory({
    required String studentId,
    required int year,
    required int month,
  });

  Future<List<LeaveRequestItem>> fetchLeaveRequests();
  Future<void> submitLeaveRequest({
    required String studentId,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  });
  Future<void> reviewLeaveRequest({
    required String leaveId,
    required LeaveRequestStatus status,
    String? note,
  });

  Future<List<DailySectionSummary>> fetchDailySummary(DateTime date);
  Future<List<LowAttendanceStudent>> fetchLowAttendanceStudents({
    double threshold = 75,
  });
  Future<AttendanceDashboardStats> fetchDashboardStats(DateTime date);
}

class SupabaseAttendanceRepository implements AttendanceRepository {
  SupabaseAttendanceRepository(this._client);

  final SupabaseClient _client;

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<AttendanceSection>> fetchSections() async {
    final rows = await _client.rpc<List<dynamic>>('get_attendance_sections');
    return rows
        .map((e) => AttendanceSection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AttendanceRosterEntry>> fetchRoster({
    required String sectionId,
    required DateTime date,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'get_section_attendance_roster',
      params: {'p_section_id': sectionId, 'p_date': _fmtDate(date)},
    );
    return rows
        .map((e) => AttendanceRosterEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> submitSectionAttendance({
    required String sectionId,
    required DateTime date,
    required List<AttendanceRosterEntry> entries,
  }) async {
    // Only send non-present exceptions; RPC handles everyone else as present.
    final exceptions = entries
        .where((e) => e.status != AttendanceStatus.present)
        .map((e) => e.toExceptionJson())
        .toList();

    await _client.rpc<int>(
      'submit_section_attendance',
      params: {
        'p_section_id': sectionId,
        'p_date': _fmtDate(date),
        'p_exceptions': exceptions,
      },
    );
  }

  @override
  Future<List<MyStudentSummary>> fetchMyStudents() async {
    final rows = await _client
        .from('students')
        .select(
          'id, admission_number, first_name, last_name, '
          'student_enrollments(classes(name), sections(name))',
        )
        .order('first_name', ascending: true);

    return (rows as List<dynamic>)
        .map((r) => MyStudentSummary.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MonthlyAttendanceSummary> fetchMonthlySummary({
    required String studentId,
    required int year,
    required int month,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'get_student_monthly_attendance',
      params: {'p_student_id': studentId, 'p_year': year, 'p_month': month},
    );
    if (rows.isEmpty) {
      return const MonthlyAttendanceSummary(
        totalDays: 0,
        presentDays: 0,
        absentDays: 0,
        lateDays: 0,
        halfDayDays: 0,
        leaveDays: 0,
        percentage: 100.0,
      );
    }
    return MonthlyAttendanceSummary.fromJson(rows.first as Map<String, dynamic>);
  }

  @override
  Future<List<StudentAttendanceRecord>> fetchStudentHistory({
    required String studentId,
    required int year,
    required int month,
  }) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    final rows = await _client
        .from('student_attendance')
        .select('date, status')
        .eq('student_id', studentId)
        .gte('date', _fmtDate(start))
        .lte('date', _fmtDate(end))
        .order('date', ascending: false);

    return (rows as List<dynamic>)
        .map(
          (r) => StudentAttendanceRecord.fromJson(r as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<List<LeaveRequestItem>> fetchLeaveRequests() async {
    final rows = await _client
        .from('leave_requests')
        .select(
          'id, student_id, from_date, to_date, reason, status, review_note, '
          'students(first_name, last_name), '
          'sections(name, classes(name))',
        )
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((r) => LeaveRequestItem.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> submitLeaveRequest({
    required String studentId,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    await _client.rpc<String>(
      'submit_leave_request',
      params: {
        'p_student_id': studentId,
        'p_from_date': _fmtDate(fromDate),
        'p_to_date': _fmtDate(toDate),
        'p_reason': reason.trim(),
      },
    );
  }

  @override
  Future<void> reviewLeaveRequest({
    required String leaveId,
    required LeaveRequestStatus status,
    String? note,
  }) async {
    await _client.rpc<void>(
      'review_leave_request',
      params: {
        'p_leave_id': leaveId,
        'p_status': status.dbValue,
        'p_note': note,
      },
    );
  }

  @override
  Future<List<DailySectionSummary>> fetchDailySummary(DateTime date) async {
    final rows = await _client.rpc<List<dynamic>>(
      'get_daily_attendance_summary',
      params: {'p_date': _fmtDate(date)},
    );
    return rows
        .map((r) => DailySectionSummary.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LowAttendanceStudent>> fetchLowAttendanceStudents({
    double threshold = 75,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'get_low_attendance_students',
      params: {'p_threshold': threshold},
    );
    return rows
        .map((r) => LowAttendanceStudent.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AttendanceDashboardStats> fetchDashboardStats(DateTime date) async {
    final data = await _client.rpc<Map<String, dynamic>>(
      'get_attendance_dashboard_stats',
      params: {'p_date': _fmtDate(date)},
    );
    return AttendanceDashboardStats.fromJson(data);
  }
}
