import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/status_chip.dart';
import 'student_admission_model.dart';
import 'student_model.dart';

abstract interface class StudentsRepository {
  Future<List<Student>> fetchStudents();
  Future<Student> addStudent(Student student);
  Future<Student> createStudentAdmission(StudentAdmissionPayload payload);
  Future<Student> updateStudentAdmission(
    String studentId,
    StudentAdmissionPayload payload,
  );
}

class StubStudentsRepository implements StudentsRepository {
  final List<Student> _students = [
    const Student(
      id: 'stu-1',
      admissionNo: 'ADM-2026-001',
      firstName: 'Aarav',
      lastName: 'Sharma',
      className: 'Class 6',
      sectionName: 'A',
      rollNo: 14,
      guardianName: 'Rajesh Sharma',
      guardianPhone: '+91 98765 43210',
      attendancePercent: '96%',
      feeStatus: StatusType.pending,
    ),
    const Student(
      id: 'stu-2',
      admissionNo: 'ADM-2026-002',
      firstName: 'Ananya',
      lastName: 'Sharma',
      className: 'Class 3',
      sectionName: 'B',
      rollNo: 7,
      guardianName: 'Rajesh Sharma',
      guardianPhone: '+91 98765 43210',
      attendancePercent: '91%',
      feeStatus: StatusType.paid,
    ),
    const Student(
      id: 'stu-3',
      admissionNo: 'ADM-2026-003',
      firstName: 'Rohan',
      lastName: 'Verma',
      className: 'Class 9',
      sectionName: 'A',
      rollNo: 4,
      guardianName: 'Sunita Verma',
      guardianPhone: '+91 98111 22334',
      attendancePercent: '94%',
      feeStatus: StatusType.paid,
    ),
    const Student(
      id: 'stu-4',
      admissionNo: 'ADM-2026-004',
      firstName: 'Meera',
      lastName: 'Nair',
      className: 'Class 8',
      sectionName: 'A',
      rollNo: 11,
      guardianName: 'Vikram Nair',
      guardianPhone: '+91 98222 33445',
      attendancePercent: '89%',
      feeStatus: StatusType.partial,
    ),
    const Student(
      id: 'stu-5',
      admissionNo: 'ADM-2026-005',
      firstName: 'Kabir',
      lastName: 'Patel',
      className: 'Class 8',
      sectionName: 'A',
      rollNo: 18,
      guardianName: 'Amit Patel',
      guardianPhone: '+91 98333 44556',
      attendancePercent: '82%',
      feeStatus: StatusType.overdue,
    ),
    const Student(
      id: 'stu-6',
      admissionNo: 'ADM-2026-006',
      firstName: 'Diya',
      lastName: 'Kulkarni',
      className: 'Class 9',
      sectionName: 'B',
      rollNo: 2,
      guardianName: 'Sneha Kulkarni',
      guardianPhone: '+91 98444 55667',
      attendancePercent: '98%',
      feeStatus: StatusType.paid,
    ),
  ];

  @override
  Future<List<Student>> fetchStudents() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_students);
  }

  @override
  Future<Student> addStudent(Student student) async {
    _students.insert(0, student);
    return student;
  }

  @override
  Future<Student> createStudentAdmission(
    StudentAdmissionPayload payload,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final nextSeq = (_students.length + 1).toString().padLeft(3, '0');
    final primaryGuardian = payload.effectivePrimaryGuardian;
    final student = Student(
      id: 'stu-${DateTime.now().millisecondsSinceEpoch}',
      admissionNo: 'ADM-${payload.admissionDate.year}-$nextSeq',
      firstName: payload.firstName.trim(),
      lastName: payload.lastName.trim(),
      className: payload.className ?? 'Class 1',
      sectionName: payload.sectionName ?? 'A',
      rollNo: int.tryParse(payload.rollNumber.trim()) ?? 1,
      guardianName: primaryGuardian.name.trim(),
      guardianPhone: '+91 ${primaryGuardian.phone.trim()}',
      attendancePercent: '100%',
      feeStatus: StatusType.pending,
      admissionDetails: payload,
    );
    _students.insert(0, student);
    return student;
  }

  @override
  Future<Student> updateStudentAdmission(
    String studentId,
    StudentAdmissionPayload payload,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _students.indexWhere((s) => s.id == studentId);
    final existing = index >= 0 ? _students[index] : null;
    final primaryGuardian = payload.effectivePrimaryGuardian;
    final phone = primaryGuardian.phone.trim();
    final updated = Student(
      id: studentId,
      admissionNo: existing?.admissionNo ?? payload.admissionNumber,
      firstName: payload.firstName.trim(),
      lastName: payload.lastName.trim(),
      className: payload.className ?? existing?.className ?? 'Class 1',
      sectionName: payload.sectionName ?? existing?.sectionName ?? 'A',
      rollNo: int.tryParse(payload.rollNumber.trim()) ?? existing?.rollNo ?? 1,
      guardianName: primaryGuardian.name.trim(),
      guardianPhone: phone.startsWith('+') ? phone : '+91 $phone',
      attendancePercent: existing?.attendancePercent ?? '100%',
      feeStatus: existing?.feeStatus ?? StatusType.pending,
      admissionDetails: payload,
    );
    if (index >= 0) {
      _students[index] = updated;
    }
    return updated;
  }
}

