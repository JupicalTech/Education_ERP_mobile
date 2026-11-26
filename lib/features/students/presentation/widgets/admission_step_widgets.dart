import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/student_admission_model.dart';
import '../../providers/students_providers.dart';

String? validateTenDigitPhone(String? value, {bool required = false}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return required ? 'Phone is required' : null;
  }
  if (!RegExp(r'^\d{10}$').hasMatch(trimmed)) {
    return 'Enter a valid 10-digit phone number';
  }
  return null;
}

String? validateSixDigitPincode(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
    return 'Pincode must be 6 digits';
  }
  return null;
}

String? validateTwelveDigitAadhaar(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  if (!RegExp(r'^\d{12}$').hasMatch(trimmed)) {
    return 'Aadhaar must be 12 digits';
  }
  return null;
}

String formatDisplayDate(DateTime? date) {
  if (date == null) return 'Select date';
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

/// Responsive 2-column grid on wide screens, 1-column stack on mobile.
class FormFieldGrid extends StatelessWidget {
  const FormFieldGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoCol = constraints.maxWidth >= 560;
        if (!isTwoCol) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (int i = 0; i < children.length; i += 2) {
          final hasSecond = i + 1 < children.length;
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: hasSecond ? children[i + 1] : const SizedBox.shrink(),
                ),
              ],
            ),
          );
          if (i + 2 < children.length) {
            rows.add(const SizedBox(height: AppSpacing.md));
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onPicked,
    this.firstDate,
    this.lastDate,
    this.isRequired = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(now.year - 10, now.month, now.day),
          firstDate: firstDate ?? DateTime(1995),
          lastDate: lastDate ?? now,
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          formatDisplayDate(value),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: value == null
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : null,
          ),
        ),
      ),
    );
  }
}

class GuardianSectionCard extends StatelessWidget {
  const GuardianSectionCard({
    super.key,
    required this.title,
    required this.guardian,
    required this.onChanged,
    this.includeIncomeAndOccupation = true,
    this.includeRelationshipInput = false,
  });

