import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../attendance/presentation/mark_attendance_view.dart';
import 'providers/home_providers.dart';

class TeacherHome extends ConsumerWidget {
  const TeacherHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(teacherClassesProvider);
    final pendingCount = classes.where((c) => !c.attendanceMarked).length;

    return ResponsiveScaffold(
      title: 'Teacher Home',
      destinations: const [
        NavDestination(
          label: 'Today',
          icon: Icons.today_outlined,
          selectedIcon: Icons.today_rounded,
        ),
        NavDestination(
          label: 'Attendance',
          icon: Icons.fact_check_outlined,
          selectedIcon: Icons.fact_check_rounded,
        ),
        NavDestination(
          label: 'Homework',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment_rounded,
        ),
      ],
      bodies: [
        ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.class_outlined,
                    value: '${classes.length}',
                    label: "Today's Classes",
                    tone: StatTone.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    icon: Icons.pending_actions_outlined,
                    value: '$pendingCount',
                    label: 'Attendance Pending',
                    tone: pendingCount > 0 ? StatTone.warning : StatTone.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Mark Attendance',
              icon: Icons.fact_check_outlined,
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Mark Attendance')),
                      body: const MarkAttendanceView(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: "Today's Classes"),
            const SizedBox(height: AppSpacing.sm),
            ...classes.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selected ${item.className}'),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.className} • ${item.subject}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${item.timeSlot} • ${item.studentCount} students',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      StatusChip(
                        status: item.attendanceMarked
                            ? StatusType.paid
                            : StatusType.pending,
                        label: item.attendanceMarked ? 'Marked' : 'Pending',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const MarkAttendanceView(),
        const EmptyState(
          icon: Icons.assignment_outlined,
          title: 'Homework & Assignments',
          subtitle: 'Post and review student submissions here.',
        ),
      ],
    );
  }
}
