import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/status_chip.dart';
import '../data/fee_model.dart';

class FeesNotifier extends Notifier<List<StudentFeeDue>> {
  @override
  List<StudentFeeDue> build() => const [
    StudentFeeDue(
      id: 'fee-1',
      studentName: 'Aarav Sharma',
      classSection: 'Class 6-A',
      feeHead: 'Term 2 Tuition',
      dueAmount: 8500,
      dueDate: '30 Nov 2026',
      status: StatusType.pending,
    ),
    StudentFeeDue(
      id: 'fee-2',
      studentName: 'Meera Nair',
      classSection: 'Class 8-A',
      feeHead: 'Tuition + Lab Fee',
      dueAmount: 4500,
      dueDate: '25 Nov 2026',
      status: StatusType.partial,
    ),
    StudentFeeDue(
      id: 'fee-3',
      studentName: 'Kabir Patel',
      classSection: 'Class 8-A',
      feeHead: 'Term 1 Tuition',
      dueAmount: 14200,
      dueDate: '10 Nov 2026',
      status: StatusType.overdue,
    ),
    StudentFeeDue(
      id: 'fee-4',
      studentName: 'Rohan Verma',
      classSection: 'Class 9-A',
      feeHead: 'Term 2 Tuition',
      dueAmount: 0,
      dueDate: 'Paid',
      status: StatusType.paid,
    ),
  ];

  void recordPayment({
    required String feeId,
    required int amountPaid,
  }) {
    state = [
      for (final item in state)
        if (item.id == feeId)
          item.copyWith(
            dueAmount: (item.dueAmount - amountPaid).clamp(0, item.dueAmount),
            status: (item.dueAmount - amountPaid) <= 0
                ? StatusType.paid
                : StatusType.partial,
          )
        else
          item,
    ];
  }
}

final feesDuesProvider = NotifierProvider<FeesNotifier, List<StudentFeeDue>>(
  FeesNotifier.new,
);
