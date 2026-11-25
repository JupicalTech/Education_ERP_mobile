import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../fees/presentation/fees_dues_view.dart';
import 'providers/home_providers.dart';

class FeeClerkHome extends ConsumerWidget {
  const FeeClerkHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(feeClerkDashboardProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ResponsiveScaffold(
      title: 'Fee Desk',
      destinations: const [
        NavDestination(
          label: 'Desk',
          icon: Icons.point_of_sale_outlined,
          selectedIcon: Icons.point_of_sale_rounded,
        ),
        NavDestination(
          label: 'Dues',
          icon: Icons.pending_actions_outlined,
          selectedIcon: Icons.pending_actions_rounded,
        ),
        NavDestination(
          label: 'Receipts',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
        ),
      ],
      bodies: [
        ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 680 ? 3 : 2;
                final spacing = AppSpacing.md;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: width,
                      child: StatCard(
                        icon: Icons.payments_outlined,
                        value: data.todayCollection,
                        label: "Today's Collection",
                        tone: StatTone.success,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StatCard(
                        icon: Icons.pending_actions_outlined,
                        value: data.pendingDues,
                        label: 'Pending Dues',
                        tone: StatTone.warning,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StatCard(
                        icon: Icons.receipt_outlined,
                        value: data.receiptsToday,
                        label: 'Receipts Today',
                        tone: StatTone.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Collect Fee',
              icon: Icons.add_card_outlined,
              fullWidth: true,
              onPressed: () => showCollectFeeSheet(context, ref),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Recent Activity'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.recentReceipts.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final item = data.recentReceipts[index];
                  return ListTile(
                    title: Text(item.studentName, style: textTheme.titleSmall),
                    subtitle: Text(
                      '${item.receiptNo} • ${item.classLabel} • ${item.mode}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.amount,
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        StatusChip(status: item.status),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const FeesDuesView(),
        const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'All Receipts',
          subtitle: 'Searchable receipt ledger will appear here.',
        ),
      ],
    );
  }
}
