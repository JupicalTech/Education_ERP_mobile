import '../../../core/widgets/status_chip.dart';

/// Mirrors PostgreSQL `attendance_status` enum.
enum AttendanceStatus {
  present('present', 'Present', StatusType.present),
  absent('absent', 'Absent', StatusType.absent),
  late('late', 'Late', StatusType.late),
  halfDay('half_day', 'Half Day', StatusType.halfDay),
  leave('leave', 'Leave', StatusType.info);

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

enum LeaveRequestStatus {
  pending('pending', 'Pending', StatusType.pending),
  approved('approved', 'Approved', StatusType.present),
  rejected('rejected', 'Rejected', StatusType.absent);

  const LeaveRequestStatus(this.dbValue, this.label, this.chipType);

  final String dbValue;
  final String label;
  final StatusType chipType;

  static LeaveRequestStatus fromString(String? value) {
    return LeaveRequestStatus.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => LeaveRequestStatus.pending,
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

  Map<String, dynamic> toExceptionJson() => {
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

class LeaveRequestItem {
  const LeaveRequestItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classSection,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    this.reviewNote,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String classSection;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final LeaveRequestStatus status;
  final String? reviewNote;

  factory LeaveRequestItem.fromJson(Map<String, dynamic> json) {
    final student = (json['students'] as Map<String, dynamic>?) ?? const {};
    final section = (json['sections'] as Map<String, dynamic>?) ?? const {};
    final cls = (section['classes'] as Map<String, dynamic>?) ?? const {};
    final first = (student['first_name'] as String?) ?? '';
    final last = (student['last_name'] as String?) ?? '';
    final className = (cls['name'] as String?) ?? '';
    final sectionName = (section['name'] as String?) ?? '';

    return LeaveRequestItem(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentName: '$first $last'.trim(),
      classSection: className.isNotEmpty ? '$className-$sectionName' : '',
      fromDate: DateTime.parse(json['from_date'] as String),
      toDate: DateTime.parse(json['to_date'] as String),
      reason: (json['reason'] as String?) ?? '',
      status: LeaveRequestStatus.fromString(json['status'] as String?),
      reviewNote: json['review_note'] as String?,
    );
  }
}

class MyStudentSummary {
  const MyStudentSummary({
    required this.studentId,
    required this.admissionNumber,
    required this.studentName,
    required this.classSection,
  });

  final String studentId;
  final String admissionNumber;
  final String studentName;
  final String classSection;

  factory MyStudentSummary.fromJson(Map<String, dynamic> json) {
    final first = (json['first_name'] as String?) ?? '';
    final last = (json['last_name'] as String?) ?? '';
    final enrollments = (json['student_enrollments'] as List<dynamic>?) ?? [];
    final enrollment = enrollments.isNotEmpty
        ? enrollments.first as Map<String, dynamic>
        : const <String, dynamic>{};
    final className =
        ((enrollment['classes'] as Map<String, dynamic>?)?['name']
            as String?) ??
        '';
    final sectionName =
        ((enrollment['sections'] as Map<String, dynamic>?)?['name']
            as String?) ??
        '';

    return MyStudentSummary(
      studentId: json['id'] as String,
      admissionNumber: (json['admission_number'] as String?) ?? '',
      studentName: '$first $last'.trim(),
      classSection: className.isNotEmpty ? '$className-$sectionName' : '',
    );
  }
}

class StudentAttendanceRecord {
  const StudentAttendanceRecord({required this.date, required this.status});

  final DateTime date;
  final AttendanceStatus status;

  factory StudentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceRecord(
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatus.fromString(json['status'] as String?),
    );
  }
}

class MonthlyAttendanceSummary {
  const MonthlyAttendanceSummary({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.halfDayDays,
    required this.leaveDays,
    required this.percentage,
  });

  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int halfDayDays;
  final int leaveDays;
  final double percentage;

  factory MonthlyAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceSummary(
      totalDays: (json['total_days'] as num?)?.toInt() ?? 0,
      presentDays: (json['present_days'] as num?)?.toInt() ?? 0,
      absentDays: (json['absent_days'] as num?)?.toInt() ?? 0,
      lateDays: (json['late_days'] as num?)?.toInt() ?? 0,
      halfDayDays: (json['half_day_days'] as num?)?.toInt() ?? 0,
      leaveDays: (json['leave_days'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

class DailySectionSummary {
  const DailySectionSummary({
    required this.sectionId,
    required this.sectionLabel,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.halfDayCount,
    required this.leaveCount,
    required this.isMarked,
  });

  final String sectionId;
  final String sectionLabel;
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int halfDayCount;
  final int leaveCount;
  final bool isMarked;

  factory DailySectionSummary.fromJson(Map<String, dynamic> json) {
    return DailySectionSummary(
      sectionId: json['section_id'] as String,
      sectionLabel: (json['section_label'] as String?) ?? '',
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      presentCount: (json['present_count'] as num?)?.toInt() ?? 0,
      absentCount: (json['absent_count'] as num?)?.toInt() ?? 0,
      lateCount: (json['late_count'] as num?)?.toInt() ?? 0,
      halfDayCount: (json['half_day_days'] as num?)?.toInt() ??
          (json['half_day_count'] as num?)?.toInt() ??
          0,
      leaveCount: (json['leave_count'] as num?)?.toInt() ?? 0,
      isMarked: (json['is_marked'] as bool?) ?? false,
    );
  }
}

class LowAttendanceStudent {
  const LowAttendanceStudent({
    required this.studentId,
    required this.admissionNumber,
    required this.studentName,
    required this.classSection,
    required this.markedDays,
    required this.attendedDays,
    required this.percentage,
  });

  final String studentId;
  final String admissionNumber;
  final String studentName;
  final String classSection;
  final int markedDays;
  final double attendedDays;
  final double percentage;

  factory LowAttendanceStudent.fromJson(Map<String, dynamic> json) {
    return LowAttendanceStudent(
      studentId: json['student_id'] as String,
      admissionNumber: (json['admission_number'] as String?) ?? '',
      studentName: (json['student_name'] as String?) ?? '',
      classSection: (json['class_section'] as String?) ?? '',
      markedDays: (json['marked_days'] as num?)?.toInt() ?? 0,
      attendedDays: (json['attended_days'] as num?)?.toDouble() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AttendanceDashboardStats {
  const AttendanceDashboardStats({
    required this.totalSections,
    required this.markedSections,
    required this.pendingSections,
    required this.totalMarked,
    required this.attendancePercent,
  });

  final int totalSections;
  final int markedSections;
  final int pendingSections;
  final int totalMarked;
  final double attendancePercent;

  factory AttendanceDashboardStats.fromJson(Map<String, dynamic> json) {
    return AttendanceDashboardStats(
      totalSections: (json['total_sections'] as num?)?.toInt() ?? 0,
      markedSections: (json['marked_sections'] as num?)?.toInt() ?? 0,
      pendingSections: (json['pending_sections'] as num?)?.toInt() ?? 0,
      totalMarked: (json['total_marked'] as num?)?.toInt() ?? 0,
      attendancePercent:
          (json['attendance_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
