import 'package:supabase_flutter/supabase_flutter.dart';

import 'teacher_model.dart';

abstract interface class TeachersRepository {
  Future<List<Teacher>> fetchTeachers();
  Future<Teacher> createTeacher(Teacher draft);
  Future<Teacher> updateTeacher(String teacherId, Teacher updated);
  Future<Teacher> setTeacherActive(String teacherId, bool isActive);
}

class StubTeachersRepository implements TeachersRepository {
  final List<Teacher> _teachers = [
    Teacher(
      id: 'tch-1',
      profileId: 'prof-tch-1',
      instituteId: 'inst-1',
      employeeId: 'EMP-2024-001',
      firstName: 'Anjali',
      lastName: 'Deshmukh',
      dateOfBirth: DateTime(1986, 5, 14),
      gender: 'Female',
      bloodGroup: 'O+',
      maritalStatus: 'Married',
      phone: '+91 98201 11223',
      email: 'anjali.deshmukh@school.edu',
      currentAddress: '42 Green Park, Sector 4',
      permanentAddress: '42 Green Park, Sector 4',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411001',
      emergencyContactName: 'Ramesh Deshmukh',
      emergencyContactPhone: '+91 98201 99887',
      emergencyContactRelationship: 'Spouse',
      designation: 'PGT',
      department: 'Science',
      employmentType: EmploymentType.fullTime,
      joiningDate: DateTime(2020, 6, 1),
      reportingToName: 'Dr. Kavita Rao (Principal)',
      status: TeacherStatus.active,
      teachingLicenseNumber: 'CTET-2018-88421',
      teachableSubjects: const ['Physics', 'Mathematics'],
      assignments: const [
        TeacherAssignment(
          className: 'Class 9',
          sectionName: 'A',
          subject: 'Physics',
        ),
        TeacherAssignment(
          className: 'Class 10',
          sectionName: 'A',
          subject: 'Physics',
        ),
      ],
      classTeacherSection: 'Class 9-A',
      qualifications: const [
        TeacherQualification(
          degree: 'M.Sc.',
          specialization: 'Physics',
          institution: 'Pune University',
          yearOfPassing: '2009',
          percentageOrGrade: '78%',
        ),
        TeacherQualification(
          degree: 'B.Ed.',
          specialization: 'Science & Maths',
          institution: 'SPPU',
          yearOfPassing: '2011',
          percentageOrGrade: '81%',
        ),
      ],
      experiences: [
        TeacherExperience(
          organization: 'Delhi Public School',
          designation: 'TGT Science',
          fromDate: DateTime(2012, 6, 1),
          toDate: DateTime(2020, 4, 30),
          reasonForLeaving: 'Relocation',
        ),
      ],
      bankDetails: const TeacherBankDetails(
        basicSalary: 52000,
        allowances: 12000,
        deductions: 4200,
        bankName: 'HDFC Bank',
        accountNumber: '50100234567891',
        ifscCode: 'HDFC0001234',
        accountHolderName: 'Anjali Deshmukh',
        pfNumber: 'MH/PUN/0045123',
      ),
      documents: const [
        TeacherDocument(
          docType: 'ID Proof',
          fileName: 'aadhaar_anjali.pdf',
          fileUrl: 'stub://id_proof',
        ),
        TeacherDocument(
          docType: 'Degree Certificates',
          fileName: 'msc_bed_certs.pdf',
          fileUrl: 'stub://degree',
        ),
      ],
    ),
    Teacher(
      id: 'tch-2',
      profileId: 'prof-tch-2',
      instituteId: 'inst-1',
      employeeId: 'EMP-2024-002',
      firstName: 'Suresh',
      lastName: 'Menon',
      dateOfBirth: DateTime(1982, 11, 20),
      gender: 'Male',
      bloodGroup: 'B+',
      phone: '+91 98450 22334',
      email: 'suresh.menon@school.edu',
      city: 'Pune',
      state: 'Maharashtra',
      designation: 'TGT',
      department: 'Mathematics',
      employmentType: EmploymentType.fullTime,
      joiningDate: DateTime(2019, 4, 15),
      status: TeacherStatus.active,
      teachingLicenseNumber: 'TET-MH-55190',
      teachableSubjects: const ['Mathematics'],
      assignments: const [
        TeacherAssignment(
          className: 'Class 8',
          sectionName: 'A',
          subject: 'Mathematics',
        ),
        TeacherAssignment(
          className: 'Class 6',
          sectionName: 'A',
          subject: 'Mathematics',
        ),
      ],
      classTeacherSection: 'Class 8-A',
      qualifications: const [
        TeacherQualification(
          degree: 'B.Sc.',
          specialization: 'Mathematics',
          institution: 'Mumbai University',
          yearOfPassing: '2004',
          percentageOrGrade: '74%',
        ),
      ],
      experiences: [
        TeacherExperience(
          organization: 'St. Xavier High School',
          designation: 'PRT Maths',
          fromDate: DateTime(2010, 7, 1),
          toDate: DateTime(2019, 3, 31),
        ),
      ],
      bankDetails: const TeacherBankDetails(
        basicSalary: 46000,
        allowances: 9500,
        deductions: 3600,
        bankName: 'ICICI Bank',
        accountNumber: '002301567890',
        ifscCode: 'ICIC0000023',
        accountHolderName: 'Suresh Menon',
      ),
    ),
    Teacher(
      id: 'tch-3',
      profileId: 'prof-tch-3',
      instituteId: 'inst-1',
      employeeId: 'EMP-2025-003',
      firstName: 'Priya',
      lastName: 'Kulkarni',
      dateOfBirth: DateTime(1992, 2, 8),
      gender: 'Female',
      bloodGroup: 'A+',
      phone: '+91 97654 33445',
      email: 'priya.kulkarni@school.edu',
      designation: 'PRT',
      department: 'Languages',
      employmentType: EmploymentType.fullTime,
      joiningDate: DateTime(2023, 7, 1),
      status: TeacherStatus.onLeave,
      teachableSubjects: const ['English', 'Social Studies'],
      assignments: const [
        TeacherAssignment(
          className: 'Class 3',
          sectionName: 'B',
          subject: 'English',
        ),
      ],
      classTeacherSection: 'Class 3-B',
      bankDetails: const TeacherBankDetails(
        basicSalary: 35000,
        allowances: 6000,
        deductions: 2500,
        bankName: 'SBI',
        accountNumber: '30987654321',
        ifscCode: 'SBIN0001122',
        accountHolderName: 'Priya Kulkarni',
      ),
    ),
    Teacher(
      id: 'tch-4',
      profileId: 'prof-tch-4',
      instituteId: 'inst-1',
      employeeId: 'EMP-2025-004',
      firstName: 'Vikram',
      lastName: 'Joshi',
      gender: 'Male',
      phone: '+91 98901 44556',
      email: 'vikram.joshi@school.edu',
      designation: 'Lab Assistant',
      department: 'Computer Science',
      employmentType: EmploymentType.contract,
      joiningDate: DateTime(2025, 1, 10),
      status: TeacherStatus.active,
      teachableSubjects: const ['Computer Science'],
      assignments: const [
        TeacherAssignment(
          className: 'Class 9',
          sectionName: 'B',
          subject: 'Computer Science',
        ),
      ],
    ),
    Teacher(
      id: 'tch-5',
      profileId: 'prof-tch-5',
      instituteId: 'inst-1',
      employeeId: 'EMP-2023-005',
      firstName: 'Meenakshi',
      lastName: 'Iyer',
      gender: 'Female',
      phone: '+91 98123 55667',
      email: 'meenakshi.iyer@school.edu',
      designation: 'PGT',
      department: 'Humanities',
      employmentType: EmploymentType.partTime,
      joiningDate: DateTime(2022, 8, 1),
      status: TeacherStatus.inactive,
      isActive: false,
      teachableSubjects: const ['History', 'English'],
      assignments: const [],
    ),
  ];

