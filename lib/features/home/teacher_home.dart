import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../attendance/presentation/leave_requests_view.dart';
import '../attendance/presentation/mark_attendance_view.dart';
import '../attendance/providers/attendance_providers.dart';
import '../auth/providers/auth_providers.dart';
import 'data/home_dummy_data.dart';
import 'providers/home_providers.dart';

class TeacherHome extends ConsumerWidget {
  const TeacherHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(teacherClassesProvider);

    return ResponsiveScaffold(
      title: 'Teacher Dashboard',
      destinations: const [
        NavDestination(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
        ),
        NavDestination(
          label: 'Attendance',
          icon: Icons.fact_check_outlined,
          selectedIcon: Icons.fact_check_rounded,
        ),
        NavDestination(
          label: 'Leave',
          icon: Icons.event_busy_outlined,
          selectedIcon: Icons.event_busy_rounded,
        ),
        NavDestination(
          label: 'Homework',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment_rounded,
        ),
      ],
      bodies: [
        _TeacherDashboardTab(classes: classes),
        const MarkAttendanceView(),
        const LeaveRequestsView(canReview: true),
        const EmptyState(
          icon: Icons.assignment_outlined,
          title: 'Homework & Assignments',
          subtitle: 'Post and review student submissions here.',
        ),
      ],
    );
  }
}

class _TeacherDashboardTab extends ConsumerWidget {
  const _TeacherDashboardTab({required this.classes});

  final List<TeacherClassItem> classes;

  void _openAttendance(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Mark Attendance')),
          body: const MarkAttendanceView(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final attStats = ref.watch(attendanceDashboardStatsProvider).value;
    final pendingCount = attStats?.pendingSections ?? 0;
    final totalStudents = classes.fold<int>(0, (sum, c) => sum + c.studentCount);
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppSpacing.desktopBreakpoint;

    final mainColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WelcomeBanner(
          greeting: 'Good morning, ${profile?.fullName ?? 'Teacher'}!',
          subtitle:
              'You have ${classes.length} classes today and $pendingCount attendance registers pending.',
          actionLabel: 'Mark Attendance',
          actionIcon: Icons.fact_check_outlined,
          onAction: () => _openAttendance(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 680 ? 4 : 2;
            const spacing = AppSpacing.md;
            final cardWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            final cards = [
              StatCard(
                icon: Icons.class_outlined,
                value: '${classes.length}',
                label: "Today's Classes",
                subtitle: classes.first.className,
                tone: StatTone.primary,
              ),
              StatCard(
                icon: Icons.groups_outlined,
                value: '$totalStudents',
                label: 'Student Count',
                subtitle: 'Across ${classes.length} sections',
                tone: StatTone.success,
              ),
              StatCard(
                icon: Icons.pending_actions_outlined,
                value: '$pendingCount',
                label: 'Pending Attendance',
                subtitle: 'Due today',
                tone: pendingCount > 0 ? StatTone.warning : StatTone.success,
              ),
              const StatCard(
                icon: Icons.assignment_turned_in_outlined,
                value: '12',
                label: 'Submissions',
                subtitle: 'Ready to review',
                tone: StatTone.accent,
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: cards
                  .map((c) => SizedBox(width: cardWidth, child: c))
                  .toList(),
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
              onTap: () => _openAttendance(context),
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
    );

    final scheduleSidebar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: "Today's Schedule"),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: classes.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final item = classes[index];
              return ListTile(
                title: Text(
                  '${item.className} • ${item.subject}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(item.timeSlot),
                trailing: index == 0
                    ? const StatusChip(status: StatusType.info, label: 'Now')
                    : null,
              );
            },
          ),
        ),
      ],
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: isDesktop
          ? [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: mainColumn),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(flex: 3, child: scheduleSidebar),
                ],
              ),
            ]
          : [
              mainColumn,
              const SizedBox(height: AppSpacing.xl),
              scheduleSidebar,
            ],
    );
  }
}
