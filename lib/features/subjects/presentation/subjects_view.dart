import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../academic_years/providers/academic_years_providers.dart';
import '../../classes/data/class_model.dart';
import '../../classes/providers/classes_providers.dart';
import '../data/subject_model.dart';
import '../providers/subjects_providers.dart';

enum _SubjectsTab { subjects, mapping }

class SubjectsView extends ConsumerStatefulWidget {
  const SubjectsView({super.key});

  @override
  ConsumerState<SubjectsView> createState() => _SubjectsViewState();
}

class _SubjectsViewState extends ConsumerState<SubjectsView> {
  _SubjectsTab _tab = _SubjectsTab.subjects;

  Future<void> _showSubjectDialog({Subject? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final codeController = TextEditingController(text: existing?.code ?? '');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add Subject' : 'Edit Subject'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: nameController,
                  label: 'Subject Name',
                  hint: 'e.g. Mathematics, Science',
                  prefixIcon: Icons.menu_book_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: codeController,
                  label: 'Subject Code (optional)',
                  hint: 'e.g. MATH, SCI',
                  prefixIcon: Icons.tag_outlined,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final notifier = ref.read(subjectsProvider.notifier);
      if (existing == null) {
        await notifier.createSubject(
          name: nameController.text,
          code: codeController.text,
        );
      } else {
        await notifier.updateSubject(
          id: existing.id,
          name: nameController.text,
          code: codeController.text,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Could not save subject: $e'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteSubject(Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${subject.name}?'),
        content: const Text(
          'This will also remove any teacher mappings for this subject.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(subjectsProvider.notifier).deleteSubject(subject.id);
      ref.invalidate(subjectMappingsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Could not delete subject: $e'),
        ),
      );
    }
  }

  Future<void> _showAssignMappingDialog() async {
    final classes = ref.read(classesProvider).value ?? const <SchoolClass>[];
    final subjects = ref.read(subjectsProvider).value ?? const <Subject>[];
    final teachers = await ref.read(teacherOptionsProvider.future);

    if (!mounted) return;

    final sectionOptions = <(String id, String label)>[
      for (final c in classes)
        for (final s in c.sections) (s.id, '${c.name}-${s.name}'),
    ];

    if (sectionOptions.isEmpty || subjects.isEmpty || teachers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Make sure you have at least one Class/Section, Subject, and active Teacher first.',
          ),
        ),
      );
      return;
    }

    var selectedSectionId = sectionOptions.first.$1;
    var selectedSubjectId = subjects.first.id;
    var selectedTeacherId = teachers.first.profileId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Subject Teacher'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedSectionId,
                  decoration: const InputDecoration(
                    labelText: 'Class & Section',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  items: sectionOptions
                      .map(
                        (s) => DropdownMenuItem(value: s.$1, child: Text(s.$2)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedSectionId = v);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  items: subjects
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            s.code != null ? '${s.name} (${s.code})' : s.name,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedSubjectId = v);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedTeacherId,
                  decoration: const InputDecoration(
                    labelText: 'Teacher',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: teachers
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.profileId,
                          child: Text(
                            t.designation.isNotEmpty
                                ? '${t.name} (${t.designation})'
                                : t.name,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedTeacherId = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(subjectMappingsProvider.notifier)
          .assignMapping(
            sectionId: selectedSectionId,
            subjectId: selectedSubjectId,
            teacherProfileId: selectedTeacherId,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Could not assign teacher: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<_SubjectsTab>(
              segments: const [
                ButtonSegment(
                  value: _SubjectsTab.subjects,
                  icon: Icon(Icons.menu_book_outlined, size: 18),
                  label: Text('Subjects'),
                ),
                ButtonSegment(
                  value: _SubjectsTab.mapping,
                  icon: Icon(Icons.hub_outlined, size: 18),
                  label: Text('Teacher Mapping'),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
            AppButton(
              label: _tab == _SubjectsTab.subjects
                  ? 'Add Subject'
                  : 'Assign Teacher',
              icon: Icons.add,
              onPressed: _tab == _SubjectsTab.subjects
                  ? () => _showSubjectDialog()
                  : _showAssignMappingDialog,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_tab == _SubjectsTab.subjects)
          _buildSubjectsList(textTheme, colorScheme)
        else
          _buildMappingList(textTheme, colorScheme),
      ],
    );
  }

  Widget _buildSubjectsList(TextTheme textTheme, ColorScheme colorScheme) {
    final subjectsAsync = ref.watch(subjectsProvider);
    return subjectsAsync.when(
      loading: () => const LoadingView(message: 'Loading subjects...'),
      error: (e, _) => ErrorView(
        message: 'Could not load subjects: $e',
        onRetry: () => ref.invalidate(subjectsProvider),
      ),
      data: (subjects) {
        if (subjects.isEmpty) {
          return EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No subjects yet',
            subtitle: 'Add subjects like Mathematics, Science, or English.',
            actionLabel: 'Add Subject',
            onAction: () => _showSubjectDialog(),
          );
        }
        return Column(
          children: subjects
              .map(
                (subject) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.menu_book_outlined,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(subject.name, style: textTheme.titleSmall),
                      subtitle: subject.code != null
                          ? Text('Code: ${subject.code}')
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit subject',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _showSubjectDialog(existing: subject),
                          ),
                          IconButton(
                            tooltip: 'Delete subject',
                            icon: Icon(
                              Icons.delete_outline,
                              color: colorScheme.error,
                            ),
                            onPressed: () => _confirmDeleteSubject(subject),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildMappingList(TextTheme textTheme, ColorScheme colorScheme) {
    final currentYear = ref.watch(currentAcademicYearProvider);
    final mappingsAsync = ref.watch(subjectMappingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currentYear == null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'No current academic year is set. Create or activate one in Academic Years first.',
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                const SectionHeader(title: 'Active Session'),
                const SizedBox(width: AppSpacing.sm),
                StatusChip(status: StatusType.info, label: currentYear.name),
              ],
            ),
          ),
        mappingsAsync.when(
          loading: () => const LoadingView(message: 'Loading mappings...'),
          error: (e, _) => ErrorView(
            message: 'Could not load mappings: $e',
            onRetry: () => ref.invalidate(subjectMappingsProvider),
          ),
          data: (mappings) {
            if (mappings.isEmpty) {
              return EmptyState(
                icon: Icons.hub_outlined,
                title: 'No teacher mappings yet',
                subtitle:
                    'Assign a subject and teacher to each section for the current academic year.',
                actionLabel: 'Assign Teacher',
                onAction: _showAssignMappingDialog,
              );
            }
            return Column(
              children: mappings
                  .map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${m.classSection} • ${m.subjectName}',
                            style: textTheme.titleSmall,
                          ),
                          subtitle: Text('Teacher: ${m.teacherName}'),
                          trailing: IconButton(
                            tooltip: 'Remove mapping',
                            icon: Icon(
                              Icons.delete_outline,
                              color: colorScheme.error,
                            ),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(subjectMappingsProvider.notifier)
                                    .deleteMapping(m.id);
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: colorScheme.error,
                                    content: Text('Could not remove: $e'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
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
