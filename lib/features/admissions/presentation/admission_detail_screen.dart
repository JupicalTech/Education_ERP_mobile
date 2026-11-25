import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/admission_model.dart';
import '../providers/admissions_providers.dart';

class AdmissionDetailScreen extends ConsumerStatefulWidget {
  const AdmissionDetailScreen({super.key, required this.enquiryId});

  final String enquiryId;

  @override
  ConsumerState<AdmissionDetailScreen> createState() =>
      _AdmissionDetailScreenState();
}

class _AdmissionDetailScreenState extends ConsumerState<AdmissionDetailScreen> {
  late final TextEditingController _noteController;
  bool _noteInitialized = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enquiries = ref.watch(admissionsProvider);
    final enquiry = enquiries.cast<AdmissionEnquiry?>().firstWhere(
      (e) => e?.id == widget.enquiryId,
      orElse: () => null,
    );

    if (enquiry == null) {
      return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: const EmptyState(
          icon: Icons.search_off_outlined,
          title: 'Record not found',
        ),
      );
    }

    if (!_noteInitialized) {
      _noteController.text = enquiry.followUpNote;
      _noteInitialized = true;
    }

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isAdmitted = enquiry.status == LeadStatus.admitted;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          BreadcrumbBar(
            items: [
              BreadcrumbItem(
                label: 'Admissions',
                onTap: () => Navigator.of(context).pop(),
              ),
              BreadcrumbItem(label: enquiry.studentName),
            ],
          ),
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    enquiry.studentName.isNotEmpty
                        ? enquiry.studentName[0].toUpperCase()
                        : '?',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enquiry.studentName,
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Applying for ${enquiry.applyingForClass} • ${enquiry.dateLabel}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  status: enquiry.status.chipType,
                  label: enquiry.status.label,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Applicant & Guardian Details'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _RecordRow(
                  label: 'Enquiry ID',
                  value: enquiry.id.toUpperCase(),
                ),
                const Divider(),
                _RecordRow(
                  label: 'Applying Class',
                  value: enquiry.applyingForClass,
                ),
                const Divider(),
                _RecordRow(
                  label: 'Guardian Name',
                  value: enquiry.guardianName,
                ),
                const Divider(),
                _RecordRow(
                  label: 'Guardian Phone',
                  value: enquiry.guardianPhone,
                ),
                const Divider(),
                _RecordRow(
                  label: 'Previous School',
                  value: enquiry.previousSchool,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Documents & Verification'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Birth Certificate & Transfer Certificate'),
              subtitle: Text(
                enquiry.documentsAttached
                    ? 'Documents verified and attached'
                    : 'Pending document submission',
              ),
              value: enquiry.documentsAttached,
              onChanged: isAdmitted
                  ? null
                  : (val) => ref
                        .read(admissionsProvider.notifier)
                        .updateDetails(enquiry.id, documentsAttached: val),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Lead Status & Follow-up'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isAdmitted) ...[
                  Text('Current Stage', style: textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      LeadStatus.newLead,
                      LeadStatus.contacted,
                      LeadStatus.visited,
                    ]
                        .map(
                          (s) => ChoiceChip(
                            selected: enquiry.status == s,
                            label: Text(s.label),
                            onSelected: (_) => ref
                                .read(admissionsProvider.notifier)
                                .updateStatus(enquiry.id, s),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                AppTextField(
                  controller: _noteController,
                  label: 'Follow-up Note',
                  enabled: !isAdmitted,
                ),
                if (!isAdmitted) ...[
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      label: 'Save Note',
                      variant: AppButtonVariant.tonal,
                      onPressed: () {
                        ref
                            .read(admissionsProvider.notifier)
                            .updateDetails(
                              enquiry.id,
                              followUpNote: _noteController.text.trim(),
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Follow-up note updated'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isAdmitted) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Approve & Create Student',
              icon: Icons.how_to_reg_outlined,
              fullWidth: true,
              onPressed: () async {
                await ref
                    .read(admissionsProvider.notifier)
                    .approveAdmission(enquiry);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${enquiry.studentName} admitted and added to Students!',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
