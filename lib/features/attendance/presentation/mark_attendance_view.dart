import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/attendance_model.dart';
import '../providers/attendance_providers.dart';

class MarkAttendanceView extends ConsumerWidget {
  const MarkAttendanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(attendanceSectionProvider);
    final roster = ref.watch(attendanceRosterProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final presentCount =
        roster.where((e) => e.status == AttendanceStatus.present).length;
    final absentCount =
        roster.where((e) => e.status == AttendanceStatus.absent).length;
    final lateCount =
        roster.where((e) => e.status == AttendanceStatus.late).length;

    const sections = ['Class 8-A', 'Class 9-B', 'Class 7-A'];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: section,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  prefixIcon: Icon(Icons.class_outlined),
                ),
                items: sections
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(attendanceSectionProvider.notifier).select(value);
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AppButton(
              label: 'All Present',
              variant: AppButtonVariant.tonal,
              onPressed: () =>
                  ref.read(attendanceRosterProvider.notifier).markAllPresent(),
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
        ...roster.map(
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
                          'Roll #${entry.rollNo} • ${entry.studentName}',
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
          label: 'Submit Attendance for $section',
          icon: Icons.save_outlined,
          fullWidth: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: colorScheme.primary,
                content: Text(
                  'Saved $section attendance: $presentCount present, $absentCount absent, $lateCount late',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
