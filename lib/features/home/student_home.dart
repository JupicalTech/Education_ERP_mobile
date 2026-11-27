import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../attendance/presentation/my_attendance_view.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Student Portal',
      destinations: const [
        NavDestination(
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        NavDestination(
          label: 'Attendance',
          icon: Icons.event_available_outlined,
          selectedIcon: Icons.event_available_rounded,
        ),
        NavDestination(
          label: 'Fees',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
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
                    icon: Icons.event_available_outlined,
                    value: '95%',
                    label: 'My Attendance',
                    tone: StatTone.success,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    icon: Icons.receipt_long_outlined,
                    value: 'Paid',
                    label: 'Term 1 Fee',
                    tone: StatTone.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Recent Notice'),
            SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Annual Science Exhibition'),
                      ),
                      StatusChip(status: StatusType.info, label: 'Today'),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text('Project submissions close this Friday at 3:00 PM.'),
                ],
              ),
            ),
          ],
        ),
        const MyAttendanceView(isParent: false),
        const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'My Fees',
          subtitle: 'Fee invoices and receipts will appear here.',
        ),
      ],
    );
  }
}
