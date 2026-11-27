import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client.dart';
import '../data/subject_model.dart';
import '../data/subjects_repository.dart';

final subjectsRepositoryProvider = Provider<SubjectsRepository>(
  (ref) => SupabaseSubjectsRepository(ref.watch(supabaseProvider)),
);

class SubjectsNotifier extends AsyncNotifier<List<Subject>> {
  @override
  FutureOr<List<Subject>> build() {
    return ref.watch(subjectsRepositoryProvider).fetchSubjects();
  }

  Future<void> createSubject({required String name, String? code}) async {
    final created = await ref
        .read(subjectsRepositoryProvider)
        .createSubject(name: name, code: code);
    final current = state.value ?? const [];
    state = AsyncData(
      [...current, created]..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  Future<void> updateSubject({
    required String id,
    required String name,
    String? code,
  }) async {
    final updated = await ref
        .read(subjectsRepositoryProvider)
        .updateSubject(id: id, name: name, code: code);
    final current = state.value ?? const [];
    state = AsyncData(
      [for (final s in current) s.id == id ? updated : s]
        ..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  Future<void> deleteSubject(String id) async {
    await ref.read(subjectsRepositoryProvider).deleteSubject(id);
    final current = state.value ?? const [];
    state = AsyncData(current.where((s) => s.id != id).toList());
  }
}

final subjectsProvider = AsyncNotifierProvider<SubjectsNotifier, List<Subject>>(
  SubjectsNotifier.new,
);

class SubjectMappingsNotifier
    extends AsyncNotifier<List<SectionSubjectMapping>> {
  @override
  FutureOr<List<SectionSubjectMapping>> build() {
    return ref.watch(subjectsRepositoryProvider).fetchMappingsForCurrentYear();
  }

  Future<void> assignMapping({
    required String sectionId,
    required String subjectId,
    required String teacherProfileId,
  }) async {
    await ref
        .read(subjectsRepositoryProvider)
        .assignMapping(
          sectionId: sectionId,
          subjectId: subjectId,
          teacherProfileId: teacherProfileId,
        );
    state = AsyncData(
      await ref.read(subjectsRepositoryProvider).fetchMappingsForCurrentYear(),
    );
  }

  Future<void> deleteMapping(String mappingId) async {
    await ref.read(subjectsRepositoryProvider).deleteMapping(mappingId);
    final current = state.value ?? const [];
    state = AsyncData(current.where((m) => m.id != mappingId).toList());
  }
}

final subjectMappingsProvider =
    AsyncNotifierProvider<SubjectMappingsNotifier, List<SectionSubjectMapping>>(
      SubjectMappingsNotifier.new,
    );

final teacherOptionsProvider = FutureProvider<List<TeacherOption>>((ref) {
  return ref.watch(subjectsRepositoryProvider).fetchTeacherOptions();
});
