class ExamModel {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String state;

  const ExamModel({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    required this.state,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id:        json['id'] as int,
      name:      json['name'] as String? ?? '',
      startDate: json['start_date'] as String?,
      endDate:   json['end_date'] as String?,
      state:     json['state'] as String? ?? '',
    );
  }
}