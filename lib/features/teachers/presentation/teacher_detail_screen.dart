import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/data/user_role.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/teacher_model.dart';
import '../providers/teachers_providers.dart';
import 'teacher_form_screen.dart';

class TeacherDetailScreen extends ConsumerWidget {
  const TeacherDetailScreen({super.key, required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync = ref.watch(teachersProvider);
    final role = ref.watch(currentProfileProvider).value?.role;
    final canViewSalary =
        role == UserRole.principal || role == UserRole.superAdmin;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: teachersAsync.when(
        loading: () => const LoadingView(message: 'Loading teacher record...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(teachersProvider),
        ),
        data: (teachers) {
          final teacher = teachers.cast<Teacher?>().firstWhere(
            (t) => t?.id == teacherId,
            orElse: () => null,
          );
          if (teacher == null) {
            return const EmptyState(
              icon: Icons.search_off_outlined,
              title: 'Teacher record not found',
            );
          }
          return _TeacherDetailBody(
            teacher: teacher,
            canViewSalary: canViewSalary,
          );
        },
      ),
    );
  }
}

class _TeacherDetailBody extends ConsumerWidget {
  const _TeacherDetailBody({
    required this.teacher,
    required this.canViewSalary,
  });

  final Teacher teacher;
  final bool canViewSalary;

