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

  static AttendanceStatus fromString(String? value) {
    return AttendanceStatus.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => AttendanceStatus.present,
    );
  }
}

class AttendanceSection {
  const AttendanceSection({
    required this.id,
    required this.label,
    this.className = '',
    this.sectionName = '',
  });

  final String id;
  final String label;
  final String className;
  final String sectionName;

  factory AttendanceSection.fromJson(Map<String, dynamic> json) {
    return AttendanceSection(
      id: json['id'] as String,
      label: (json['label'] as String?) ?? '',
      className: (json['class_name'] as String?) ?? '',
      sectionName: (json['section_name'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceSection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
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

  factory AttendanceRosterEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceRosterEntry(
      studentId: json['student_id'] as String,
      rollNo: (json['roll_number'] as int?) ?? 0,
      studentName: (json['student_name'] as String?) ?? '',
      status: AttendanceStatus.fromString(json['status'] as String?),
    );
  }

  Map<String, dynamic> toRpcJson() => {
    'student_id': studentId,
    'status': status.dbValue,
  };

  AttendanceRosterEntry copyWith({AttendanceStatus? status}) {
    return AttendanceRosterEntry(
      studentId: studentId,
      rollNo: rollNo,
      studentName: studentName,
      status: status ?? this.status,
    );
  }
}
