import '../../../core/widgets/status_chip.dart';

enum TeacherStatus {
  active('active', 'Active', StatusType.present),
  onLeave('on_leave', 'On Leave', StatusType.late),
  resigned('resigned', 'Resigned', StatusType.absent),
  inactive('inactive', 'Inactive', StatusType.overdue);

  const TeacherStatus(this.dbValue, this.label, this.chipStatus);

  final String dbValue;
  final String label;
  final StatusType chipStatus;

  static TeacherStatus fromString(String? value) {
    return TeacherStatus.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => TeacherStatus.active,
    );
  }
}

enum EmploymentType {
  fullTime('full_time', 'Full-time'),
  partTime('part_time', 'Part-time'),
  contract('contract', 'Contract'),
  guest('guest', 'Guest');

  const EmploymentType(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static EmploymentType fromString(String? value) {
    return EmploymentType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => EmploymentType.fullTime,
    );
  }
}

class TeacherQualification {
  const TeacherQualification({
    this.id,
    required this.degree,
    this.specialization,
    required this.institution,
    this.yearOfPassing,
    this.percentageOrGrade,
  });

  final String? id;
  final String degree;
  final String? specialization;
  final String institution;
  final String? yearOfPassing;
  final String? percentageOrGrade;

  factory TeacherQualification.fromJson(Map<String, dynamic> json) {
    return TeacherQualification(
      id: json['id'] as String?,
      degree: (json['degree'] as String?) ?? '',
      specialization: json['specialization'] as String?,
      institution: (json['institution'] as String?) ?? '',
      yearOfPassing: json['year_of_passing'] as String?,
      percentageOrGrade: json['percentage_or_grade'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'degree': degree,
    'specialization': specialization,
    'institution': institution,
    'year_of_passing': yearOfPassing,
    'percentage_or_grade': percentageOrGrade,
  };

  TeacherQualification copyWith({
    String? id,
    String? degree,
    String? specialization,
    String? institution,
    String? yearOfPassing,
    String? percentageOrGrade,
  }) {
    return TeacherQualification(
      id: id ?? this.id,
      degree: degree ?? this.degree,
      specialization: specialization ?? this.specialization,
      institution: institution ?? this.institution,
      yearOfPassing: yearOfPassing ?? this.yearOfPassing,
      percentageOrGrade: percentageOrGrade ?? this.percentageOrGrade,
    );
  }
}

class TeacherExperience {
  const TeacherExperience({
    this.id,
    required this.organization,
    this.designation,
    required this.fromDate,
    required this.toDate,
    this.reasonForLeaving,
  });

  final String? id;
  final String organization;
  final String? designation;
  final DateTime fromDate;
  final DateTime toDate;
  final String? reasonForLeaving;

  int get durationMonths {
    final diffDays = toDate.difference(fromDate).inDays;
    if (diffDays <= 0) return 0;
    return (diffDays / 30.4375).round();
  }

  factory TeacherExperience.fromJson(Map<String, dynamic> json) {
    return TeacherExperience(
      id: json['id'] as String?,
      organization: (json['organization'] as String?) ?? '',
      designation: json['designation'] as String?,
      fromDate: DateTime.tryParse((json['from_date'] as String?) ?? '') ??
          DateTime.now(),
      toDate:
          DateTime.tryParse((json['to_date'] as String?) ?? '') ?? DateTime.now(),
      reasonForLeaving: json['reason_for_leaving'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'organization': organization,
    'designation': designation,
    'from_date': _fmtDate(fromDate),
    'to_date': _fmtDate(toDate),
    'reason_for_leaving': reasonForLeaving,
  };

  TeacherExperience copyWith({
    String? id,
    String? organization,
    String? designation,
    DateTime? fromDate,
    DateTime? toDate,
    String? reasonForLeaving,
  }) {
    return TeacherExperience(
      id: id ?? this.id,
      organization: organization ?? this.organization,
      designation: designation ?? this.designation,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      reasonForLeaving: reasonForLeaving ?? this.reasonForLeaving,
    );
  }
}

class TeacherAssignment {
  const TeacherAssignment({
    this.id,
    this.academicYearId = '2026-2027',
    required this.className,
    required this.sectionName,
    required this.subject,
    this.sectionId,
    this.subjectId,
  });

  final String? id;
  final String academicYearId;
  final String className;
  final String sectionName;
  final String subject;
  final String? sectionId;
  final String? subjectId;

  String get classSection => '$className-$sectionName';

  factory TeacherAssignment.fromJson(Map<String, dynamic> json) {
    return TeacherAssignment(
      id: json['id'] as String?,
      academicYearId: (json['academic_year_id'] as String?) ?? '2026-2027',
      className: (json['class_name'] as String?) ?? '',
      sectionName: (json['section_name'] as String?) ?? '',
      subject: (json['subject'] as String?) ?? '',
      sectionId: json['section_id'] as String?,
      subjectId: json['subject_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'academic_year_id': academicYearId,
    'section_id': sectionId ?? classSection,
    'subject_id': subjectId ?? subject,
    'class_name': className,
    'section_name': sectionName,
    'subject': subject,
  };

  TeacherAssignment copyWith({
    String? id,
    String? academicYearId,
    String? className,
    String? sectionName,
    String? subject,
    String? sectionId,
    String? subjectId,
  }) {
    return TeacherAssignment(
      id: id ?? this.id,
      academicYearId: academicYearId ?? this.academicYearId,
      className: className ?? this.className,
      sectionName: sectionName ?? this.sectionName,
      subject: subject ?? this.subject,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
    );
  }
}

class TeacherBankDetails {
  const TeacherBankDetails({
    this.basicSalary = 0,
    this.allowances = 0,
    this.deductions = 0,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.accountHolderName,
    this.pfNumber,
    this.esiNumber,
  });

  final double basicSalary;
  final double allowances;
  final double deductions;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountHolderName;
  final String? pfNumber;
  final String? esiNumber;

  double get netSalary => basicSalary + allowances - deductions;

  factory TeacherBankDetails.fromJson(Map<String, dynamic> json) {
    return TeacherBankDetails(
      basicSalary: (json['basic_salary'] as num?)?.toDouble() ?? 0,
      allowances: (json['allowances'] as num?)?.toDouble() ?? 0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0,
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      ifscCode: json['ifsc_code'] as String?,
      accountHolderName: json['account_holder_name'] as String?,
      pfNumber: json['pf_number'] as String?,
      esiNumber: json['esi_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'basic_salary': basicSalary,
    'allowances': allowances,
    'deductions': deductions,
    'bank_name': bankName,
    'account_number': accountNumber,
    'ifsc_code': ifscCode,
    'account_holder_name': accountHolderName,
    'pf_number': pfNumber,
    'esi_number': esiNumber,
  };

  TeacherBankDetails copyWith({
    double? basicSalary,
    double? allowances,
    double? deductions,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? accountHolderName,
    String? pfNumber,
    String? esiNumber,
  }) {
    return TeacherBankDetails(
      basicSalary: basicSalary ?? this.basicSalary,
      allowances: allowances ?? this.allowances,
      deductions: deductions ?? this.deductions,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      pfNumber: pfNumber ?? this.pfNumber,
      esiNumber: esiNumber ?? this.esiNumber,
    );
  }
}

class TeacherDocument {
  const TeacherDocument({
    this.id,
    required this.docType,
    this.fileName,
    required this.fileUrl,
  });

  final String? id;
  final String docType;
  final String? fileName;
  final String fileUrl;

  factory TeacherDocument.fromJson(Map<String, dynamic> json) {
    return TeacherDocument(
      id: json['id'] as String?,
      docType: (json['doc_type'] as String?) ?? '',
      fileName: json['file_name'] as String?,
      fileUrl: (json['file_url'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'doc_type': docType,
    'file_name': fileName,
    'file_url': fileUrl,
  };
}

class Teacher {
  const Teacher({
    required this.id,
    required this.profileId,
    required this.instituteId,
    required this.employeeId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.photoUrl,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.maritalStatus,
    this.nationality = 'Indian',
    this.religion,
    this.aadhaarNumber,
    this.panNumber,
    this.phone,
    this.alternatePhone,
    required this.email,
    this.currentAddress,
    this.permanentAddress,
    this.city,
    this.state,
    this.pincode,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    required this.designation,
    this.department,
    this.employmentType = EmploymentType.fullTime,
    required this.joiningDate,
    this.probationEndDate,
    this.reportingToId,
    this.reportingToName,
    this.status = TeacherStatus.active,
    this.resignationDate,
    this.teachingLicenseNumber,
    this.isActive = true,
    this.qualifications = const [],
    this.experiences = const [],
    this.teachableSubjects = const [],
    this.assignments = const [],
    this.classTeacherSection,
    this.bankDetails,
    this.documents = const [],
  });

  final String id;
  final String profileId;
  final String instituteId;
  final String employeeId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? photoUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? maritalStatus;
  final String nationality;
  final String? religion;
  final String? aadhaarNumber;
  final String? panNumber;
  final String? phone;
  final String? alternatePhone;
  final String email;
  final String? currentAddress;
  final String? permanentAddress;
  final String? city;
  final String? state;
  final String? pincode;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  final String designation;
  final String? department;
  final EmploymentType employmentType;
  final DateTime joiningDate;
  final DateTime? probationEndDate;
  final String? reportingToId;
  final String? reportingToName;
  final TeacherStatus status;
  final DateTime? resignationDate;
  final String? teachingLicenseNumber;
  final bool isActive;
  final List<TeacherQualification> qualifications;
  final List<TeacherExperience> experiences;
  final List<String> teachableSubjects;
  final List<TeacherAssignment> assignments;
  final String? classTeacherSection;
  final TeacherBankDetails? bankDetails;
  final List<TeacherDocument> documents;

  String get fullName => [
    firstName,
    if (middleName != null && middleName!.trim().isNotEmpty) middleName!.trim(),
    lastName,
  ].join(' ');

  List<String> get assignedClasses =>
      assignments.map((a) => a.classSection).toSet().toList()..sort();

  int get totalExperienceMonths =>
      experiences.fold(0, (sum, e) => sum + e.durationMonths);

  String get totalExperienceLabel {
    final months = totalExperienceMonths;
    if (months == 0) return '0 months (Fresher)';
    final yrs = months ~/ 12;
    final rem = months % 12;
    if (yrs == 0) return '$rem mo';
    if (rem == 0) return '$yrs yr${yrs > 1 ? 's' : ''}';
    return '$yrs yr${yrs > 1 ? 's' : ''} $rem mo';
  }

  Teacher copyWith({
    String? id,
    String? profileId,
    String? instituteId,
    String? employeeId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? maritalStatus,
    String? nationality,
    String? religion,
    String? aadhaarNumber,
    String? panNumber,
    String? phone,
    String? alternatePhone,
    String? email,
    String? currentAddress,
    String? permanentAddress,
    String? city,
    String? state,
    String? pincode,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    String? designation,
    String? department,
    EmploymentType? employmentType,
    DateTime? joiningDate,
    DateTime? probationEndDate,
    String? reportingToId,
    String? reportingToName,
    TeacherStatus? status,
    DateTime? resignationDate,
    String? teachingLicenseNumber,
    bool? isActive,
    List<TeacherQualification>? qualifications,
    List<TeacherExperience>? experiences,
    List<String>? teachableSubjects,
    List<TeacherAssignment>? assignments,
    String? classTeacherSection,
    bool clearClassTeacher = false,
    TeacherBankDetails? bankDetails,
    List<TeacherDocument>? documents,
  }) {
    return Teacher(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      instituteId: instituteId ?? this.instituteId,
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      photoUrl: photoUrl ?? this.photoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      nationality: nationality ?? this.nationality,
      religion: religion ?? this.religion,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      panNumber: panNumber ?? this.panNumber,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      currentAddress: currentAddress ?? this.currentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship:
          emergencyContactRelationship ?? this.emergencyContactRelationship,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      employmentType: employmentType ?? this.employmentType,
      joiningDate: joiningDate ?? this.joiningDate,
      probationEndDate: probationEndDate ?? this.probationEndDate,
      reportingToId: reportingToId ?? this.reportingToId,
      reportingToName: reportingToName ?? this.reportingToName,
      status: status ?? this.status,
      resignationDate: resignationDate ?? this.resignationDate,
      teachingLicenseNumber:
          teachingLicenseNumber ?? this.teachingLicenseNumber,
      isActive: isActive ?? this.isActive,
      qualifications: qualifications ?? this.qualifications,
      experiences: experiences ?? this.experiences,
      teachableSubjects: teachableSubjects ?? this.teachableSubjects,
      assignments: assignments ?? this.assignments,
      classTeacherSection: clearClassTeacher
          ? null
          : (classTeacherSection ?? this.classTeacherSection),
      bankDetails: bankDetails ?? this.bankDetails,
      documents: documents ?? this.documents,
    );
  }

  /// Serializes to the JSONB payload expected by `create_teacher` / `update_teacher` RPC.
  Map<String, dynamic> toRpcPayload() {
    return {
      'profile_id': profileId.isEmpty ? null : profileId,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'avatar_url': photoUrl,
      'date_of_birth': dateOfBirth != null ? _fmtDate(dateOfBirth!) : null,
      'gender': gender,
      'blood_group': bloodGroup,
      'marital_status': maritalStatus,
      'nationality': nationality,
      'religion': religion,
      'aadhaar_number': aadhaarNumber,
      'pan_number': panNumber,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'email': email,
      'current_address': currentAddress,
      'permanent_address': permanentAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relationship': emergencyContactRelationship,
      'designation': designation,
      'department': department,
      'employment_type': employmentType.dbValue,
      'joining_date': _fmtDate(joiningDate),
      'probation_end_date':
          probationEndDate != null ? _fmtDate(probationEndDate!) : null,
      'reporting_to': reportingToId,
      'status': status.dbValue,
      'resignation_date':
          resignationDate != null ? _fmtDate(resignationDate!) : null,
      'teaching_license_number': teachingLicenseNumber,
      'is_active': isActive,
      'qualifications': qualifications.map((q) => q.toJson()).toList(),
      'experiences': experiences.map((e) => e.toJson()).toList(),
      'teachable_subject_ids': teachableSubjects,
      'assignments': assignments.map((a) => a.toJson()).toList(),
      'class_teacher_section_id': classTeacherSection,
      'documents': documents.map((d) => d.toJson()).toList(),
      if (bankDetails != null) 'bank_details': bankDetails!.toJson(),
    };
  }

  factory Teacher.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return Teacher(
      id: json['id'] as String,
      profileId: (json['profile_id'] as String?) ?? '',
      instituteId: (json['institute_id'] as String?) ?? '',
      employeeId: (json['employee_id'] as String?) ?? '',
      firstName:
          (profile?['first_name'] as String?) ??
          (json['first_name'] as String?) ??
          '',
      middleName: json['middle_name'] as String?,
      lastName:
          (profile?['last_name'] as String?) ??
          (json['last_name'] as String?) ??
          '',
      photoUrl: (profile?['avatar_url'] as String?) ?? json['photo_url'] as String?,
      dateOfBirth: DateTime.tryParse((json['date_of_birth'] as String?) ?? ''),
      gender: json['gender'] as String?,
      bloodGroup: json['blood_group'] as String?,
      maritalStatus: json['marital_status'] as String?,
      nationality: (json['nationality'] as String?) ?? 'Indian',
      religion: json['religion'] as String?,
      aadhaarNumber: json['aadhaar_number'] as String?,
      panNumber: json['pan_number'] as String?,
      phone: (profile?['phone'] as String?) ?? json['phone'] as String?,
      alternatePhone: json['alternate_phone'] as String?,
      email: (json['email'] as String?) ?? '',
      currentAddress: json['current_address'] as String?,
      permanentAddress: json['permanent_address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      emergencyContactRelationship:
          json['emergency_contact_relationship'] as String?,
      designation: (json['designation'] as String?) ?? '',
      department: json['department'] as String?,
      employmentType: EmploymentType.fromString(
        json['employment_type'] as String?,
      ),
      joiningDate:
          DateTime.tryParse((json['joining_date'] as String?) ?? '') ??
          DateTime.now(),
      probationEndDate: DateTime.tryParse(
        (json['probation_end_date'] as String?) ?? '',
      ),
      reportingToId: json['reporting_to'] as String?,
      status: TeacherStatus.fromString(json['status'] as String?),
      resignationDate: DateTime.tryParse(
        (json['resignation_date'] as String?) ?? '',
      ),
      teachingLicenseNumber: json['teaching_license_number'] as String?,
      isActive: (profile?['is_active'] as bool?) ?? (json['is_active'] as bool?) ?? true,
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