  Future<void> _confirmToggleActive(BuildContext context, WidgetRef ref) async {
    final willActivate = !teacher.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(willActivate ? 'Activate Teacher?' : 'Deactivate Teacher?'),
        content: Text(
          willActivate
              ? 'This will re-enable ${teacher.fullName}\'s account (is_active = true).'
              : 'This will deactivate ${teacher.fullName}\'s account (is_active = false) without deleting any historical records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(willActivate ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref
        .read(teachersProvider.notifier)
        .setTeacherActive(teacher.id, willActivate);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          willActivate
              ? '${teacher.fullName} activated.'
              : '${teacher.fullName} deactivated.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final tabs = <Tab>[
      const Tab(text: 'Profile'),
      const Tab(text: 'Assignments'),
      const Tab(text: 'Qualifications'),
      const Tab(text: 'Documents'),
      if (canViewSalary) const Tab(text: 'Salary & Bank'),
    ];

    final tabViews = <Widget>[
      _ProfileTab(teacher: teacher),
      _AssignmentsTab(teacher: teacher),
      _QualificationsTab(teacher: teacher),
      _DocumentsTab(teacher: teacher),
      if (canViewSalary) _SalaryTab(teacher: teacher),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BreadcrumbBar(
                  items: [
                    BreadcrumbItem(
                      label: 'Teachers',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    BreadcrumbItem(label: teacher.fullName),
                  ],
                ),
                AppCard(
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          teacher.firstName.isNotEmpty
                              ? teacher.firstName[0].toUpperCase()
                              : '?',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 220),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher.fullName,
                              style: textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${teacher.employeeId} • ${teacher.designation}${teacher.department != null ? ' (${teacher.department})' : ''}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        status: teacher.status.chipStatus,
                        label: teacher.status.label,
                      ),
                      AppButton(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        variant: AppButtonVariant.tonal,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  TeacherFormScreen(editingTeacher: teacher),
                            ),
                          );
                        },
                      ),
                      AppButton(
                        label: teacher.isActive ? 'Deactivate' : 'Activate',
                        icon: teacher.isActive
                            ? Icons.block_outlined
                            : Icons.check_circle_outline,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => _confirmToggleActive(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TabBar(isScrollable: true, tabs: tabs),
              ],
            ),
          ),
          Expanded(child: TabBarView(children: tabViews)),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.teacher});

  final Teacher teacher;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _DetailSection(
          title: 'Basic Details',
          rows: [
            _InfoRow('Full Name', teacher.fullName),
            _InfoRow('Employee ID', teacher.employeeId),
            _InfoRow('Gender', teacher.gender ?? '-'),
            _InfoRow('Date of Birth', _fmt(teacher.dateOfBirth)),
            _InfoRow('Blood Group', teacher.bloodGroup ?? '-'),
            _InfoRow('Marital Status', teacher.maritalStatus ?? '-'),
            _InfoRow('Nationality', teacher.nationality),
            _InfoRow('Religion', teacher.religion ?? '-'),
            _InfoRow('Aadhaar', teacher.aadhaarNumber ?? '-'),
            _InfoRow('PAN', teacher.panNumber ?? '-'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailSection(
          title: 'Contact & Address',
          rows: [
            _InfoRow('Login Email', teacher.email),
            _InfoRow('Phone', teacher.phone ?? '-'),
            _InfoRow('Alternate Phone', teacher.alternatePhone ?? '-'),
            _InfoRow('Current Address', teacher.currentAddress ?? '-'),
            _InfoRow('Permanent Address', teacher.permanentAddress ?? '-'),
            _InfoRow(
              'City / State / Pincode',
              [
                teacher.city,
                teacher.state,
                teacher.pincode,
              ].where((e) => e != null && e.isNotEmpty).join(', '),
            ),
            _InfoRow(
              'Emergency Contact',
              [
                teacher.emergencyContactName,
                teacher.emergencyContactRelationship,
                teacher.emergencyContactPhone,
              ].where((e) => e != null && e.isNotEmpty).join(' • '),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailSection(
          title: 'Employment Details',
          rows: [
            _InfoRow('Designation', teacher.designation),
            _InfoRow('Department', teacher.department ?? '-'),
            _InfoRow('Employment Type', teacher.employmentType.label),
            _InfoRow('Joining Date', _fmt(teacher.joiningDate)),
            _InfoRow('Probation End Date', _fmt(teacher.probationEndDate)),
            _InfoRow('Reporting To', teacher.reportingToName ?? '-'),
            _InfoRow('Status', teacher.status.label),
            if (teacher.resignationDate != null)
              _InfoRow('Resignation Date', _fmt(teacher.resignationDate)),
          ],
        ),
      ],
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({required this.teacher});

  final Teacher teacher;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _DetailSection(
          title: 'Teachable Subjects & Class Teacher Role',
          rows: [
            _InfoRow(
              'Teachable Subjects',
              teacher.teachableSubjects.isEmpty
                  ? '-'
                  : teacher.teachableSubjects.join(', '),
            ),
            _InfoRow(
              'Class Teacher Of',
              teacher.classTeacherSection ?? 'Not assigned as class teacher',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Class & Subject Allocations'),
        const SizedBox(height: AppSpacing.sm),
        if (teacher.assignments.isEmpty)
          const EmptyState(
            icon: Icons.class_outlined,
            title: 'No class assignments yet',
          )
        else
          ...teacher.assignments.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text('${a.classSection} — ${a.subject}'),
                  subtitle: Text('Academic Year ${a.academicYearId}'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QualificationsTab extends StatelessWidget {
  const _QualificationsTab({required this.teacher});

  final Teacher teacher;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _DetailSection(
          title: 'Summary & Teaching Licence',
          rows: [
            _InfoRow('Total Experience', teacher.totalExperienceLabel),
            _InfoRow(
              'TET / CTET / B.Ed No.',
              teacher.teachingLicenseNumber ?? '-',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Qualifications'),
        const SizedBox(height: AppSpacing.sm),
        if (teacher.qualifications.isEmpty)
          const EmptyState(
            icon: Icons.school_outlined,
            title: 'No qualifications recorded',
          )
        else
          ...teacher.qualifications.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${q.degree}${q.specialization != null && q.specialization!.isNotEmpty ? ' (${q.specialization})' : ''}',
                  ),
                  subtitle: Text(
                    '${q.institution} • ${q.yearOfPassing ?? '-'} • ${q.percentageOrGrade ?? '-'}',
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Previous Experience'),
        const SizedBox(height: AppSpacing.sm),
        if (teacher.experiences.isEmpty)
          const EmptyState(
            icon: Icons.work_history_outlined,
            title: 'No previous experience recorded',
          )
        else
          ...teacher.experiences.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${e.organization} • ${e.designation ?? '-'}'),
                  subtitle: Text(
                    '${_fmt(e.fromDate)} to ${_fmt(e.toDate)}${e.reasonForLeaving != null ? ' • ${e.reasonForLeaving}' : ''}',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({required this.teacher});

  final Teacher teacher;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        if (teacher.documents.isEmpty)
          const EmptyState(
            icon: Icons.folder_open_outlined,
            title: 'No documents uploaded',
          )
        else
          ...teacher.documents.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(d.docType),
                  subtitle: Text(d.fileName ?? d.fileUrl),
                  trailing: const StatusChip(
                    status: StatusType.present,
                    label: 'Uploaded',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SalaryTab extends StatelessWidget {
  const _SalaryTab({required this.teacher});

  final Teacher teacher;

  @override
  Widget build(BuildContext context) {
    final bank = teacher.bankDetails;
    if (bank == null) {
      return const EmptyState(
        icon: Icons.account_balance_outlined,
        title: 'No salary or bank details recorded',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _DetailSection(
          title: 'Salary Breakdown',
          rows: [
            _InfoRow('Basic Salary', '₹${bank.basicSalary.toStringAsFixed(0)}'),
            _InfoRow('Allowances', '₹${bank.allowances.toStringAsFixed(0)}'),
            _InfoRow('Deductions', '₹${bank.deductions.toStringAsFixed(0)}'),
            _InfoRow('Net Salary', '₹${bank.netSalary.toStringAsFixed(0)}'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailSection(
          title: 'Bank & Statutory Details',
          rows: [
            _InfoRow('Bank Name', bank.bankName ?? '-'),
            _InfoRow('Account Holder', bank.accountHolderName ?? '-'),
            _InfoRow('Account Number', bank.accountNumber ?? '-'),
            _InfoRow('IFSC Code', bank.ifscCode ?? '-'),
            _InfoRow('PF Number', bank.pfNumber ?? '-'),
            _InfoRow('ESI Number', bank.esiNumber ?? '-'),
          ],
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 170,
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

class _InfoRow {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
}

String _fmt(DateTime? d) {
  if (d == null) return '-';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
