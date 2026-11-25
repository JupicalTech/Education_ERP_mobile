import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/attendance_model.dart';

class AttendanceSectionNotifier extends Notifier<String> {
  @override
  String build() => 'Class 8-A';

  void select(String section) => state = section;
}

final attendanceSectionProvider =
    NotifierProvider<AttendanceSectionNotifier, String>(
  AttendanceSectionNotifier.new,
);

class AttendanceRosterNotifier extends Notifier<List<AttendanceRosterEntry>> {
  @override
  List<AttendanceRosterEntry> build() {
    final section = ref.watch(attendanceSectionProvider);
    return _dummyRosterFor(section);
  }

  void setStatus(String studentId, AttendanceStatus status) {
    state = [
      for (final entry in state)
        if (entry.studentId == studentId)
          entry.copyWith(status: status)
        else
          entry,
    ];
  }

  void markAllPresent() {
    state = [
      for (final entry in state)
        entry.copyWith(status: AttendanceStatus.present),
    ];
  }

  static List<AttendanceRosterEntry> _dummyRosterFor(String section) {
    return [
      AttendanceRosterEntry(
        studentId: '$section-1',
        rollNo: 1,
        studentName: 'Aarav Sharma',
        status: AttendanceStatus.present,
      ),
      AttendanceRosterEntry(
        studentId: '$section-2',
        rollNo: 2,
        studentName: 'Diya Kulkarni',
        status: AttendanceStatus.present,
      ),
      AttendanceRosterEntry(
        studentId: '$section-3',
        rollNo: 3,
        studentName: 'Kabir Patel',
        status: AttendanceStatus.absent,
      ),
      AttendanceRosterEntry(
        studentId: '$section-4',
        rollNo: 4,
        studentName: 'Meera Nair',
        status: AttendanceStatus.late,
      ),
      AttendanceRosterEntry(
        studentId: '$section-5',
        rollNo: 5,
        studentName: 'Rohan Verma',
        status: AttendanceStatus.present,
      ),
    ];
  }
}

final attendanceRosterProvider =
    NotifierProvider<AttendanceRosterNotifier, List<AttendanceRosterEntry>>(
  AttendanceRosterNotifier.new,
);
