import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client.dart';
import '../data/class_model.dart';
import '../data/classes_repository.dart';

final classesRepositoryProvider = Provider<ClassesRepository>(
  (ref) => SupabaseClassesRepository(ref.watch(supabaseProvider)),
);

class ClassesNotifier extends AsyncNotifier<List<SchoolClass>> {
  @override
  FutureOr<List<SchoolClass>> build() {
    return ref.watch(classesRepositoryProvider).fetchClasses();
  }

  Future<void> createClass({
    required String name,
    required int displayOrder,
    List<String> initialSections = const [],
  }) async {
    final created = await ref
        .read(classesRepositoryProvider)
        .createClass(
          name: name,
          displayOrder: displayOrder,
          initialSections: initialSections,
        );
    final current = state.value ?? const [];
    state = AsyncData([...current, created]);
  }

  Future<void> createClasses({
    required List<String> names,
    required int startingOrder,
    List<String> initialSections = const [],
  }) async {
    await ref
        .read(classesRepositoryProvider)
        .createClasses(
          names: names,
          startingOrder: startingOrder,
          initialSections: initialSections,
        );
    state = AsyncData(await ref.read(classesRepositoryProvider).fetchClasses());
  }

  Future<void> deleteClass(String classId) async {
    await ref.read(classesRepositoryProvider).deleteClass(classId);
    final current = state.value ?? const [];
    state = AsyncData(current.where((c) => c.id != classId).toList());
  }

  Future<void> addSection({
    required String classId,
    required String name,
  }) async {
    final created = await ref
        .read(classesRepositoryProvider)
        .addSection(classId: classId, name: name);
    final current = state.value ?? const [];
    state = AsyncData([
      for (final c in current)
        if (c.id == classId)
          c.copyWith(
            sections: [...c.sections, created]
              ..sort((a, b) => a.name.compareTo(b.name)),
          )
        else
          c,
    ]);
  }

  Future<void> deleteSection(String sectionId) async {
    await ref.read(classesRepositoryProvider).deleteSection(sectionId);
    final current = state.value ?? const [];
    state = AsyncData([
      for (final c in current)
        c.copyWith(
          sections: c.sections.where((s) => s.id != sectionId).toList(),
        ),
    ]);
  }
}

final classesProvider =
    AsyncNotifierProvider<ClassesNotifier, List<SchoolClass>>(
      ClassesNotifier.new,
    );
