import '../../../core/widgets/status_chip.dart';

/// Mirrors PostgreSQL `attendance_status` enum.
enum AttendanceStatus {
  present('present', 'Present', StatusType.present),
  absent('absent', 'Absent', StatusType.absent),
  late('late', 'Late', StatusType.late),
  halfDay('half_day', 'Half Day', StatusType.halfDay);

  const AttendanceStatus(this.dbValue, this.label, this.chipType);

  final String dbValue;
  final String label;
  final StatusType chipType;
}

class AttendanceRosterEntry {
  const AttendanceRosterEntry({
    required this.studentId,
    required this.rollNo,
    required this.studentName,
    required this.status,
  });

  final String studentId;
  final int rollNo;
  final String studentName;
  final AttendanceStatus status;

  AttendanceRosterEntry copyWith({AttendanceStatus? status}) {
    return AttendanceRosterEntry(
      studentId: studentId,
      rollNo: rollNo,
      studentName: studentName,
      status: status ?? this.status,
    );
  }
}
