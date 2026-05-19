class MeetingModel {
  final int id;
  final String meetingSeq;
  final String? topic;
  final String? studentName;
  final String? facultyName;
  final String? standardName;
  final String? startDate;
  final String? endDate;
  final String state;

  const MeetingModel({
    required this.id,
    required this.meetingSeq,
    this.topic,
    this.studentName,
    this.facultyName,
    this.standardName,
    this.startDate,
    this.endDate,
    required this.state,
  });

  static String? _m2oName(dynamic val) {
    if (val is List && val.length > 1) return val[1] as String?;
    if (val is String) return val;
    return null;
  }

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id:           json['id'] as int,
      meetingSeq:   json['meeting_seq'] as String? ?? '',
      topic:        json['topic'] as String?,
      studentName:  _m2oName(json['student_id']),
      facultyName:  _m2oName(json['faculty_id']),
      standardName: _m2oName(json['standard']),
      startDate:    json['start_date'] as String?,
      endDate:      json['end_date'] as String?,
      state:        json['state'] as String? ?? 'draft',
    );
  }

  /// Human-readable state label
  String get stateLabel {
    switch (state) {
      case 'ongoing':    return 'Ongoing';
      case 'conducted':  return 'Conducted';
      case 'rescheduled': return 'Rescheduled';
      case 'cancel':     return 'Cancelled';
      case 'draft':
      default:           return 'New';
    }
  }
}