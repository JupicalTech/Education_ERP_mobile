import '../../../core/widgets/status_chip.dart';

/// Mirrors PostgreSQL `fee_payment_mode` enum.
enum FeePaymentMode {
  cash('cash', 'Cash'),
  upi('upi', 'UPI'),
  cheque('cheque', 'Cheque'),
  bankTransfer('bank_transfer', 'Bank Transfer'),
  online('online', 'Online');

  const FeePaymentMode(this.dbValue, this.label);
  final String dbValue;
  final String label;
}

class StudentFeeDue {
  const StudentFeeDue({
    required this.id,
    required this.studentName,
    required this.classSection,
    required this.feeHead,
    required this.dueAmount,
    required this.dueDate,
    required this.status,
  });

  final String id;
  final String studentName;
  final String classSection;
  final String feeHead;
  final int dueAmount;
  final String dueDate;
  final StatusType status;

  StudentFeeDue copyWith({int? dueAmount, StatusType? status}) {
    return StudentFeeDue(
      id: id,
      studentName: studentName,
      classSection: classSection,
      feeHead: feeHead,
      dueAmount: dueAmount ?? this.dueAmount,
      dueDate: dueDate,
      status: status ?? this.status,
    );
  }
}
