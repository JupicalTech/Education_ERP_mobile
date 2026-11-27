import 'package:supabase_flutter/supabase_flutter.dart';

import 'attendance_model.dart';

abstract interface class AttendanceRepository {
  Future<List<AttendanceSection>> fetchSections();
  Future<List<AttendanceRosterEntry>> fetchRoster({
    required String sectionId,
    required DateTime date,
  });
  Future<void> saveAttendance({
    required String sectionId,
    required DateTime date,
    required List<AttendanceRosterEntry> entries,
  });
}

class StubAttendanceRepository implements AttendanceRepository {
  @override
  Future<List<AttendanceSection>> fetchSections() async {
    return const [
      AttendanceSection(id: 'sec-8a', label: 'Class 8-A'),
      AttendanceSection(id: 'sec-9b', label: 'Class 9-B'),
      AttendanceSection(id: 'sec-7a', label: 'Class 7-A'),
    ];
  }

  @override
  Future<List<AttendanceRosterEntry>> fetchRoster({
    required String sectionId,
    required DateTime date,
  }) async {
    return [
      AttendanceRosterEntry(
        studentId: '$sectionId-1',
        rollNo: 1,
        studentName: 'Aarav Sharma',
        status: AttendanceStatus.present,
      ),
      AttendanceRosterEntry(
        studentId: '$sectionId-2',
        rollNo: 2,
        studentName: 'Diya Kulkarni',
        status: AttendanceStatus.present,
      ),
      AttendanceRosterEntry(
        studentId: '$sectionId-3',
        rollNo: 3,
        studentName: 'Kabir Patel',
        status: AttendanceStatus.absent,
      ),
      AttendanceRosterEntry(
        studentId: '$sectionId-4',
        rollNo: 4,
        studentName: 'Meera Nair',
        status: AttendanceStatus.late,
      ),
      AttendanceRosterEntry(
        studentId: '$sectionId-5',
        rollNo: 5,
        studentName: 'Rohan Verma',
        status: AttendanceStatus.present,
      ),
    ];
  }

  @override
  Future<void> saveAttendance({
    required String sectionId,
    required DateTime date,
    required List<AttendanceRosterEntry> entries,
  }) async {}
}

class SupabaseAttendanceRepository implements AttendanceRepository {
  SupabaseAttendanceRepository(this._client);

  final SupabaseClient _client;

  static String _formatDate(DateTime d) =>
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
      params: {
        'p_section_id': sectionId,
        'p_date': _formatDate(date),
      },
    );
    return rows
        .map((e) => AttendanceRosterEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveAttendance({
    required String sectionId,
    required DateTime date,
    required List<AttendanceRosterEntry> entries,
  }) async {
    await _client.rpc<int>(
      'save_section_attendance',
      params: {
        'p_section_id': sectionId,
        'p_date': _formatDate(date),
        'p_entries': entries.map((e) => e.toRpcJson()).toList(),
      },
    );
  }
}
