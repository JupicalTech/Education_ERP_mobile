/// Matches only the fields shown in the parent portal table:
/// Name | Standard | Division | Academic Year
class StudentModel {
  final int id;
  final String name;
  final String? standardName;
  final String? divisionName;
  final String? academicYear;

  //constructor

  const StudentModel({
    required this.id,
    required this.name,
    this.standardName,
    this.divisionName,
    this.academicYear,
  });

  static String? _m2oName(dynamic val) {
    if (val is List && val.length > 1) return val[1] as String?;
    return null;
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id:           json['id'] as int,
      name:         json['name'] as String? ?? '',
      standardName: _m2oName(json['standard']),
      divisionName: _m2oName(json['div']),
      academicYear: _m2oName(json['curr_year']),
    );
  }
}