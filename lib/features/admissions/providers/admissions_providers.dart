import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/status_chip.dart';
import '../../students/data/student_model.dart';
import '../../students/providers/students_providers.dart';
import '../data/admission_model.dart';

class AdmissionsNotifier extends Notifier<List<AdmissionEnquiry>> {
  @override
  List<AdmissionEnquiry> build() => const [
    AdmissionEnquiry(
      id: 'enq-1',
      studentName: 'Ishaan Gupta',
      applyingForClass: 'Class 6',
      guardianName: 'Neha Gupta',
      guardianPhone: '+91 98765 11223',
      previousSchool: 'St. Xavier Public School',
      followUpNote: 'Requested campus tour this Friday.',
      status: LeadStatus.newLead,
      dateLabel: 'Today',
      documentsAttached: false,
    ),
    AdmissionEnquiry(
      id: 'enq-2',
      studentName: 'Sara Khan',
      applyingForClass: 'Class 8',
      guardianName: 'Imran Khan',
      guardianPhone: '+91 98123 45678',
      previousSchool: 'Delhi Modern Academy',
      followUpNote: 'Called guardian; birth certificate & TC uploaded.',
      status: LeadStatus.contacted,
      dateLabel: 'Yesterday',
      documentsAttached: true,
    ),
    AdmissionEnquiry(
      id: 'enq-3',
      studentName: 'Vivaan Joshi',
      applyingForClass: 'Class 3',
      guardianName: 'Pooja Joshi',
      guardianPhone: '+91 98234 56789',
      previousSchool: 'Little Steps Primary',
      followUpNote: 'Visited school; ready for admission approval.',
      status: LeadStatus.visited,
      dateLabel: '2 days ago',
      documentsAttached: true,
    ),
    AdmissionEnquiry(
      id: 'enq-4',
      studentName: 'Riya Menon',
      applyingForClass: 'Class 9',
      guardianName: 'Suresh Menon',
      guardianPhone: '+91 98345 67890',
      previousSchool: 'National High School',
      followUpNote: 'Admitted and enrolled in Class 9-A.',
      status: LeadStatus.admitted,
      dateLabel: '5 days ago',
      documentsAttached: true,
    ),
  ];

  void addEnquiry(AdmissionEnquiry enquiry) {
    state = [enquiry, ...state];
  }

  void updateStatus(String id, LeadStatus status) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(status: status) else item,
    ];
  }

  void updateDetails(
    String id, {
    String? followUpNote,
    bool? documentsAttached,
  }) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            followUpNote: followUpNote,
            documentsAttached: documentsAttached,
          )
        else
          item,
    ];
  }

  /// Marks the enquiry as admitted and automatically creates a Student record.
  Future<void> approveAdmission(AdmissionEnquiry enquiry) async {
    updateStatus(enquiry.id, LeadStatus.admitted);

    final parts = enquiry.studentName.trim().split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final now = DateTime.now();

    final student = Student(
      id: 'stu-${now.millisecondsSinceEpoch}',
      admissionNo: 'ADM-2026-${now.millisecond.toString().padLeft(3, '0')}',
      firstName: firstName,
      lastName: lastName,
      className: enquiry.applyingForClass,
      sectionName: 'A',
      rollNo: 1,
      guardianName: enquiry.guardianName,
      guardianPhone: enquiry.guardianPhone,
      attendancePercent: '100%',
      feeStatus: StatusType.pending,
    );

    await ref.read(studentsProvider.notifier).addStudent(student);
  }
}

final admissionsProvider =
    NotifierProvider<AdmissionsNotifier, List<AdmissionEnquiry>>(
  AdmissionsNotifier.new,
);

class AdmissionStatusFilterNotifier extends Notifier<LeadStatus?> {
  @override
  LeadStatus? build() => null;

  void select(LeadStatus? status) => state = status;
}

final admissionStatusFilterProvider =
    NotifierProvider<AdmissionStatusFilterNotifier, LeadStatus?>(
  AdmissionStatusFilterNotifier.new,
);

final filteredAdmissionsProvider = Provider<List<AdmissionEnquiry>>((ref) {
  final list = ref.watch(admissionsProvider);
  final filter = ref.watch(admissionStatusFilterProvider);
  if (filter == null) return list;
  return list.where((e) => e.status == filter).toList();
});
