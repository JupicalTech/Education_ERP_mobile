import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/academic_year_model.dart';
import '../providers/academic_years_providers.dart';

class AcademicYearsView extends ConsumerWidget {
  const AcademicYearsView({super.key});

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

  Future<void> _showYearDialog(
    BuildContext context,
    WidgetRef ref, {
    AcademicYear? existing,
    bool defaultToCurrent = false,
  }) async {
    final now = DateTime.now();
    // Default academic year: April to March
    final defaultStartYear = now.month >= 4 ? now.year : now.year - 1;
    var startDate = existing?.startDate ?? DateTime(defaultStartYear, 4, 1);
    var endDate = existing?.endDate ?? DateTime(defaultStartYear + 1, 3, 31);
    var isCurrent = existing?.isCurrent ?? defaultToCurrent;

    final defaultName =
        '$defaultStartYear-${(defaultStartYear + 1).toString().substring(2)}';
    final nameController = TextEditingController(
      text: existing?.name ?? defaultName,
    );
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Add Academic Year' : 'Edit Academic Year',
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: nameController,
                    label: 'Academic Year Name',
                    hint: 'e.g. 2026-27',
                    prefixIcon: Icons.calendar_month_outlined,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setDialogState(() => startDate = picked);
                            }
                          },
                          icon: const Icon(Icons.event_outlined, size: 18),
                          label: Text('Start: ${_fmtDate(startDate)}'),
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
                              initialDate: endDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2036),
                            );
                            if (picked != null) {
                              setDialogState(() => endDate = picked);
                            }
                          },
                          icon: const Icon(Icons.event_outlined, size: 18),
                          label: Text('End: ${_fmtDate(endDate)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Set as Current Year'),
                    value: isCurrent,
                    onChanged: (v) => setDialogState(() => isCurrent = v),
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
                if (!formKey.currentState!.validate()) return;
                if (!endDate.isAfter(startDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('End date must be after start date'),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(existing == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(academicYearsProvider.notifier).saveAcademicYear(
            id: existing?.id,
            name: nameController.text,
            startDate: startDate,
            endDate: endDate,
            isCurrent: isCurrent,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Could not save academic year: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(academicYearsProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return yearsAsync.when(
      loading: () => const LoadingView(message: 'Loading academic years...'),
      error: (e, _) => ErrorView(
        message: 'Could not load academic years: $e',
        onRetry: () => ref.invalidate(academicYearsProvider),
      ),
      data: (years) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Academic Years', style: textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        '${years.length} sessions configured',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Add Year',
                  icon: Icons.add,
                  onPressed: () => _showYearDialog(
                    context,
                    ref,
                    defaultToCurrent: years.isEmpty,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (years.isEmpty)
              EmptyState(
                icon: Icons.calendar_month_outlined,
                title: 'No academic years yet',
                subtitle:
                    'Add your current school session (e.g. 2026-27, April to March).',
                actionLabel: 'Add Academic Year',
                onAction: () =>
                    _showYearDialog(context, ref, defaultToCurrent: true),
              )
            else
              ...years.map(
                (year) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Text(year.name, style: textTheme.titleSmall),
                          if (year.isCurrent) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const StatusChip(
                              status: StatusType.present,
                              label: 'Current',
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${_fmtDate(year.startDate)} – ${_fmtDate(year.endDate)}',
                      ),
                      trailing: Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          if (!year.isCurrent)
                            TextButton(
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(academicYearsProvider.notifier)
                                      .setCurrent(year.id);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: colorScheme.error,
                                      content: Text('Failed: $e'),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Set Current'),
                            ),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showYearDialog(
                              context,
                              ref,
                              existing: year,
                            ),
                          ),
                        ],
                      ),
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
