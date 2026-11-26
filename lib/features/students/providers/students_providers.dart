import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_admission_model.dart';
import '../data/student_model.dart';
import '../data/students_repository.dart';

final studentsRepositoryProvider = Provider<StudentsRepository>(
  (ref) => StubStudentsRepository(),
);

// Ready to swap in when SQL migration is run:
// final studentsRepositoryProvider = Provider<StudentsRepository>(
//   (ref) => SupabaseStudentsRepository(ref.watch(supabaseProvider)),
// );

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

  Future<Student> createAdmission(StudentAdmissionPayload payload) async {
    final created = await ref
        .read(studentsRepositoryProvider)
        .createStudentAdmission(payload);
    final current = state.value ?? [];
    state = AsyncData([created, ...current]);
    return created;
  }

  Future<Student> updateAdmission(
    String studentId,
    StudentAdmissionPayload payload,
  ) async {
    final updated = await ref
        .read(studentsRepositoryProvider)
        .updateStudentAdmission(studentId, payload);
    final current = state.value ?? [];
    state = AsyncData(
      current.map((s) => s.id == studentId ? updated : s).toList(),
    );
    return updated;
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

@immutable
class AdmissionFormState {
  const AdmissionFormState({
    required this.currentStep,
    required this.payload,
    this.editingStudentId,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final int currentStep;
  final StudentAdmissionPayload payload;
  final String? editingStudentId;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isEditing => editingStudentId != null;

  AdmissionFormState copyWith({
    int? currentStep,
    StudentAdmissionPayload? payload,
    String? editingStudentId,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdmissionFormState(
      currentStep: currentStep ?? this.currentStep,
      payload: payload ?? this.payload,
      editingStudentId: editingStudentId ?? this.editingStudentId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class StudentAdmissionNotifier extends Notifier<AdmissionFormState> {
  static const int totalSteps = 8; // 7 sections + final review

  @override
  AdmissionFormState build() {
    final now = DateTime.now();
    return AdmissionFormState(
      currentStep: 0,
      payload: StudentAdmissionPayload(
        admissionDate: now,
        documents: DocumentType.values
            .map((type) => StudentDocumentInput(docType: type))
            .toList(),
      ),
    );
  }

  void updatePayload(
    StudentAdmissionPayload Function(StudentAdmissionPayload current) updater,
  ) {
    state = state.copyWith(
      payload: updater(state.payload),
      clearError: true,
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

  void addPreviousSchool() {
    updatePayload(
      (p) => p.copyWith(
        previousSchools: [...p.previousSchools, const PreviousSchoolInput()],
      ),
    );
  }

  void removePreviousSchool(int index) {
    if (state.payload.previousSchools.length <= 1) return;
    final updated = [...state.payload.previousSchools]..removeAt(index);
    updatePayload((p) => p.copyWith(previousSchools: updated));
  }

  void updatePreviousSchool(
    int index,
    PreviousSchoolInput Function(PreviousSchoolInput current) updater,
  ) {
    final updated = [...state.payload.previousSchools];
    updated[index] = updater(updated[index]);
    updatePayload((p) => p.copyWith(previousSchools: updated));
  }

  void toggleSibling(String studentId) {
    final current = state.payload.siblingIds;
    final updated = current.contains(studentId)
        ? current.where((id) => id != studentId).toList()
        : [...current, studentId];
    updatePayload((p) => p.copyWith(siblingIds: updated));
  }

  void stubUploadDocument(DocumentType type) {
    final stubName =
        '${type.dbValue}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final stubUrl = 'stub://student-documents/$stubName';
    final updated = state.payload.documents.map((doc) {
      if (doc.docType != type) return doc;
      return doc.copyWith(fileName: stubName, fileUrl: stubUrl);
    }).toList();
    updatePayload((p) => p.copyWith(documents: updated));
  }

  void clearDocument(DocumentType type) {
    final updated = state.payload.documents.map((doc) {
      if (doc.docType != type) return doc;
      return doc.copyWith(clear: true);
    }).toList();
    updatePayload((p) => p.copyWith(documents: updated));
  }

  /// Only First Name and Last Name are validated on the form.
  String? validateStepExtra(int step) => null;

  void initForEdit(Student student) {
    final existing = student.admissionDetails;
    final cleanPhone = student.guardianPhone.replaceAll(RegExp(r'^\+91\s*'), '').replaceAll(RegExp(r'\s+'), '');
    final initialPayload = existing != null
        ? existing.copyWith(admissionNumber: student.admissionNo)
        : StudentAdmissionPayload(
            firstName: student.firstName,
            lastName: student.lastName,
            admissionNumber: student.admissionNo,
            admissionDate: DateTime.now(),
            className: student.className,
            sectionName: student.sectionName,
            rollNumber: '${student.rollNo}',
            father: GuardianInput(
              name: student.guardianName,
              phone: cleanPhone,
              relationship: 'Father',
              isPrimary: true,
            ),
            documents: DocumentType.values
                .map((type) => StudentDocumentInput(docType: type))
                .toList(),
          );
    state = AdmissionFormState(
      currentStep: 0,
      payload: initialPayload,
      editingStudentId: student.id,
    );
  }

  Future<Student?> submit() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final studentsNotifier = ref.read(studentsProvider.notifier);
      final result = state.isEditing
          ? await studentsNotifier.updateAdmission(
              state.editingStudentId!,
              state.payload,
            )
          : await studentsNotifier.createAdmission(state.payload);
      state = state.copyWith(isSubmitting: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
}

final studentAdmissionProvider =
    NotifierProvider.autoDispose<StudentAdmissionNotifier, AdmissionFormState>(
  StudentAdmissionNotifier.new,
);
