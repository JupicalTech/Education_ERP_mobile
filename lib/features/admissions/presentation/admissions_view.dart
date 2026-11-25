import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/admission_model.dart';
import '../providers/admissions_providers.dart';
import 'admission_detail_screen.dart';
import 'new_enquiry_screen.dart';

class AdmissionsView extends ConsumerWidget {
  const AdmissionsView({super.key});

  void _openNewEnquiryForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NewEnquiryScreen(),
      ),
    );
  }

  void _openEnquiryRecord(BuildContext context, AdmissionEnquiry enquiry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdmissionDetailScreen(enquiryId: enquiry.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEnquiries = ref.watch(admissionsProvider);
    final filtered = ref.watch(filteredAdmissionsProvider);
    final selectedStatus = ref.watch(admissionStatusFilterProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final pendingCount = allEnquiries
        .where((e) => e.status != LeadStatus.admitted)
        .length;
    final admittedCount = allEnquiries
        .where((e) => e.status == LeadStatus.admitted)
        .length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.assignment_ind_outlined,
                value: '${allEnquiries.length}',
                label: 'Total Enquiries',
                tone: StatTone.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatCard(
                icon: Icons.phone_callback_outlined,
                value: '$pendingCount',
                label: 'Active Leads',
                tone: StatTone.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatCard(
                icon: Icons.how_to_reg_outlined,
                value: '$admittedCount',
                label: 'Admitted',
                tone: StatTone.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Expanded(
              child: SectionHeader(title: 'Admissions & Enquiries'),
            ),
            AppButton(
              label: 'New Enquiry',
              icon: Icons.add,
              onPressed: () => _openNewEnquiryForm(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  selected: selectedStatus == null,
                  label: const Text('All'),
                  onSelected: (_) => ref
                      .read(admissionStatusFilterProvider.notifier)
                      .select(null),
                ),
              ),
              ...LeadStatus.values.map(
                (status) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    selected: selectedStatus == status,
                    label: Text(status.label),
                    onSelected: (_) => ref
                        .read(admissionStatusFilterProvider.notifier)
                        .select(status),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.assignment_ind_outlined,
            title: 'No enquiries in this stage',
            subtitle: 'Tap "New Enquiry" to add a prospective student.',
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final item = filtered[index];
                return ListTile(
                  onTap: () => _openEnquiryRecord(context, item),
                  title: Text(item.studentName, style: textTheme.titleSmall),
                  subtitle: Text(
                    '${item.applyingForClass} • ${item.guardianName} • ${item.followUpNote}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.dateLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      StatusChip(
                        status: item.status.chipType,
                        label: item.status.label,
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
