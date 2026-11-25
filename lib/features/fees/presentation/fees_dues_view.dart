import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/fee_model.dart';
import '../providers/fees_providers.dart';

class FeesDuesView extends ConsumerWidget {
  const FeesDuesView({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dues = ref.watch(feesDuesProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SectionHeader(title: 'Student Fee Dues'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dues.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final item = dues[index];
              final canCollect = !readOnly && item.dueAmount > 0;
              return ListTile(
                onTap: canCollect
                    ? () => showCollectFeeSheet(context, ref, initialFee: item)
                    : null,
                title: Text(item.studentName, style: textTheme.titleSmall),
                subtitle: Text(
                  '${item.classSection} • ${item.feeHead} • ${item.dueDate}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.dueAmount}',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    StatusChip(status: item.status),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<void> showCollectFeeSheet(
  BuildContext context,
  WidgetRef ref, {
  StudentFeeDue? initialFee,
}) async {
  final dues = ref
      .read(feesDuesProvider)
      .where((d) => d.dueAmount > 0)
      .toList();
  if (dues.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No pending dues to collect')),
    );
    return;
  }

  StudentFeeDue selected = initialFee ?? dues.first;
  FeePaymentMode mode = FeePaymentMode.upi;
  final amountCtrl = TextEditingController(text: '${selected.dueAmount}');
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Collect Fee',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<StudentFeeDue>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Student'),
                items: dues
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text('${d.studentName} (₹${d.dueAmount})'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() {
                      selected = val;
                      amountCtrl.text = '${val.dueAmount}';
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: amountCtrl,
                label: 'Amount (₹)',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final parsed = int.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<FeePaymentMode>(
                initialValue: mode,
                decoration: const InputDecoration(labelText: 'Payment Mode'),
                items: FeePaymentMode.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => mode = val);
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Record Payment',
                icon: Icons.check_circle_outline,
                fullWidth: true,
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final amount = int.parse(amountCtrl.text.trim());
                  ref
                      .read(feesDuesProvider.notifier)
                      .recordPayment(feeId: selected.id, amountPaid: amount);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Recorded ₹$amount (${mode.label}) for ${selected.studentName}',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
