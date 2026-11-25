import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../admissions/presentation/admissions_view.dart';
import '../admissions/presentation/new_enquiry_screen.dart';
import '../auth/providers/auth_providers.dart';
import '../fees/presentation/fees_dues_view.dart';
import '../students/presentation/students_list_view.dart';
import 'data/home_dummy_data.dart';
import 'providers/home_providers.dart';

class PrincipalHome extends ConsumerWidget {
  const PrincipalHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(principalDashboardProvider);

    return ResponsiveScaffold(
      title: 'Principal Dashboard',
      destinations: const [
        NavDestination(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
        ),
        NavDestination(
          label: 'Admissions',
          icon: Icons.assignment_ind_outlined,
          selectedIcon: Icons.assignment_ind_rounded,
        ),
        NavDestination(
          label: 'Students',
          icon: Icons.people_outline,
          selectedIcon: Icons.people_rounded,
        ),
        NavDestination(
          label: 'Fees',
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet_rounded,
        ),
        NavDestination(
          label: 'Notices',
          icon: Icons.campaign_outlined,
          selectedIcon: Icons.campaign_rounded,
        ),
      ],
      bodies: [
        _OverviewTab(data: data),
        const AdmissionsView(),
        const StudentsListView(),
        const FeesDuesView(readOnly: true),
        _NoticesTab(data: data),
      ],
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.data});

  final PrincipalDashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppSpacing.desktopBreakpoint;

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WelcomeBanner(
          greeting: 'Good morning, ${profile?.fullName ?? 'Principal'}!',
          subtitle:
              'Attendance is ${data.todayAttendance} today with ${data.pendingDues} in pending fee dues.',
          actionLabel: 'New Enquiry',
          actionIcon: Icons.add,
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NewEnquiryScreen()),
          ),
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
                icon: Icons.groups_outlined,
                value: data.totalStudents,
                label: 'Total Students',
                subtitle: 'Across 12 classes',
                tone: StatTone.primary,
              ),
              StatCard(
                icon: Icons.fact_check_outlined,
                value: data.todayAttendance,
                label: "Today's Attendance",
                subtitle: 'Marked by 9:30 AM',
                tone: StatTone.success,
              ),
              StatCard(
                icon: Icons.payments_outlined,
                value: data.feesCollected,
                label: 'Fees Collected',
                subtitle: 'This month',
                tone: StatTone.accent,
              ),
              StatCard(
                icon: Icons.pending_actions_outlined,
                value: data.pendingDues,
                label: 'Pending Dues',
                subtitle: 'Requires follow-up',
                tone: StatTone.warning,
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
        SectionHeader(
          title: 'School Notices',
          actionLabel: 'New Notice',
          onAction: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notice composer coming soon')),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.notices.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final notice = data.notices[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.campaign_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(notice.title, style: textTheme.titleSmall),
                subtitle: Text(notice.subtitle),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      notice.dateLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    StatusChip(
                      status: StatusType.info,
                      label: notice.audience,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );

    final sidePanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Upcoming & Reminders'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.event_outlined, color: colorScheme.primary),
                ),
                title: Text('Parent-Teacher Meeting', style: textTheme.titleSmall),
                subtitle: const Text('Saturday • 09:30 AM – 01:30 PM'),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.assignment_ind_outlined,
                    color: colorScheme.secondary,
                  ),
                ),
                title: Text('3 Active Admission Leads', style: textTheme.titleSmall),
                subtitle: const Text('1 ready for approval'),
              ),
            ],
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
                  Expanded(flex: 7, child: mainContent),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(flex: 3, child: sidePanel),
                ],
              ),
            ]
          : [
              mainContent,
              const SizedBox(height: AppSpacing.xl),
              sidePanel,
            ],
    );
  }
}

class _NoticesTab extends StatelessWidget {
  const _NoticesTab({required this.data});

  final PrincipalDashboardData data;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: data.notices.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final notice = data.notices[index];
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notice.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StatusChip(status: StatusType.info, label: notice.audience),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(notice.subtitle),
              const SizedBox(height: AppSpacing.sm),
              Text(
                notice.dateLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
