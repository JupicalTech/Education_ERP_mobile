import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/student_admission_model.dart';
import '../data/student_model.dart';
import '../providers/students_providers.dart';
import 'student_admission_screen.dart';
import 'widgets/admission_step_widgets.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: studentsAsync.when(
        loading: () => const LoadingView(message: 'Loading student record...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(studentsProvider),
        ),
        data: (students) {
          final student = students.cast<Student?>().firstWhere(
            (s) => s?.id == studentId,
            orElse: () => null,
          );

          if (student == null) {
            return const EmptyState(
              icon: Icons.search_off_outlined,
              title: 'Student record not found',
            );
          }

          return _StudentDetailBody(
            student: student,
            allStudents: students,
          );
        },
      ),
    );
  }
}

class _StudentDetailBody extends StatelessWidget {
  const _StudentDetailBody({
    required this.student,
    required this.allStudents,
  });

  final Student student;
  final List<Student> allStudents;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final details = student.admissionDetails;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        BreadcrumbBar(
          items: [
            BreadcrumbItem(
              label: 'Students',
              onTap: () => Navigator.of(context).pop(),
            ),
            BreadcrumbItem(label: student.fullName),
          ],
        ),
        AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  student.firstName.isNotEmpty
                      ? student.firstName[0].toUpperCase()
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
                    Text(student.fullName, style: textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${student.classSection} • Roll #${student.rollNo} • ${student.admissionNo}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(status: student.feeStatus),
              const SizedBox(width: AppSpacing.md),
              AppButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                variant: AppButtonVariant.tonal,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          StudentAdmissionScreen(editingStudent: student),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Basic & Admission Details'),
        const SizedBox(height: AppSpacing.sm),
        _RecordCard(
          rows: [
            _RecordRow(label: 'Admission No', value: student.admissionNo),
            _RecordRow(label: 'Class & Section', value: student.classSection),
            _RecordRow(label: 'Roll Number', value: '${student.rollNo}'),
            _RecordRow(label: 'Attendance', value: student.attendancePercent),
            if (details != null) ...[
              _RecordRow(
                label: 'Full Name',
                value: [
                  details.firstName,
                  details.middleName,
                  details.lastName,
                ].where((e) => e.trim().isNotEmpty).join(' '),
              ),
              _RecordRow(
                label: 'Date of Birth',
                value: formatDisplayDate(details.dateOfBirth),
              ),
              _RecordRow(label: 'Gender', value: _orDash(details.gender)),
              _RecordRow(
                label: 'Blood Group',
                value: _orDash(details.bloodGroup),
              ),
              _RecordRow(
                label: 'Category',
                value: _orDash(details.category?.label),
              ),
              _RecordRow(
                label: 'Aadhaar',
                value: _orDash(details.aadhaarNumber),
              ),
              _RecordRow(
                label: 'Admission Date',
                value: formatDisplayDate(details.admissionDate),
              ),
              _RecordRow(label: 'GR Number', value: _orDash(details.grNumber)),
              _RecordRow(label: 'Academic Year', value: details.academicYear),
              _RecordRow(
                label: 'Admission Type',
                value: details.admissionType.label,
              ),
              _RecordRow(
                label: 'Student Type',
                value: details.studentType.label,
              ),
              _RecordRow(
                label: 'Medium',
                value: _orDash(details.mediumOfInstruction),
              ),
            ],
          ],
        ),
        if (details != null) ...[
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Contact & Address'),
          const SizedBox(height: AppSpacing.sm),
          _RecordCard(
            rows: [
              _RecordRow(
                label: 'Current Address',
                value: _orDash(details.currentAddress),
              ),
              _RecordRow(
                label: 'Permanent Address',
                value: _orDash(
                  details.sameAsCurrentAddress
                      ? details.currentAddress
                      : details.permanentAddress,
                ),
              ),
              _RecordRow(
                label: 'City / State / PIN',
                value: _orDash(
                  [
                    details.city,
                    details.state,
                    details.pincode,
                  ].where((e) => e.trim().isNotEmpty).join(', '),
                ),
              ),
              _RecordRow(
                label: 'Student Phone',
                value: _orDash(details.studentPhone),
              ),
              _RecordRow(
                label: 'Student Email',
                value: _orDash(details.studentEmail),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Parent / Guardian Details'),
        const SizedBox(height: AppSpacing.sm),
        _RecordCard(
          rows: [
            _RecordRow(label: 'Primary Guardian', value: student.guardianName),
            _RecordRow(label: 'Primary Phone', value: student.guardianPhone),
            if (details != null) ...[
              if (details.father.hasAnyData)
                _RecordRow(
                  label: 'Father',
                  value: _formatGuardian(details.father),
                ),
              if (details.mother.hasAnyData)
                _RecordRow(
                  label: 'Mother',
                  value: _formatGuardian(details.mother),
                ),
              if (details.hasSeparateGuardian && details.guardian.hasAnyData)
                _RecordRow(
                  label: 'Guardian (${details.guardian.relationship})',
                  value: _formatGuardian(details.guardian),
                ),
              if (details.emergencyContactName.trim().isNotEmpty ||
                  details.emergencyContactPhone.trim().isNotEmpty)
                _RecordRow(
                  label: 'Emergency Contact',
                  value: [
                    details.emergencyContactName,
                    details.emergencyContactRelationship,
                    details.emergencyContactPhone,
                  ].where((e) => e.trim().isNotEmpty).join(' • '),
                ),
            ],
          ],
        ),
        if (details != null) ...[
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Previous Schools'),
          const SizedBox(height: AppSpacing.sm),
          _buildPreviousSchools(details),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Medical, Transport & Other Info'),
          const SizedBox(height: AppSpacing.sm),
          _RecordCard(
            rows: [
              _RecordRow(label: 'Allergies', value: _orDash(details.allergies)),
              _RecordRow(
                label: 'Conditions',
                value: _orDash(details.medicalConditions),
              ),
              _RecordRow(
                label: 'Doctor Contact',
                value: _orDash(details.doctorContact),
              ),
              _RecordRow(
                label: 'Special Needs',
                value: _orDash(details.specialNeeds),
              ),
              _RecordRow(
                label: 'Transport',
                value: details.transportNeeded
                    ? 'Yes (${_orDash(details.transportRouteStop)})'
                    : 'No',
              ),
              _RecordRow(
                label: 'Linked Siblings',
                value: _formatSiblings(details.siblingIds),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Documents'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: details.documents.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final doc = details.documents[index];
                return ListTile(
                  leading: Icon(
                    doc.isUploaded
                        ? Icons.check_circle_outline
                        : Icons.description_outlined,
                    color: doc.isUploaded
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(doc.docType.label),
                  subtitle: Text(doc.fileName ?? 'Not uploaded'),
                  trailing: StatusChip(
                    status: doc.isUploaded
                        ? StatusType.paid
                        : StatusType.pending,
                    label: doc.isUploaded ? 'Uploaded' : 'Pending',
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviousSchools(StudentAdmissionPayload details) {
    final schools = details.previousSchools
        .where((s) => s.schoolName.trim().isNotEmpty)
        .toList();
    if (schools.isEmpty) {
      return const _RecordCard(
        rows: [_RecordRow(label: 'Previous School', value: 'None recorded')],
      );
    }
    return _RecordCard(
      rows: [
        for (int i = 0; i < schools.length; i++)
          _RecordRow(
            label: 'School ${i + 1}',
            value: [
              '${schools[i].schoolName} (${schools[i].board.label})',
              if (schools[i].lastClassAttended.trim().isNotEmpty)
                'Class: ${schools[i].lastClassAttended}',
              if (schools[i].yearOfPassing.trim().isNotEmpty)
                'Year: ${schools[i].yearOfPassing}',
              if (schools[i].tcNumber.trim().isNotEmpty)
                'TC: ${schools[i].tcNumber}',
            ].join(' • '),
          ),
      ],
    );
  }

  String _formatGuardian(GuardianInput g) {
    return [
      g.name,
      if (g.phone.trim().isNotEmpty) g.phone,
      if (g.occupation.trim().isNotEmpty) g.occupation,
    ].join(' • ');
  }

  String _formatSiblings(List<String> siblingIds) {
    if (siblingIds.isEmpty) return 'None';
    final names = siblingIds.map((id) {
      final match = allStudents.cast<Student?>().firstWhere(
        (s) => s?.id == id,
        orElse: () => null,
      );
      return match != null ? '${match.fullName} (${match.classSection})' : id;
    }).toList();
    return names.join(', ');
  }

  String _orDash(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '-' : trimmed;
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.rows});

  final List<_RecordRow> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1) const Divider(),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
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
