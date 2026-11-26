import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../../core/network/supabase_client.dart';
import '../data/teacher_model.dart';
import '../data/teachers_repository.dart';

final teachersRepositoryProvider = Provider<TeachersRepository>(
  (ref) => StubTeachersRepository(),
);

// Ready to swap in when SQL migration is run:
// final teachersRepositoryProvider = Provider<TeachersRepository>(
//   (ref) => SupabaseTeachersRepository(ref.watch(supabaseProvider)),
// );

class TeachersNotifier extends AsyncNotifier<List<Teacher>> {
  @override
  FutureOr<List<Teacher>> build() {
    return ref.watch(teachersRepositoryProvider).fetchTeachers();
  }

  Future<Teacher> createTeacher(Teacher draft) async {
    final created = await ref
        .read(teachersRepositoryProvider)
        .createTeacher(draft);
    // Re-fetch so single-class-teacher updates across existing rows stay in sync
    final refreshed = await ref.read(teachersRepositoryProvider).fetchTeachers();
    state = AsyncData(refreshed);
    return created;
  }

  Future<Teacher> updateTeacher(String teacherId, Teacher updated) async {
    final saved = await ref
        .read(teachersRepositoryProvider)
        .updateTeacher(teacherId, updated);
    final refreshed = await ref.read(teachersRepositoryProvider).fetchTeachers();
    state = AsyncData(refreshed);
    return saved;
  }

  Future<Teacher> setTeacherActive(String teacherId, bool isActive) async {
    final updated = await ref
        .read(teachersRepositoryProvider)
        .setTeacherActive(teacherId, isActive);
    final current = state.value ?? [];
    state = AsyncData(
      current.map((t) => t.id == teacherId ? updated : t).toList(),
    );
    return updated;
  }
}

final teachersProvider =
    AsyncNotifierProvider<TeachersNotifier, List<Teacher>>(
      TeachersNotifier.new,
    );

// --- Search & Filters ---

class _StringNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setValue(String value) => state = value;
}

class _NullableStringNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? value) => state = value;
}

class _TeacherStatusFilterNotifier extends Notifier<TeacherStatus?> {
  @override
  TeacherStatus? build() => null;
  void select(TeacherStatus? value) => state = value;
}

class _EmploymentTypeFilterNotifier extends Notifier<EmploymentType?> {
  @override
  EmploymentType? build() => null;
  void select(EmploymentType? value) => state = value;
}

final teacherSearchQueryProvider = NotifierProvider<_StringNotifier, String>(
  _StringNotifier.new,
);

final teacherSubjectFilterProvider =
    NotifierProvider<_NullableStringNotifier, String?>(
      _NullableStringNotifier.new,
    );

final teacherClassFilterProvider =
    NotifierProvider<_NullableStringNotifier, String?>(
      _NullableStringNotifier.new,
    );

final teacherStatusFilterProvider =
    NotifierProvider<_TeacherStatusFilterNotifier, TeacherStatus?>(
      _TeacherStatusFilterNotifier.new,
    );

final teacherEmploymentTypeFilterProvider =
    NotifierProvider<_EmploymentTypeFilterNotifier, EmploymentType?>(
      _EmploymentTypeFilterNotifier.new,
    );

final filteredTeachersProvider = Provider<AsyncValue<List<Teacher>>>((ref) {
  final teachersAsync = ref.watch(teachersProvider);
  final query = ref.watch(teacherSearchQueryProvider).trim().toLowerCase();
  final subjectFilter = ref.watch(teacherSubjectFilterProvider);
  final classFilter = ref.watch(teacherClassFilterProvider);
  final statusFilter = ref.watch(teacherStatusFilterProvider);
  final empTypeFilter = ref.watch(teacherEmploymentTypeFilterProvider);

  return teachersAsync.whenData((teachers) {
    return teachers.where((t) {
      if (query.isNotEmpty) {
        final matchesName = t.fullName.toLowerCase().contains(query);
        final matchesEmpId = t.employeeId.toLowerCase().contains(query);
        final matchesPhone = (t.phone ?? '').toLowerCase().contains(query);
        if (!matchesName && !matchesEmpId && !matchesPhone) return false;
      }
      if (subjectFilter != null) {
        final hasSubject =
            t.teachableSubjects.contains(subjectFilter) ||
            t.assignments.any((a) => a.subject == subjectFilter);
        if (!hasSubject) return false;
      }
      if (classFilter != null) {
        final hasClass =
            t.assignments.any((a) => a.className == classFilter) ||
            (t.classTeacherSection?.startsWith(classFilter) ?? false);
        if (!hasClass) return false;
      }
      if (statusFilter != null && t.status != statusFilter) {
        return false;
      }
      if (empTypeFilter != null && t.employmentType != empTypeFilter) {
        return false;
      }
      return true;
    }).toList();
  });
});

class TeacherStats {
  const TeacherStats({
    required this.total,
    required this.active,
    required this.onLeave,
    required this.classTeachers,
  });

  final int total;
  final int active;
  final int onLeave;
  final int classTeachers;
}

final teacherStatsProvider = Provider<TeacherStats>((ref) {
  final teachers = ref.watch(teachersProvider).value ?? const [];
  return TeacherStats(
    total: teachers.length,
    active: teachers.where((t) => t.status == TeacherStatus.active).length,
    onLeave: teachers.where((t) => t.status == TeacherStatus.onLeave).length,
    classTeachers: teachers
        .where(
          (t) =>
              t.classTeacherSection != null &&
              t.classTeacherSection!.isNotEmpty,
        )
        .length,
  );
});

