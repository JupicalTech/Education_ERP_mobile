import 'package:school_attendance/core/models/attendance_model.dart';
import 'package:school_attendance/core/models/exam_model.dart';
import 'package:school_attendance/core/models/fees_model.dart';
import 'package:school_attendance/core/models/meeting_model.dart';
import 'package:school_attendance/core/models/result_model.dart';

import '../api/odoo_client.dart';
import '../models/student_model.dart';
import '../utils/logger.dart';

class ParentService {
  final OdooClient _client;
  ParentService(this._client);

  Future<List<StudentModel>> fetchMyChildren(int parentPartnerId) async {
    AppLogger.i('fetchMyChildren — parentPartnerId: $parentPartnerId');
    if (parentPartnerId == 0) {
      AppLogger.i('ERROR: parentPartnerId is 0, aborting');
      return [];
    }

    final parentRecord = await _client.callKw(
      model: 'res.partner',
      method: 'read',
      args: [[parentPartnerId], ['id', 'name', 'student_ids']],
    );
    AppLogger.i('parent record → $parentRecord');

    final studentIds = List<int>.from(
      (parentRecord[0]['student_ids'] as List? ?? []),
    );
    AppLogger.i('student IDs → $studentIds');
    if (studentIds.isEmpty) return [];

    final students = await _client.callKw(
      model: 'res.partner',
      method: 'read',
      args: [studentIds, ['id', 'name', 'standard', 'div', 'curr_year']],
    );
    AppLogger.i('students detail → $students');

    return (students as List)
        .map((s) => StudentModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<List<FeesModel>> fetchFees(List<int> studentIds) async {
    AppLogger.i('fetchFees — studentIds: $studentIds');
    if (studentIds.isEmpty) return [];

    final result = await _client.callKw(
      model: 'fees.fees',
      method: 'search_read',
      args: [
        [['student', 'in', studentIds]],
      ],
      fields: ['id', 'name', 'student', 'year', 'state'],
      orderBy: 'id desc',
    );

    AppLogger.i('fees result → $result');
    return (result as List)
        .map((f) => FeesModel.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExamModel>> fetchExams(List<int> studentIds) async {
    AppLogger.i('fetchExams — studentIds: $studentIds');
    if (studentIds.isEmpty) return [];

    final result = await _client.callKw(
      model: 'student.exam',
      method: 'search_read',
      args: [
        [['student_ids', 'in', studentIds]],
      ],
      fields: ['id', 'name', 'start_date', 'end_date', 'state'],
      orderBy: 'start_date desc',
    );

    AppLogger.i('exams result → $result');
    return (result as List)
        .map((e) => ExamModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ResultModel>> fetchResults(List<int> studentIds) async {
    AppLogger.i('fetchResults — studentIds: $studentIds');
    if (studentIds.isEmpty) return [];

    final results = await _client.callKw(
      model: 'student.result',
      method: 'search_read',
      args: [
        [['student_id', 'in', studentIds]],
      ],
      fields: [
        'id', 'student_id', 'exam_id', 'standard',
        'division', 'academic_year', 'total_mark',
        'total_mark_scored', 'percentage', 'pass_fail_full',
      ],
      orderBy: 'id desc',
    );

    AppLogger.i('results → $results');
    return (results as List)
        .map((r) => ResultModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<ResultModel> fetchResultDetail(int resultId) async {
    AppLogger.i('fetchResultDetail — resultId: $resultId');

    final results = await _client.callKw(
      model: 'student.result',
      method: 'read',
      args: [[resultId], [
        'id', 'student_id', 'exam_id', 'standard',
        'division', 'academic_year', 'total_mark',
        'total_mark_scored', 'percentage', 'pass_fail_full',
      ]],
    );

    final lines = await _client.callKw(
      model: 'result.subject.line',
      method: 'search_read',
      args: [
        [['result_id', '=', resultId]],
      ],
      fields: [
        'id', 'subject_id', 'date', 'pass_mark',
        'mark_scored', 'mark', 'pass_or_fail', 'grade_id',
      ],
    );

    AppLogger.i('result detail lines → $lines');

    final subjectLines = (lines as List)
        .map((l) => ResultSubjectLine.fromJson(l as Map<String, dynamic>))
        .toList();

    return ResultModel.fromJson(
      (results as List)[0] as Map<String, dynamic>,
      subjectLines: subjectLines,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Attendance
  // ─────────────────────────────────────────────────────────────

  Future<List<AttendanceModel>> fetchAttendance(List<int> studentIds) async {
    AppLogger.i('fetchAttendance — studentIds: $studentIds');
    if (studentIds.isEmpty) return [];

    final rawLines = await _client.callKw(
      model: 'attendance.line',
      method: 'search_read',
      args: [
        [['student_id', 'in', studentIds]],
      ],
      fields: [
        'id', 'attendance_id', 'student_id', 'name',
        'roll_no', 'present', 'late',
        'absence_reason', 'absence_noreason', 'withdraw',
      ],
      orderBy: 'id desc',
    );

    AppLogger.i('attendance lines → $rawLines');
    if ((rawLines as List).isEmpty) return [];

    final sessionIds = rawLines
        .map((l) {
          final aid = l['attendance_id'];
          if (aid is List && aid.isNotEmpty) return aid[0] as int;
          return null;
        })
        .whereType<int>()
        .toSet()
        .toList();

    AppLogger.i('attendance session IDs → $sessionIds');

    final rawSessions = await _client.callKw(
      model: 'attendance.attendance',
      method: 'read',
      args: [sessionIds, [
        'id', 'date', 'faculty_id',
        'standard_id', 'division_id', 'subject_id',
      ]],
    );

    AppLogger.i('attendance sessions → $rawSessions');

    final allSubjectIds = <int>{};
    for (final s in (rawSessions as List)) {
      final subjectField = s['subject_id'];
      if (subjectField is List) {
        for (final v in subjectField) {
          if (v is int) allSubjectIds.add(v);
        }
      }
    }

    final Map<int, String> subjectNames = {};
    if (allSubjectIds.isNotEmpty) {
      final rawSubjects = await _client.callKw(
        model: 'student.subject',
        method: 'read',
        args: [allSubjectIds.toList(), ['id', 'name']],
      );
      for (final sub in (rawSubjects as List)) {
        subjectNames[sub['id'] as int] = sub['name'] as String;
      }
    }
    AppLogger.i('subject names → $subjectNames');

    final Map<int, List<AttendanceLine>> linesBySession = {};
    for (final raw in rawLines) {
      final line = AttendanceLine.fromJson(raw as Map<String, dynamic>);
      final sid = line.attendanceId;
      if (sid != null) {
        linesBySession.putIfAbsent(sid, () => []).add(line);
      }
    }

    return (rawSessions).map<AttendanceModel>((s) {
      final session = Map<String, dynamic>.from(s as Map);
      final sid = session['id'] as int;

      final rawSubjectIds = session['subject_id'];
      if (rawSubjectIds is List) {
        session['subject_id'] = rawSubjectIds
            .whereType<int>()
            .map((id) => [id, subjectNames[id] ?? ''])
            .toList();
      }

      return AttendanceModel.fromJson(
        session,
        lines: linesBySession[sid] ?? [],
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ─────────────────────────────────────────────────────────────
  // Meetings
  // ─────────────────────────────────────────────────────────────

  /// Fetches all meetings where parent_id = [parentPartnerId]
  Future<List<MeetingModel>> fetchMeetings(int parentPartnerId) async {
    AppLogger.i('fetchMeetings — parentPartnerId: $parentPartnerId');
    if (parentPartnerId == 0) return [];

    final result = await _client.callKw(
      model: 'student.meeting',
      method: 'search_read',
      args: [
        [['parent_id', '=', parentPartnerId]],
      ],
      fields: [
        'id', 'meeting_seq', 'topic',
        'student_id', 'faculty_id', 'standard',
        'start_date', 'end_date', 'state',
      ],
      orderBy: 'start_date desc',
    );

    AppLogger.i('meetings result → $result');
    return (result as List)
        .map((m) => MeetingModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }
}