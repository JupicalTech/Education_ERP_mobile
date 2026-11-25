import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';

class SuperAdminHome extends StatelessWidget {
  const SuperAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Super Admin',
      destinations: const [
        NavDestination(
          label: 'Overview',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
        ),
        NavDestination(
          label: 'Institutes',
          icon: Icons.apartment_outlined,
          selectedIcon: Icons.apartment_rounded,
        ),
        NavDestination(
          label: 'Settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_rounded,
        ),
      ],
      bodies: [
        ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.apartment_outlined,
                    value: '4',
                    label: 'Active Institutes',
                    tone: StatTone.primary,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    icon: Icons.verified_user_outlined,
                    value: '186',
                    label: 'Staff Accounts',
                    tone: StatTone.success,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'System Status'),
            SizedBox(height: AppSpacing.sm),
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('V1 Multi-Tenant Setup'),
                subtitle: Text('Ready for Supabase migration & onboarding.'),
                trailing: StatusChip(status: StatusType.info, label: 'Ready'),
              ),
            ),
          ],
        ),
        const EmptyState(
          icon: Icons.apartment_outlined,
          title: 'Institutes',
          subtitle: 'School onboarding and tenant management will appear here.',
        ),
        const EmptyState(
          icon: Icons.settings_outlined,
          title: 'System Settings',
          subtitle: 'Global configuration and roles will appear here.',
        ),
      ],
    );
  }
}