  @override
  Future<List<Teacher>> fetchTeachers() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_teachers);
  }

  @override
  Future<Teacher> createTeacher(Teacher draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final seq = (_teachers.length + 1).toString().padLeft(3, '0');
    final empId = 'EMP-${DateTime.now().year}-$seq';
    final created = draft.copyWith(
      id: 'tch-${DateTime.now().millisecondsSinceEpoch}',
      profileId: 'prof-${DateTime.now().millisecondsSinceEpoch}',
      employeeId: empId,
    );

    // Enforce single class teacher per section
    if (created.classTeacherSection != null) {
      for (var i = 0; i < _teachers.length; i++) {
        if (_teachers[i].classTeacherSection == created.classTeacherSection) {
          _teachers[i] = _teachers[i].copyWith(clearClassTeacher: true);
        }
      }
    }

    _teachers.insert(0, created);
    return created;
  }

  @override
  Future<Teacher> updateTeacher(String teacherId, Teacher updated) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final index = _teachers.indexWhere((t) => t.id == teacherId);
    if (index == -1) {
      throw StateError('Teacher $teacherId not found');
    }

    // Enforce single class teacher per section
    if (updated.classTeacherSection != null) {
      for (var i = 0; i < _teachers.length; i++) {
        if (i != index &&
            _teachers[i].classTeacherSection == updated.classTeacherSection) {
          _teachers[i] = _teachers[i].copyWith(clearClassTeacher: true);
        }
      }
    }

    _teachers[index] = updated;
    return updated;
  }

  @override
  Future<Teacher> setTeacherActive(String teacherId, bool isActive) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final index = _teachers.indexWhere((t) => t.id == teacherId);
    if (index == -1) {
      throw StateError('Teacher $teacherId not found');
    }
    final next = _teachers[index].copyWith(
      isActive: isActive,
      status: isActive ? TeacherStatus.active : TeacherStatus.inactive,
    );
    _teachers[index] = next;
    return next;
  }
}

class SupabaseTeachersRepository implements TeachersRepository {
  SupabaseTeachersRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Teacher>> fetchTeachers() async {
    final rows = await _client
        .from('teachers')
        .select('*, profiles!teachers_profile_id_fkey(*)')
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((row) => Teacher.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Teacher> createTeacher(Teacher draft) async {
    final teacherId = await _client.rpc<String>(
      'create_teacher',
      params: {'payload': draft.toRpcPayload()},
    );

    final row = await _client
        .from('teachers')
        .select('*, profiles!teachers_profile_id_fkey(*)')
        .eq('id', teacherId)
        .single();

    return Teacher.fromJson(row);
  }

  @override
  Future<Teacher> updateTeacher(String teacherId, Teacher updated) async {
    await _client.rpc<String>(
      'update_teacher',
      params: {'p_teacher_id': teacherId, 'payload': updated.toRpcPayload()},
    );

    final row = await _client
        .from('teachers')
        .select('*, profiles!teachers_profile_id_fkey(*)')
        .eq('id', teacherId)
        .single();
    return Teacher.fromJson(row);
  }

  @override
  Future<Teacher> setTeacherActive(String teacherId, bool isActive) async {
    await _client.rpc<void>(
      'set_teacher_active',
      params: {'p_teacher_id': teacherId, 'p_is_active': isActive},
    );
    final row = await _client
        .from('teachers')
        .select('*, profiles!teachers_profile_id_fkey(*)')
        .eq('id', teacherId)
        .single();
    return Teacher.fromJson(row);
  }
}
