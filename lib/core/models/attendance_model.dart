class AttendanceModel {
  final int id;
  final String date;
  final String? facultyName;
  final String? standardName;
  final String? divisionName;
  final List<String> subjects;
  final List<AttendanceLine> lines;

  const AttendanceModel({
    required this.id,
    required this.date,
    this.facultyName,
    this.standardName,
    this.divisionName,
    this.subjects = const [],
    this.lines = const [],
  });

  static String? _m2oName(dynamic val) {
    if (val is List && val.length > 1) return val[1] as String?;
    if (val is String) return val;
    return null;
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json,
      {List<AttendanceLine> lines = const []}) {
    // subject_id is Many2many → list of [id, name] pairs or just ids
    List<String> subjects = [];
    final rawSubjects = json['subject_id'];
    if (rawSubjects is List) {
      for (final s in rawSubjects) {
        if (s is List && s.length > 1) {
          subjects.add(s[1] as String);
        }
      }
    }

    return AttendanceModel(
      id: json['id'] as int,
      date: json['date'] as String? ?? '',
      facultyName: _m2oName(json['faculty_id']),
      standardName: _m2oName(json['standard_id']),
      divisionName: _m2oName(json['division_id']),
      subjects: subjects,
      lines: lines,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Attendance Line
// ─────────────────────────────────────────────────────────────

class AttendanceLine {
  final int id;
  final int? attendanceId;
  final String studentName;
  final int? studentId;
  final String? rollNo;
  final bool present;
  final bool late;
  final bool absenceReason;
  final bool absenceNoreason;
  final bool withdraw;

  const AttendanceLine({
    required this.id,
    this.attendanceId,
    required this.studentName,
    this.studentId,
    this.rollNo,
    required this.present,
    required this.late,
    required this.absenceReason,
    required this.absenceNoreason,
    required this.withdraw,
  });

  static String? _m2oName(dynamic val) {
    if (val is List && val.length > 1) return val[1] as String?;
    if (val is String) return val;
    return null;
  }

  static int? _m2oId(dynamic val) {
    if (val is List && val.isNotEmpty) return val[0] as int?;
    if (val is int) return val;
    return null;
  }

  factory AttendanceLine.fromJson(Map<String, dynamic> json) {
    return AttendanceLine(
      id: json['id'] as int,
      attendanceId: _m2oId(json['attendance_id']),
      studentName: _m2oName(json['student_id']) ?? json['name'] as String? ?? '—',
      studentId: _m2oId(json['student_id']),
      rollNo: json['roll_no'] != null && json['roll_no'] != false
          ? json['roll_no'].toString()
          : null,
      present: json['present'] as bool? ?? false,
      late: json['late'] as bool? ?? false,
      absenceReason: json['absence_reason'] as bool? ?? false,
      absenceNoreason: json['absence_noreason'] as bool? ?? false,
      withdraw: json['withdraw'] as bool? ?? false,
    );
  }

  /// Derived status label
  String get statusLabel {
    if (withdraw) return 'Withdrawn';
    if (absenceReason) return 'Absent (Reason)';
    if (absenceNoreason) return 'Absent (No Reason)';
    if (present && late) return 'Present (Late)';
    if (present) return 'Present';
    return 'Not Marked';
  }
}