  final String title;
  final GuardianInput guardian;
  final ValueChanged<GuardianInput> onChanged;
  final bool includeIncomeAndOccupation;
  final bool includeRelationshipInput;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title),
          const SizedBox(height: AppSpacing.md),
          FormFieldGrid(
            children: [
              TextFormField(
                initialValue: guardian.name,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                onChanged: (v) => onChanged(guardian.copyWith(name: v)),
              ),
              TextFormField(
                initialValue: guardian.phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  counterText: '',
                ),
                onChanged: (v) => onChanged(guardian.copyWith(phone: v)),
              ),
              if (includeRelationshipInput)
                TextFormField(
                  initialValue: guardian.relationship,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.family_restroom_outlined),
                  ),
                  onChanged: (v) =>
                      onChanged(guardian.copyWith(relationship: v)),
                ),
              if (includeIncomeAndOccupation) ...[
                TextFormField(
                  initialValue: guardian.email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  onChanged: (v) => onChanged(guardian.copyWith(email: v)),
                ),
                TextFormField(
                  initialValue: guardian.occupation,
                  decoration: const InputDecoration(
                    labelText: 'Occupation',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  onChanged: (v) => onChanged(guardian.copyWith(occupation: v)),
                ),
                TextFormField(
                  initialValue: guardian.qualification,
                  decoration: const InputDecoration(
                    labelText: 'Qualification',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  onChanged: (v) =>
                      onChanged(guardian.copyWith(qualification: v)),
                ),
                TextFormField(
                  initialValue: guardian.annualIncome,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Annual Income (Optional)',
                    prefixIcon: Icon(Icons.currency_rupee_outlined),
                  ),
                  onChanged: (v) =>
                      onChanged(guardian.copyWith(annualIncome: v)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class SiblingPickerSection extends ConsumerStatefulWidget {
  const SiblingPickerSection({super.key});

  @override
  ConsumerState<SiblingPickerSection> createState() =>
      _SiblingPickerSectionState();
}

class _SiblingPickerSectionState extends ConsumerState<SiblingPickerSection> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final selectedIds = ref.watch(
      studentAdmissionProvider.select((s) => s.payload.siblingIds),
    );
    final notifier = ref.read(studentAdmissionProvider.notifier);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Siblings Already in School'),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search existing students by name or admission no...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          const SizedBox(height: AppSpacing.md),
          studentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Unable to load students: $e'),
            data: (students) {
              final selectedStudents = students
                  .where((s) => selectedIds.contains(s.id))
                  .toList();
              final matches = _query.isEmpty
                  ? students.take(4).toList()
                  : students
                        .where(
                          (s) =>
                              s.fullName.toLowerCase().contains(_query) ||
                              s.admissionNo.toLowerCase().contains(_query),
                        )
                        .take(5)
                        .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedStudents.isNotEmpty) ...[
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: selectedStudents
                          .map(
                            (s) => InputChip(
                              label: Text('${s.fullName} (${s.classSection})'),
                              onDeleted: () => notifier.toggleSibling(s.id),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (matches.isEmpty)
                    Text(
                      'No matching students found.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    ...matches.map((s) {
                      final isLinked = selectedIds.contains(s.id);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: isLinked,
                        title: Text(s.fullName),
                        subtitle: Text('${s.classSection} • ${s.admissionNo}'),
                        onChanged: (_) => notifier.toggleSibling(s.id),
                      );
                    }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class AdmissionReviewSection extends ConsumerWidget {
  const AdmissionReviewSection({super.key, required this.onEditStep});

  final ValueChanged<int> onEditStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = ref.watch(
      studentAdmissionProvider.select((s) => s.payload),
    );
    final uploadedDocs = payload.documents.where((d) => d.isUploaded).length;
    final prevSchools = payload.previousSchools
        .where((s) => s.schoolName.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReviewCard(
          title: '1. Basic Details',
          onEdit: () => onEditStep(0),
          rows: [
            _ReviewItem(
              'Full Name',
              '${payload.firstName} ${payload.middleName} ${payload.lastName}'
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim(),
            ),
            _ReviewItem('Date of Birth', formatDisplayDate(payload.dateOfBirth)),
            _ReviewItem('Gender', payload.gender ?? '-'),
            _ReviewItem('Blood Group', payload.bloodGroup ?? '-'),
            _ReviewItem('Category', payload.category?.label ?? '-'),
            _ReviewItem('Aadhaar', _orDash(payload.aadhaarNumber)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ReviewCard(
          title: '2. Admission Details',
          onEdit: () => onEditStep(1),
          rows: [
            _ReviewItem('Admission No', payload.admissionNumber),
            _ReviewItem(
              'Admission Date',
              formatDisplayDate(payload.admissionDate),
            ),
            _ReviewItem('Academic Year', payload.academicYear),
            _ReviewItem(
              'Class & Section',
              '${payload.className ?? '-'} - ${payload.sectionName ?? '-'}',
            ),
            _ReviewItem('Admission Type', payload.admissionType.label),
            _ReviewItem('Student Type', payload.studentType.label),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ReviewCard(
          title: '3. Contact & Address',
          onEdit: () => onEditStep(2),
          rows: [
            _ReviewItem('Current Address', _orDash(payload.currentAddress)),
            _ReviewItem(
              'City / State / PIN',
              [
                payload.city,
                payload.state,
                payload.pincode,
              ].where((e) => e.trim().isNotEmpty).join(', '),
            ),
            _ReviewItem('Student Phone', _orDash(payload.studentPhone)),
            _ReviewItem('Student Email', _orDash(payload.studentEmail)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ReviewCard(
          title: '4. Parent / Guardian',
          onEdit: () => onEditStep(3),
          rows: [
            if (payload.father.hasAnyData)
              _ReviewItem(
                'Father',
                '${payload.father.name} (${payload.father.phone})',
              ),
            if (payload.mother.hasAnyData)
              _ReviewItem(
                'Mother',
                '${payload.mother.name} (${payload.mother.phone})',
              ),
            if (payload.hasSeparateGuardian && payload.guardian.hasAnyData)
              _ReviewItem(
                'Guardian',
                '${payload.guardian.name} • ${payload.guardian.relationship} (${payload.guardian.phone})',
              ),
            _ReviewItem('Primary Contact', payload.primaryContact.name.toUpperCase()),
            if (payload.emergencyContactName.trim().isNotEmpty)
              _ReviewItem(
                'Emergency',
                '${payload.emergencyContactName} (${payload.emergencyContactPhone})',
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ReviewCard(
          title: '5. Previous School & 6. Other Info',
          onEdit: () => onEditStep(4),
          rows: [
            _ReviewItem(
              'Previous Schools',
              prevSchools.isEmpty
                  ? 'None'
                  : prevSchools.map((s) => '${s.schoolName} (${s.board.label})').join(', '),
            ),
            _ReviewItem('Linked Siblings', '${payload.siblingIds.length}'),
            _ReviewItem(
              'Transport',
              payload.transportNeeded
                  ? 'Yes (${_orDash(payload.transportRouteStop)})'
                  : 'No',
            ),
            _ReviewItem(
              'Documents Attached',
              '$uploadedDocs / ${payload.documents.length}',
            ),
          ],
        ),
      ],
    );
  }

  String _orDash(String value) => value.trim().isEmpty ? '-' : value.trim();
}

class _ReviewItem {
  const _ReviewItem(this.label, this.value);
  final String label;
  final String value;
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.onEdit,
    required this.rows,
  });

  final String title;
  final VoidCallback onEdit;
  final List<_ReviewItem> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, actionLabel: 'Edit', onAction: onEdit),
          const SizedBox(height: AppSpacing.sm),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      r.label,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.value.isEmpty ? '-' : r.value,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
