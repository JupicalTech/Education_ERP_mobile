import '../../../core/widgets/status_chip.dart';

enum LeadStatus {
  newLead('new', 'New', StatusType.info),
  contacted('contacted', 'Contacted', StatusType.pending),
  visited('visited', 'Visited', StatusType.partial),
  admitted('admitted', 'Admitted', StatusType.paid);

  const LeadStatus(this.dbValue, this.label, this.chipType);

  final String dbValue;
  final String label;
  final StatusType chipType;
}

class AdmissionEnquiry {
  const AdmissionEnquiry({
    required this.id,
    required this.studentName,
    required this.applyingForClass,
    required this.guardianName,
    required this.guardianPhone,
    required this.previousSchool,
    required this.followUpNote,
    required this.status,
    required this.dateLabel,
    this.documentsAttached = false,
  });

  final String id;
  final String studentName;
  final String applyingForClass;
  final String guardianName;
  final String guardianPhone;
  final String previousSchool;
  final String followUpNote;
  final LeadStatus status;
  final String dateLabel;
  final bool documentsAttached;

  AdmissionEnquiry copyWith({
    LeadStatus? status,
    String? followUpNote,
    bool? documentsAttached,
  }) {
    return AdmissionEnquiry(
      id: id,
      studentName: studentName,
      applyingForClass: applyingForClass,
      guardianName: guardianName,
      guardianPhone: guardianPhone,
      previousSchool: previousSchool,
      followUpNote: followUpNote ?? this.followUpNote,
      status: status ?? this.status,
      dateLabel: dateLabel,
      documentsAttached: documentsAttached ?? this.documentsAttached,
    );
  }
}