/// Production implementation backed by Supabase RPC & tables.
class SupabaseStudentsRepository implements StudentsRepository {
  SupabaseStudentsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Student>> fetchStudents() async {
    final rows = await _client
        .from('students')
        .select(
          'id, admission_number, first_name, last_name, '
          'student_enrollments(roll_number, classes(name), sections(name)), '
          'student_parents(is_primary, guardians(name, phone))',
        )
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).map((raw) {
      final row = raw as Map<String, dynamic>;
      final enrollments = (row['student_enrollments'] as List<dynamic>?) ?? [];
      final enrollment = enrollments.isNotEmpty
          ? enrollments.first as Map<String, dynamic>
          : const <String, dynamic>{};
      final parents = (row['student_parents'] as List<dynamic>?) ?? [];
      final primaryParent = parents.cast<Map<String, dynamic>>().firstWhere(
            (p) => p['is_primary'] == true,
            orElse: () => parents.isNotEmpty
                ? parents.first as Map<String, dynamic>
                : const <String, dynamic>{},
          );
      final guardian =
          (primaryParent['guardians'] as Map<String, dynamic>?) ?? const {};

      return Student(
        id: row['id'] as String,
        admissionNo: (row['admission_number'] as String?) ?? '',
        firstName: (row['first_name'] as String?) ?? '',
        lastName: (row['last_name'] as String?) ?? '',
        className:
            ((enrollment['classes'] as Map<String, dynamic>?)?['name']
                as String?) ??
            '',
        sectionName:
            ((enrollment['sections'] as Map<String, dynamic>?)?['name']
                as String?) ??
            '',
        rollNo: (enrollment['roll_number'] as int?) ?? 0,
        guardianName: (guardian['name'] as String?) ?? '',
        guardianPhone: (guardian['phone'] as String?) ?? '',
        attendancePercent: '100%',
        feeStatus: StatusType.pending,
      );
    }).toList();
  }

  @override
  Future<Student> addStudent(Student student) async {
    throw UnimplementedError('Use createStudentAdmission instead.');
  }

  @override
  Future<Student> createStudentAdmission(
    StudentAdmissionPayload payload,
  ) async {
    final result = await _client.rpc<Map<String, dynamic>>(
      'create_student_admission',
      params: {'payload': payload.toJson()},
    );

    final primaryGuardian = payload.effectivePrimaryGuardian;
    return Student(
      id: result['student_id'] as String,
      admissionNo: result['admission_number'] as String,
      firstName: payload.firstName.trim(),
      lastName: payload.lastName.trim(),
      className: payload.className ?? '',
      sectionName: payload.sectionName ?? '',
      rollNo: int.tryParse(payload.rollNumber.trim()) ?? 0,
      guardianName: primaryGuardian.name.trim(),
      guardianPhone: primaryGuardian.phone.trim(),
      attendancePercent: '100%',
      feeStatus: StatusType.pending,
      admissionDetails: payload,
    );
  }

  @override
  Future<Student> updateStudentAdmission(
    String studentId,
    StudentAdmissionPayload payload,
  ) async {
    final result = await _client.rpc<Map<String, dynamic>>(
      'update_student_admission',
      params: {'p_student_id': studentId, 'payload': payload.toJson()},
    );

    final primaryGuardian = payload.effectivePrimaryGuardian;
    return Student(
      id: studentId,
      admissionNo:
          (result['admission_number'] as String?) ?? payload.admissionNumber,
      firstName: payload.firstName.trim(),
      lastName: payload.lastName.trim(),
      className: payload.className ?? '',
      sectionName: payload.sectionName ?? '',
      rollNo: int.tryParse(payload.rollNumber.trim()) ?? 0,
      guardianName: primaryGuardian.name.trim(),
      guardianPhone: primaryGuardian.phone.trim(),
      attendancePercent: '100%',
      feeStatus: StatusType.pending,
      admissionDetails: payload,
    );
  }
}
