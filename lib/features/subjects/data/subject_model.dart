class Subject {
  const Subject({
    required this.id,
    required this.name,
    this.code,
  });

  final String id;
  final String name;
  final String? code;

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      code: json['code'] as String?,
    );
  }
}

class TeacherOption {
  const TeacherOption({
    required this.profileId,
    required this.name,
    this.designation = '',
  });

  final String profileId;
  final String name;
  final String designation;

  factory TeacherOption.fromJson(Map<String, dynamic> json) {
    final first = (json['first_name'] as String?) ?? '';
    final last = (json['last_name'] as String?) ?? '';
    return TeacherOption(
      profileId: json['profile_id'] as String,
      name: '$first $last'.trim(),
      designation: (json['designation'] as String?) ?? '',
    );
  }
}

class SectionSubjectMapping {
  const SectionSubjectMapping({
    required this.id,
    required this.academicYearId,
    required this.sectionId,
    required this.subjectId,
    required this.teacherProfileId,
    required this.className,
    required this.sectionName,
    required this.subjectName,
    this.subjectCode,
    required this.teacherName,
  });

  final String id;
  final String academicYearId;
  final String sectionId;
  final String subjectId;
  final String teacherProfileId;
  final String className;
  final String sectionName;
  final String subjectName;
  final String? subjectCode;
  final String teacherName;

  String get classSection => '$className-$sectionName';

  factory SectionSubjectMapping.fromJson(Map<String, dynamic> json) {
    final section = (json['sections'] as Map<String, dynamic>?) ?? const {};
    final cls = (section['classes'] as Map<String, dynamic>?) ?? const {};
    final subject = (json['subjects'] as Map<String, dynamic>?) ?? const {};
    final profile = (json['profiles'] as Map<String, dynamic>?) ?? const {};
    final first = (profile['first_name'] as String?) ?? '';
    final last = (profile['last_name'] as String?) ?? '';

    return SectionSubjectMapping(
      id: json['id'] as String,
      academicYearId: json['academic_year_id'] as String,
      sectionId: json['section_id'] as String,
      subjectId: json['subject_id'] as String,
      teacherProfileId: json['teacher_id'] as String,
      className: (cls['name'] as String?) ?? '',
      sectionName: (section['name'] as String?) ?? '',
      subjectName: (subject['name'] as String?) ?? '',
      subjectCode: subject['code'] as String?,
      teacherName: '$first $last'.trim(),
    );
  }
}
