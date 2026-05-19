class ResultSubjectLine {
  final int id;
  final String subjectName;
  final String? subjectCode;
  final String? date;
  final double passMark;
  final double markScored;
  final double mark;
  final bool passOrFail;
  final String? grade;

  const ResultSubjectLine({
    required this.id,
    required this.subjectName,
    this.subjectCode,
    this.date,
    required this.passMark,
    required this.markScored,
    required this.mark,
    required this.passOrFail,
    this.grade,
  });

  static String? _m2oName(dynamic val) {
    if (val == false || val == null) return null;
    if (val is List && val.length > 1) return val[1] as String?;
    if (val is String) return val;
    return null;
  }

  factory ResultSubjectLine.fromJson(Map<String, dynamic> json) {
    final subject = json['subject_id'];
    String subjectName = '';
    if (subject is List && subject.length > 1) {
      subjectName = subject[1] as String? ?? '';
    }

    return ResultSubjectLine(
      id:          json['id'] as int,
      subjectName: subjectName,
      date:        (json['date'] == false) ? null : json['date'] as String?,
      passMark:    (json['pass_mark'] as num?)?.toDouble() ?? 0,
      markScored:  (json['mark_scored'] as num?)?.toDouble() ?? 0,
      mark:        (json['mark'] as num?)?.toDouble() ?? 0,
      passOrFail:  json['pass_or_fail'] as bool? ?? false,
      grade:       _m2oName(json['grade_id']),
    );
  }
}

class ResultModel {
  final int id;
  final String studentName;
  final String? examName;
  final String? standardName;
  final String? divisionName;
  final String? academicYear;
  final double totalMark;       // sum of all subject max marks
  final double totalMarkScored; // sum of all subject scored marks
  final double percentage;
  final bool passFailFull;
  final String? grade;          // ← ADDED: overall result grade (grade_id on student.result)
  final List<ResultSubjectLine> subjectLines;

  const ResultModel({
    required this.id,
    required this.studentName,
    this.examName,
    this.standardName,
    this.divisionName,
    this.academicYear,
    required this.totalMark,
    required this.totalMarkScored,
    required this.percentage,
    required this.passFailFull,
    this.grade,                  // ← ADDED
    this.subjectLines = const [],
  });

  // ── Convenience getters used by ResultReportScreen ────────────

  bool get isPassed => passFailFull;

  /// Sum of each subject's maximum marks (used for "X / total" display)
  double get subjectTotal =>
      subjectLines.fold(0.0, (sum, s) => sum + s.mark);

  static String? _m2oName(dynamic val) {
    if (val == false || val == null) return null;
    if (val is List && val.length > 1) return val[1] as String?;
    if (val is String) return val;
    return null;
  }

  factory ResultModel.fromJson(Map<String, dynamic> json,
      {List<ResultSubjectLine> subjectLines = const []}) {
    return ResultModel(
      id:              json['id'] as int,
      studentName:     _m2oName(json['student_id']) ?? '',
      examName:        _m2oName(json['exam_id']),
      standardName:    _m2oName(json['standard']),
      divisionName:    _m2oName(json['division']),
      academicYear:    _m2oName(json['academic_year']),
      totalMark:       (json['total_mark'] as num?)?.toDouble() ?? 0,
      totalMarkScored: (json['total_mark_scored'] as num?)?.toDouble() ?? 0,
      percentage:      (json['percentage'] as num?)?.toDouble() ?? 0,
      passFailFull:    json['pass_fail_full'] as bool? ?? false,
      grade:           _m2oName(json['grade_id']),  // ← ADDED
      subjectLines:    subjectLines,
    );
  }
}