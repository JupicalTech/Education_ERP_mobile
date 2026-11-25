import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_model.dart';
import '../data/students_repository.dart';

final studentsRepositoryProvider = Provider<StudentsRepository>(
  (ref) => StubStudentsRepository(),
);

class StudentsNotifier extends AsyncNotifier<List<Student>> {
  @override
  FutureOr<List<Student>> build() {
    return ref.watch(studentsRepositoryProvider).fetchStudents();
  }

  Future<void> addStudent(Student student) async {
    final added = await ref
        .read(studentsRepositoryProvider)
        .addStudent(student);
    final current = state.value ?? [];
    state = AsyncData([added, ...current]);
  }
}

final studentsProvider = AsyncNotifierProvider<StudentsNotifier, List<Student>>(
  StudentsNotifier.new,
);

class StudentSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

final studentSearchQueryProvider =
    NotifierProvider<StudentSearchNotifier, String>(
  StudentSearchNotifier.new,
);

class ClassFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? className) => state = className;
}

final selectedClassFilterProvider =
    NotifierProvider<ClassFilterNotifier, String?>(
  ClassFilterNotifier.new,
);

final filteredStudentsProvider = Provider<AsyncValue<List<Student>>>((ref) {
  final studentsAsync = ref.watch(studentsProvider);
  final query = ref.watch(studentSearchQueryProvider).trim().toLowerCase();
  final classFilter = ref.watch(selectedClassFilterProvider);

  return studentsAsync.whenData((students) {
    return students.where((s) {
      final matchesClass = classFilter == null || s.className == classFilter;
      final matchesQuery =
          query.isEmpty ||
          s.fullName.toLowerCase().contains(query) ||
          s.admissionNo.toLowerCase().contains(query);
      return matchesClass && matchesQuery;
    }).toList();
  });
});
