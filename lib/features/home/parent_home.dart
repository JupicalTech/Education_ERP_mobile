import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../attendance/presentation/my_attendance_view.dart';
import 'providers/home_providers.dart';

class ParentHome extends ConsumerWidget {
  const ParentHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(parentChildrenProvider);
    final selectedIndex = ref.watch(selectedChildIndexProvider);
    final child = children[selectedIndex.clamp(0, children.length - 1)];
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ResponsiveScaffold(
      title: 'Parent Portal',
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
          children: [
            const SectionHeader(title: 'Select Child'),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(children.length, (index) {
                  final item = children[index];
                  final isSelected = index == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(item.name),
                      onSelected: (_) => ref
                          .read(selectedChildIndexProvider.notifier)
                          .select(index),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_outline,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child.name, style: textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          child.classLabel,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: child.todayStatus),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.event_available_outlined,
                    value: child.attendancePercent,
                    label: 'Attendance Rate',
                    tone: StatTone.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    value: child.feeDueAmount,
                    label: child.feeDueDate,
                    tone: child.feeStatus == StatusType.paid
                        ? StatTone.success
                        : StatTone.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fee Status', style: textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${child.feeDueAmount} • ${child.feeDueDate}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: child.feeStatus),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Latest Notice'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          child.latestNotice.title,
                          style: textTheme.titleSmall,
                        ),
                      ),
                      StatusChip(
                        status: StatusType.info,
                        label: child.latestNotice.dateLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(child.latestNotice.subtitle),
                ],
              ),
            ),
          ],
        ),
        const MyAttendanceView(isParent: true),
        const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Fee Invoices & Receipts',
          subtitle: 'Online fee payments and PDF receipts will appear here.',
        ),
      ],
    );
  }
}
