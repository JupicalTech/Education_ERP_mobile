import '../../../core/widgets/status_chip.dart';

class Student {
  const Student({
    required this.id,
    required this.admissionNo,
    required this.firstName,
    required this.lastName,
    required this.className,
    required this.sectionName,
    required this.rollNo,
    required this.guardianName,
    required this.guardianPhone,
    required this.attendancePercent,
    required this.feeStatus,
  });

  final String id;
  final String admissionNo;
  final String firstName;
  final String lastName;
  final String className;
  final String sectionName;
  final int rollNo;
  final String guardianName;
  final String guardianPhone;
  final String attendancePercent;
  final StatusType feeStatus;

  String get fullName => '$firstName $lastName'.trim();
  String get classSection => '$className-$sectionName';
}
