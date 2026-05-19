class FeesModel {
  final int id;
  final String receiptNumber;
  final String? studentName;
  final String? year;
  final String state;

  const FeesModel({
    required this.id,
    required this.receiptNumber,
    this.studentName,
    this.year,
    required this.state,
  });

  // Many2one fields come as [id, name] from Odoo
  static String? _m2oName(dynamic val) {
    if (val is List && val.length > 1) return val[1] as String?;
    if (val is String) return val;
    return null;
  }

  factory FeesModel.fromJson(Map<String, dynamic> json) {
    return FeesModel(
      id:            json['id'] as int,
      receiptNumber: json['name'] as String? ?? '',
      studentName:   _m2oName(json['student']),
      year:          _m2oName(json['year']),
      state:         json['state'] as String? ?? '',
    );
  }
}