import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/student_model.dart';
import '../providers/students_providers.dart';
import 'student_admission_screen.dart';
import 'student_detail_screen.dart';

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

  void _openStudentDetail(Student student) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentDetailScreen(studentId: student.id),
      ),
    );
  }

  void _openAdmissionForm() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const StudentAdmissionScreen(),
      ),
    );
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
              label: 'New Admission',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: _openAdmissionForm,
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
                    onTap: () => _openStudentDetail(student),
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
