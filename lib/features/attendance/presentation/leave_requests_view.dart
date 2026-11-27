import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/attendance_model.dart';
import '../providers/attendance_providers.dart';

class LeaveRequestsView extends ConsumerWidget {
  const LeaveRequestsView({
    super.key,
    this.canReview = false,
    this.allowApply = false,
  });

  final bool canReview;
  final bool allowApply;

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _showApplyDialog(BuildContext context, WidgetRef ref) async {
    final students = await ref.read(myAttendanceStudentsProvider.future);
    if (!context.mounted) return;
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No linked students found.')),
      );
      return;
    }

    var selectedStudentId = students.first.studentId;
    var fromDate = DateTime.now();
    var toDate = DateTime.now();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Apply for Leave'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedStudentId,
                    decoration: const InputDecoration(
                      labelText: 'Student',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: students
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.studentId,
                            child: Text(
                              s.classSection.isNotEmpty
                                  ? '${s.studentName} (${s.classSection})'
                                  : s.studentName,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedStudentId = v);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: fromDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 7),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 90),
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                fromDate = picked;
                                if (toDate.isBefore(fromDate)) {
                                  toDate = fromDate;
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.event_outlined, size: 18),
                          label: Text('From: ${_fmtDate(fromDate)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: toDate,
                              firstDate: fromDate,
                              lastDate: DateTime.now().add(
                                const Duration(days: 90),
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => toDate = picked);
                            }
                          },
                          icon: const Icon(Icons.event_outlined, size: 18),
                          label: Text('To: ${_fmtDate(toDate)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: reasonController,
                    label: 'Reason',
                    hint: 'e.g. Fever, Family function',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(leaveRequestsProvider.notifier).submit(
            studentId: selectedStudentId,
            fromDate: fromDate,
            toDate: toDate,
            reason: reasonController.text,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Could not submit leave request: $e'),
        ),
      );
    }
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    LeaveRequestItem item,
    LeaveRequestStatus status,
  ) async {
    try {
      await ref.read(leaveRequestsProvider.notifier).review(
            leaveId: item.id,
            status: status,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Could not update leave request: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leavesAsync = ref.watch(leaveRequestsProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return leavesAsync.when(
      loading: () => const LoadingView(message: 'Loading leave requests...'),
      error: (e, _) => ErrorView(
        message: 'Could not load leave requests: $e',
        onRetry: () => ref.invalidate(leaveRequestsProvider),
      ),
      data: (items) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Leave Requests', style: textTheme.titleLarge),
                ),
                if (allowApply)
                  AppButton(
                    label: 'Apply Leave',
                    icon: Icons.add,
                    onPressed: () => _showApplyDialog(context, ref),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No leave requests',
                subtitle: allowApply
                    ? 'Tap Apply Leave to request leave for your child.'
                    : 'No pending or past leave requests.',
                actionLabel: allowApply ? 'Apply Leave' : null,
                onAction:
                    allowApply ? () => _showApplyDialog(context, ref) : null,
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.classSection.isNotEmpty
                                    ? '${item.studentName} (${item.classSection})'
                                    : item.studentName,
                                style: textTheme.titleSmall,
                              ),
                            ),
                            StatusChip(
                              status: item.status.chipType,
                              label: item.status.label,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${_fmtDate(item.fromDate)} – ${_fmtDate(item.toDate)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(item.reason, style: textTheme.bodyMedium),
                        if (canReview &&
                            item.status == LeaveRequestStatus.pending) ...[
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => _review(
                                  context,
                                  ref,
                                  item,
                                  LeaveRequestStatus.rejected,
                                ),
                                child: const Text('Reject'),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              FilledButton(
                                onPressed: () => _review(
                                  context,
                                  ref,
                                  item,
                                  LeaveRequestStatus.approved,
                                ),
                                child: const Text('Approve'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