// --- Multi-step Add / Edit Teacher Form State ---

class TeacherFormState {
  const TeacherFormState({
    this.currentStep = 0,
    this.isSubmitting = false,
    this.error,
    this.editingTeacherId,
    this.sameAsCurrentAddress = false,
    required this.draft,
  });

  final int currentStep;
  final bool isSubmitting;
  final String? error;
  final String? editingTeacherId;
  final bool sameAsCurrentAddress;
  final Teacher draft;

  bool get isEditing => editingTeacherId != null;

  TeacherFormState copyWith({
    int? currentStep,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    String? editingTeacherId,
    bool clearEditingId = false,
    bool? sameAsCurrentAddress,
    Teacher? draft,
  }) {
    return TeacherFormState(
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      editingTeacherId: clearEditingId
          ? null
          : (editingTeacherId ?? this.editingTeacherId),
      sameAsCurrentAddress: sameAsCurrentAddress ?? this.sameAsCurrentAddress,
      draft: draft ?? this.draft,
    );
  }
}

class TeacherFormNotifier extends Notifier<TeacherFormState> {
  static const totalSteps = 7;

  @override
  TeacherFormState build() {
    return TeacherFormState(draft: _emptyDraft());
  }

  Teacher _emptyDraft() => Teacher(
    id: '',
    profileId: '',
    instituteId: 'inst-1',
    employeeId: 'Auto-generated on save',
    firstName: '',
    lastName: '',
    email: '',
    designation: 'TGT',
    joiningDate: DateTime.now(),
    bankDetails: const TeacherBankDetails(),
  );

  void reset() {
    state = TeacherFormState(draft: _emptyDraft());
  }

  void initForEdit(Teacher teacher) {
    final sameAddr =
        teacher.currentAddress != null &&
        teacher.currentAddress == teacher.permanentAddress;
    state = TeacherFormState(
      currentStep: 0,
      editingTeacherId: teacher.id,
      sameAsCurrentAddress: sameAddr,
      draft: teacher.copyWith(
        bankDetails: teacher.bankDetails ?? const TeacherBankDetails(),
      ),
    );
  }

  void goToStep(int step) {
    if (step < 0 || step >= totalSteps) return;
    state = state.copyWith(currentStep: step, clearError: true);
  }

  void nextStep() {
    if (state.currentStep < totalSteps - 1) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        clearError: true,
      );
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        clearError: true,
      );
    }
  }

  void updateDraft(Teacher Function(Teacher current) updater) {
    state = state.copyWith(draft: updater(state.draft), clearError: true);
  }

  void setSameAsCurrentAddress(bool value) {
    state = state.copyWith(
      sameAsCurrentAddress: value,
      draft: value
          ? state.draft.copyWith(permanentAddress: state.draft.currentAddress)
          : state.draft,
    );
  }

  void addQualification(TeacherQualification q) {
    updateDraft((d) => d.copyWith(qualifications: [...d.qualifications, q]));
  }

  void removeQualification(int index) {
    updateDraft((d) {
      final list = [...d.qualifications]..removeAt(index);
      return d.copyWith(qualifications: list);
    });
  }

  void addExperience(TeacherExperience e) {
    updateDraft((d) => d.copyWith(experiences: [...d.experiences, e]));
  }

  void removeExperience(int index) {
    updateDraft((d) {
      final list = [...d.experiences]..removeAt(index);
      return d.copyWith(experiences: list);
    });
  }

  void toggleTeachableSubject(String subject) {
    updateDraft((d) {
      final list = [...d.teachableSubjects];
      if (list.contains(subject)) {
        list.remove(subject);
      } else {
        list.add(subject);
      }
      return d.copyWith(teachableSubjects: list);
    });
  }

  void addAssignment(TeacherAssignment a) {
    updateDraft((d) => d.copyWith(assignments: [...d.assignments, a]));
  }

  void removeAssignment(int index) {
    updateDraft((d) {
      final list = [...d.assignments]..removeAt(index);
      return d.copyWith(assignments: list);
    });
  }

  void setDocument(String docType, String fileName) {
    updateDraft((d) {
      final list = d.documents.where((doc) => doc.docType != docType).toList();
      list.add(
        TeacherDocument(
          docType: docType,
          fileName: fileName,
          fileUrl: 'stub://teachers/$docType/$fileName',
        ),
      );
      return d.copyWith(documents: list);
    });
  }

  void removeDocument(String docType) {
    updateDraft((d) {
      final list = d.documents.where((doc) => doc.docType != docType).toList();
      return d.copyWith(documents: list);
    });
  }

  Future<Teacher?> submit() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final notifier = ref.read(teachersProvider.notifier);
      final saved = state.isEditing
          ? await notifier.updateTeacher(state.editingTeacherId!, state.draft)
          : await notifier.createTeacher(state.draft);
      state = state.copyWith(isSubmitting: false);
      return saved;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return null;
    }
  }
}

final teacherFormProvider =
    NotifierProvider<TeacherFormNotifier, TeacherFormState>(
      TeacherFormNotifier.new,
    );
