import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
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
          label: 'Overview',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
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
        const EmptyState(
          icon: Icons.people_outline,
          title: 'Student Directory',
          subtitle: 'Module 1 will connect this view to Supabase.',
        ),
        const EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Fee Reports',
          subtitle: 'Collection summaries and dues will appear here.',
        ),
        _NoticesTab(data: data),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.data});

  final PrincipalDashboardData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 680;
            final columns = isWide ? 4 : 2;
            final spacing = AppSpacing.md;
            final cardWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            final cards = [
              StatCard(
                icon: Icons.groups_outlined,
                value: data.totalStudents,
                label: 'Total Students',
                tone: StatTone.primary,
              ),
              StatCard(
                icon: Icons.fact_check_outlined,
                value: data.todayAttendance,
                label: "Today's Attendance",
                tone: StatTone.success,
              ),
              StatCard(
                icon: Icons.payments_outlined,
                value: data.feesCollected,
                label: 'Fees Collected',
                tone: StatTone.info,
              ),
              StatCard(
                icon: Icons.pending_actions_outlined,
                value: data.pendingDues,
                label: 'Pending Dues',
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
  }
}

class _NoticesTab extends StatelessWidget {
  const _NoticesTab({required this.data});

  final PrincipalDashboardData data;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
