import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/attendance_model.dart';
import '../providers/attendance_providers.dart';

class MarkAttendanceView extends ConsumerStatefulWidget {
  const MarkAttendanceView({super.key});

  @override
  ConsumerState<MarkAttendanceView> createState() => _MarkAttendanceViewState();
}

class _MarkAttendanceViewState extends ConsumerState<MarkAttendanceView> {
  bool _isSaving = false;

  String _formatDate(DateTime d) {
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

  Future<void> _pickDate(DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(attendanceDateProvider.notifier).setDate(picked);
    }
  }

  Future<void> _submit(
    AttendanceSection section,
    int presentCount,
    int absentCount,
    int lateCount,
  ) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(attendanceRosterProvider.notifier).submit();
      if (!mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            'Saved ${section.label} attendance: '
            '$presentCount present, $absentCount absent, $lateCount late',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text('Failed to save attendance: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(attendanceSectionsProvider);
    final activeSection = ref.watch(activeAttendanceSectionProvider);
    final selectedDate = ref.watch(attendanceDateProvider);
    final rosterAsync = ref.watch(attendanceRosterProvider);
    final textTheme = Theme.of(context).textTheme;

    return sectionsAsync.when(
      loading: () => const LoadingView(message: 'Loading sections...'),
      error: (e, _) => ErrorView(
        message: 'Could not load sections: $e',
        onRetry: () => ref.invalidate(attendanceSectionsProvider),
      ),
      data: (sections) {
        if (sections.isEmpty || activeSection == null) {
          return const EmptyState(
            icon: Icons.class_outlined,
            title: 'No sections assigned',
            subtitle: 'No classes or sections found for attendance.',
          );
        }

        final roster = rosterAsync.value ?? const [];
        final presentCount =
            roster.where((e) => e.status == AttendanceStatus.present).length;
        final absentCount =
            roster.where((e) => e.status == AttendanceStatus.absent).length;
        final lateCount =
            roster.where((e) => e.status == AttendanceStatus.late).length;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<AttendanceSection>(
                    initialValue: activeSection,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      prefixIcon: Icon(Icons.class_outlined),
                    ),
                    items: sections
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text(s.label)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(selectedAttendanceSectionProvider.notifier)
                            .select(value);
                      }
                    },
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(selectedDate),
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(_formatDate(selectedDate)),
                ),
                AppButton(
                  label: 'All Present',
                  variant: AppButtonVariant.tonal,
                  onPressed: roster.isEmpty
                      ? null
                      : () => ref
                            .read(attendanceRosterProvider.notifier)
                            .markAllPresent(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.check_circle_outline,
                    value: '$presentCount',
                    label: 'Present',
                    tone: StatTone.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    icon: Icons.cancel_outlined,
                    value: '$absentCount',
                    label: 'Absent',
                    tone: StatTone.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    icon: Icons.schedule_outlined,
                    value: '$lateCount',
                    label: 'Late',
                    tone: StatTone.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Roll Call'),
            const SizedBox(height: AppSpacing.sm),
            rosterAsync.when(
              loading: () => const LoadingView(message: 'Loading roster...'),
              error: (e, _) => ErrorView(
                message: 'Could not load roster: $e',
                onRetry: () => ref.invalidate(attendanceRosterProvider),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No students enrolled',
                    subtitle: 'No active students enrolled in this section.',
                  );
                }
                return Column(
                  children: [
                    ...entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.rollNo > 0
                                          ? 'Roll #${entry.rollNo} • ${entry.studentName}'
                                          : entry.studentName,
                                      style: textTheme.titleSmall,
                                    ),
                                  ),
                                  StatusChip(status: entry.status.chipType),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.xs,
                                children: AttendanceStatus.values.map((status) {
                                  final isSelected = entry.status == status;
                                  return ChoiceChip(
                                    selected: isSelected,
                                    label: Text(status.label),
                                    onSelected: (_) => ref
                                        .read(attendanceRosterProvider.notifier)
                                        .setStatus(entry.studentId, status),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Submit Attendance for ${activeSection.label}',
                      icon: Icons.save_outlined,
                      fullWidth: true,
                      isLoading: _isSaving,
                      onPressed: _isSaving
                          ? null
                          : () => _submit(
                              activeSection,
                              presentCount,
                              absentCount,
                              lateCount,
                            ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
