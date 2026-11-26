import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/teacher_model.dart';
import '../providers/teachers_providers.dart';
import 'teacher_detail_screen.dart';
import 'teacher_form_screen.dart';

class TeachersListView extends ConsumerStatefulWidget {
  const TeachersListView({super.key});

  @override
  ConsumerState<TeachersListView> createState() => _TeachersListViewState();
}

class _TeachersListViewState extends ConsumerState<TeachersListView> {
  final _searchController = TextEditingController();

  static const _subjects = [
    'Physics',
    'Mathematics',
    'English',
    'Social Studies',
    'Computer Science',
    'History',
    'Chemistry',
    'Biology',
  ];

  static const _classes = [
    'Class 3',
    'Class 6',
    'Class 8',
    'Class 9',
    'Class 10',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTeacher() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TeacherFormScreen()),
    );
  }

  void _openTeacherDetail(Teacher teacher) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherDetailScreen(teacherId: teacher.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(filteredTeachersProvider);
    final stats = ref.watch(teacherStatsProvider);
    final subjectFilter = ref.watch(teacherSubjectFilterProvider);
    final classFilter = ref.watch(teacherClassFilterProvider);
    final statusFilter = ref.watch(teacherStatusFilterProvider);
    final empTypeFilter = ref.watch(teacherEmploymentTypeFilterProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 680 ? 4 : 2;
            const spacing = AppSpacing.md;
            final cardWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            final cards = [
              StatCard(
                icon: Icons.groups_outlined,
                value: '${stats.total}',
                label: 'Total Teachers',
                tone: StatTone.primary,
              ),
              StatCard(
                icon: Icons.check_circle_outline,
                value: '${stats.active}',
                label: 'Active',
                tone: StatTone.success,
              ),
              StatCard(
                icon: Icons.event_busy_outlined,
                value: '${stats.onLeave}',
                label: 'On Leave',
                tone: StatTone.warning,
              ),
              StatCard(
                icon: Icons.school_outlined,
                value: '${stats.classTeachers}',
                label: 'Class Teachers',
                tone: StatTone.info,
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: cards
                  .map((c) => SizedBox(width: cardWidth, child: c))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => ref
                    .read(teacherSearchQueryProvider.notifier)
                    .setValue(value),
                decoration: InputDecoration(
                  hintText: 'Search by name, employee ID, or phone...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(teacherSearchQueryProvider.notifier)
                                .setValue('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AppButton(
              label: 'Add Teacher',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: _openAddTeacher,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _FilterDropdown<String>(
                label: 'Subject',
                value: subjectFilter,
                items: _subjects,
                itemLabel: (s) => s,
                onChanged: (v) =>
                    ref.read(teacherSubjectFilterProvider.notifier).select(v),
              ),
              _FilterDropdown<String>(
                label: 'Class',
                value: classFilter,
                items: _classes,
                itemLabel: (c) => c,
                onChanged: (v) =>
                    ref.read(teacherClassFilterProvider.notifier).select(v),
              ),
              _FilterDropdown<TeacherStatus>(
                label: 'Status',
                value: statusFilter,
                items: TeacherStatus.values,
                itemLabel: (s) => s.label,
                onChanged: (v) =>
                    ref.read(teacherStatusFilterProvider.notifier).select(v),
              ),
              _FilterDropdown<EmploymentType>(
                label: 'Employment Type',
                value: empTypeFilter,
                items: EmploymentType.values,
                itemLabel: (e) => e.label,
                onChanged: (v) => ref
                    .read(teacherEmploymentTypeFilterProvider.notifier)
                    .select(v),
              ),
              if (subjectFilter != null ||
                  classFilter != null ||
                  statusFilter != null ||
                  empTypeFilter != null)
                TextButton.icon(
                  onPressed: () {
                    ref.read(teacherSubjectFilterProvider.notifier).select(null);
                    ref.read(teacherClassFilterProvider.notifier).select(null);
                    ref.read(teacherStatusFilterProvider.notifier).select(null);
                    ref
                        .read(teacherEmploymentTypeFilterProvider.notifier)
                        .select(null);
                  },
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear filters'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          teachersAsync.when(
            loading: () => const LoadingView(message: 'Loading teachers...'),
            error: (err, _) => ErrorView(
              message: err.toString(),
              onRetry: () => ref.invalidate(teachersProvider),
            ),
            data: (teachers) {
              if (teachers.isEmpty) {
                return const EmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'No teachers match your filters',
                  subtitle: 'Try adjusting your search or filter criteria.',
                );
              }

              return Column(
                children: teachers
                    .map(
                      (teacher) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _TeacherRowCard(
                          teacher: teacher,
                          onTap: () => _openTeacherDetail(teacher),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        items: [
          DropdownMenuItem<T?>(value: null, child: Text('All $label')),
          ...items.map(
            (item) => DropdownMenuItem<T?>(
              value: item,
              child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _TeacherRowCard extends StatelessWidget {
  const _TeacherRowCard({required this.teacher, required this.onTap});

  final Teacher teacher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final subjects = teacher.teachableSubjects.isEmpty
        ? 'No subjects'
        : teacher.teachableSubjects.join(', ');
    final classes = teacher.assignedClasses.isEmpty
        ? 'Unassigned'
        : teacher.assignedClasses.join(', ');

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: teacher.photoUrl != null
                ? NetworkImage(teacher.photoUrl!)
                : null,
            child: teacher.photoUrl == null
                ? Text(
                    teacher.firstName.isNotEmpty
                        ? teacher.firstName[0].toUpperCase()
                        : '?',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        teacher.fullName,
                        style: textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      teacher.employeeId,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${teacher.designation} • $subjects',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Classes: $classes${teacher.phone != null && teacher.phone!.isNotEmpty ? ' • ${teacher.phone}' : ''}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusChip(
            status: teacher.status.chipStatus,
            label: teacher.status.label,
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
