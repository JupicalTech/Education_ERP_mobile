import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/student_model.dart';
import '../providers/students_providers.dart';

class StudentsListView extends ConsumerStatefulWidget {
  const StudentsListView({super.key});

  @override
  ConsumerState<StudentsListView> createState() => _StudentsListViewState();
}

class _StudentsListViewState extends ConsumerState<StudentsListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStudentDetail(Student student) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    student.firstName.isNotEmpty ? student.firstName[0] : '?',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.fullName, style: textTheme.titleLarge),
                      Text(
                        '${student.classSection} • Roll #${student.rollNo}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: student.feeStatus),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            _DetailRow(label: 'Admission No', value: student.admissionNo),
            _DetailRow(label: 'Attendance', value: student.attendancePercent),
            _DetailRow(label: 'Guardian', value: student.guardianName),
            _DetailRow(label: 'Phone', value: student.guardianPhone),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddStudentDialog() async {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final guardianCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedClass = 'Class 8';

    final created = await showDialog<Student>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Student'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: firstNameCtrl,
                  label: 'First Name',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: lastNameCtrl,
                  label: 'Last Name',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedClass,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: const ['Class 3', 'Class 6', 'Class 8', 'Class 9']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) selectedClass = v;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: guardianCtrl,
                  label: 'Guardian Name',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: phoneCtrl,
                  label: 'Guardian Phone',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                Student(
                  id: 'stu-${DateTime.now().millisecondsSinceEpoch}',
                  admissionNo:
                      'ADM-2026-${DateTime.now().millisecond.toString().padLeft(3, '0')}',
                  firstName: firstNameCtrl.text.trim(),
                  lastName: lastNameCtrl.text.trim(),
                  className: selectedClass,
                  sectionName: 'A',
                  rollNo: 1,
                  guardianName: guardianCtrl.text.trim(),
                  guardianPhone: phoneCtrl.text.trim().isEmpty
                      ? 'Not provided'
                      : phoneCtrl.text.trim(),
                  attendancePercent: '100%',
                  feeStatus: StatusType.pending,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (created != null && mounted) {
      await ref.read(studentsProvider.notifier).addStudent(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(filteredStudentsProvider);
    final selectedClass = ref.watch(selectedClassFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const classes = ['Class 3', 'Class 6', 'Class 8', 'Class 9'];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => ref
                    .read(studentSearchQueryProvider.notifier)
                    .setQuery(value),
                decoration: InputDecoration(
                  hintText: 'Search by name or admission no...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(studentSearchQueryProvider.notifier)
                                .setQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AppButton(
              label: 'Add',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: _showAddStudentDialog,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  selected: selectedClass == null,
                  label: const Text('All Classes'),
                  onSelected: (_) =>
                      ref.read(selectedClassFilterProvider.notifier).select(null),
                ),
              ),
              ...classes.map(
                (cls) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    selected: selectedClass == cls,
                    label: Text(cls),
                    onSelected: (_) => ref
                        .read(selectedClassFilterProvider.notifier)
                        .select(cls),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        studentsAsync.when(
          loading: () => const LoadingView(message: 'Loading students...'),
          error: (err, _) => ErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(studentsProvider),
          ),
          data: (students) {
            if (students.isEmpty) {
              return const EmptyState(
                icon: Icons.people_outline,
                title: 'No matching students',
                subtitle: 'Try clearing your search or class filter.',
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final student = students[index];
                  return ListTile(
                    onTap: () => _showStudentDetail(student),
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        student.firstName.isNotEmpty
                            ? student.firstName[0]
                            : '?',
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(student.fullName, style: textTheme.titleSmall),
                    subtitle: Text(
                      '${student.classSection} • Roll #${student.rollNo} • ${student.admissionNo}',
                    ),
                    trailing: StatusChip(status: student.feeStatus),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 120,
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
