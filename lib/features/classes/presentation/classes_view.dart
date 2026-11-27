import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../data/class_model.dart';
import '../providers/classes_providers.dart';

class ClassesView extends ConsumerWidget {
  const ClassesView({super.key});

  Future<void> _showAddClassDialog(
    BuildContext context,
    WidgetRef ref,
    List<SchoolClass> existingClasses,
    int nextOrder,
  ) async {
    final classController = TextEditingController();
    final newSectionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final existingNames =
        existingClasses.map((c) => c.name.toLowerCase()).toSet();
    final availableSections = <String>['A', 'B', 'C', 'D', 'E'];
    final selectedSections = <String>{'A', 'B'};
    const quickClasses = [
      'Nursery',
      'LKG',
      'UKG',
      'Class 1',
      'Class 2',
      'Class 3',
      'Class 4',
      'Class 5',
      'Class 6',
      'Class 7',
      'Class 8',
      'Class 9',
      'Class 10',
      'Class 11',
      'Class 12',
    ];

    void addCustomSection(StateSetter setDialogState) {
      final value = newSectionController.text.trim();
      if (value.isEmpty) return;
      setDialogState(() {
        if (!availableSections.any(
          (s) => s.toLowerCase() == value.toLowerCase(),
        )) {
          availableSections.add(value);
        }
        selectedSections.add(
          availableSections.firstWhere(
            (s) => s.toLowerCase() == value.toLowerCase(),
          ),
        );
        newSectionController.clear();
      });
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Class'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: classController,
                      label: 'Class Name',
                      hint: 'e.g. Nursery, Class 1, Grade 10',
                      prefixIcon: Icons.class_outlined,
                      validator: (v) {
                        final trimmed = (v ?? '').trim();
                        if (trimmed.isEmpty) return 'Class name is required';
                        if (existingNames.contains(trimmed.toLowerCase())) {
                          return '$trimmed already exists';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Common Names (tap to fill, edit above if needed)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: quickClasses.map((c) {
                        final alreadyExists =
                            existingNames.contains(c.toLowerCase());
                        return ActionChip(
                          label: Text(c),
                          visualDensity: VisualDensity.compact,
                          onPressed: alreadyExists
                              ? null
                              : () {
                                  classController.text = c;
                                  classController.selection =
                                      TextSelection.collapsed(offset: c.length);
                                },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Sections',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: availableSections.map((sec) {
                        final isSelected = selectedSections.contains(sec);
                        return FilterChip(
                          label: Text('Section $sec'),
                          selected: isSelected,
                          onSelected: (checked) {
                            setDialogState(() {
                              if (checked) {
                                selectedSections.add(sec);
                              } else {
                                selectedSections.remove(sec);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: newSectionController,
                            label: 'Add Custom Section',
                            hint: 'e.g. Rose, Lotus',
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) =>
                                addCustomSection(setDialogState),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.filledTonal(
                          tooltip: 'Add section',
                          onPressed: () => addCustomSection(setDialogState),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
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
              child: const Text('Create Class'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(classesProvider.notifier).createClass(
            name: classController.text.trim(),
            displayOrder: nextOrder,
            initialSections: selectedSections.toList()..sort(),
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Could not create class: $e'),
        ),
      );
    }
  }

  Future<void> _showAddSectionDialog(
    BuildContext context,
    WidgetRef ref,
    SchoolClass schoolClass,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Section to ${schoolClass.name}'),
        content: Form(
          key: formKey,
          child: AppTextField(
            controller: controller,
            label: 'Section Name',
            hint: 'e.g. A, B, Rose',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
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
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(classesProvider.notifier).addSection(
            classId: schoolClass.id,
            name: controller.text.trim(),
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Could not add section: $e'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteClass(
    BuildContext context,
    WidgetRef ref,
    SchoolClass schoolClass,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${schoolClass.name}?'),
        content: const Text(
          'This will also remove all sections inside this class.',
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

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(classesProvider.notifier).deleteClass(schoolClass.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Could not delete class: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return classesAsync.when(
      loading: () => const LoadingView(message: 'Loading classes...'),
      error: (e, _) => ErrorView(
        message: 'Could not load classes: $e',
        onRetry: () => ref.invalidate(classesProvider),
      ),
      data: (classes) {
        final nextOrder = classes.isEmpty
            ? 1
            : classes.map((c) => c.displayOrder).reduce((a, b) => a > b ? a : b) +
                1;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Classes & Sections', style: textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        '${classes.length} classes configured',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Add Classes',
                  icon: Icons.add,
                  onPressed: () =>
                      _showAddClassDialog(context, ref, classes, nextOrder),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (classes.isEmpty)
              EmptyState(
                icon: Icons.class_outlined,
                title: 'No classes yet',
                subtitle: 'Add your first class and sections to get started.',
                actionLabel: 'Add Classes',
                onAction: () => _showAddClassDialog(context, ref, classes, 1),
              )
            else
              ...classes.map(
                (schoolClass) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    schoolClass.name,
                                    style: textTheme.titleMedium,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  StatusChip(
                                    status: StatusType.info,
                                    label:
                                        '${schoolClass.sections.length} sections',
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete class',
                              icon: Icon(
                                Icons.delete_outline,
                                color: colorScheme.error,
                              ),
                              onPressed: () =>
                                  _confirmDeleteClass(context, ref, schoolClass),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...schoolClass.sections.map(
                              (sec) => InputChip(
                                label: Text('Section ${sec.name}'),
                                onDeleted: () async {
                                  try {
                                    await ref
                                        .read(classesProvider.notifier)
                                        .deleteSection(sec.id);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: colorScheme.error,
                                        content: Text(
                                          'Could not delete section: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 18),
                              label: const Text('Add Section'),
                              onPressed: () => _showAddSectionDialog(
                                context,
                                ref,
                                schoolClass,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
