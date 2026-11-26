import 'package:flutter/foundation.dart';

enum AdmissionType {
  newAdmission('new', 'New Admission'),
  transfer('transfer', 'Transfer'),
  reAdmission('re_admission', 'Re-admission');

  const AdmissionType(this.dbValue, this.label);
  final String dbValue;
  final String label;
}

enum StudentType {
  dayScholar('day_scholar', 'Day Scholar'),
  hosteller('hosteller', 'Hosteller');

  const StudentType(this.dbValue, this.label);
  final String dbValue;
  final String label;
}

enum StudentCategory {
  general('General'),
  obc('OBC'),
  sc('SC'),
  st('ST');

  const StudentCategory(this.label);
  final String label;
}

enum SchoolBoard {
  cbse('CBSE'),
  gseb('GSEB'),
  icse('ICSE'),
  other('Other');

  const SchoolBoard(this.label);
  final String label;
}

enum DocumentType {
  birthCertificate('birth_certificate', 'Birth Certificate'),
  aadhaar('aadhaar', 'Aadhaar Card'),
  transferCertificate('transfer_certificate', 'Transfer Certificate (TC)'),
  previousMarksheet('previous_marksheet', 'Previous Marksheet'),
  passportPhoto('passport_photo', 'Passport Photo'),
  addressProof('address_proof', 'Address Proof');

  const DocumentType(this.dbValue, this.label);
  final String dbValue;
  final String label;
}

enum PrimaryContactRole { father, mother, guardian }

@immutable
class GuardianInput {
  const GuardianInput({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.occupation = '',
    this.qualification = '',
    this.annualIncome = '',
    required this.relationship,
    this.isPrimary = false,
  });

  final String name;
  final String phone;
  final String email;
  final String occupation;
  final String qualification;
  final String annualIncome;
  final String relationship;
  final bool isPrimary;

  bool get hasAnyData =>
      name.trim().isNotEmpty ||
      phone.trim().isNotEmpty ||
      email.trim().isNotEmpty ||
      occupation.trim().isNotEmpty ||
      qualification.trim().isNotEmpty ||
      annualIncome.trim().isNotEmpty;

  bool get isValidMandatory =>
      name.trim().isNotEmpty && phone.trim().length == 10;

  GuardianInput copyWith({
    String? name,
    String? phone,
    String? email,
    String? occupation,
    String? qualification,
    String? annualIncome,
    String? relationship,
    bool? isPrimary,
  }) {
    return GuardianInput(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      occupation: occupation ?? this.occupation,
      qualification: qualification ?? this.qualification,
      annualIncome: annualIncome ?? this.annualIncome,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'phone': phone.trim(),
        'email': _nullIfEmpty(email),
        'occupation': _nullIfEmpty(occupation),
        'qualification': _nullIfEmpty(qualification),
        'annual_income': _nullIfEmpty(annualIncome),
        'relationship': relationship,
        'is_primary': isPrimary,
      };
}

@immutable
class PreviousSchoolInput {
  const PreviousSchoolInput({
    this.schoolName = '',
    this.board = SchoolBoard.cbse,
    this.lastClassAttended = '',
    this.yearOfPassing = '',
    this.percentageOrGrade = '',
    this.reasonForLeaving = '',
    this.tcNumber = '',
    this.tcDate,
  });

  final String schoolName;
  final SchoolBoard board;
  final String lastClassAttended;
  final String yearOfPassing;
  final String percentageOrGrade;
  final String reasonForLeaving;
  final String tcNumber;
  final DateTime? tcDate;

  bool get hasAnyData =>
      schoolName.trim().isNotEmpty ||
      lastClassAttended.trim().isNotEmpty ||
      yearOfPassing.trim().isNotEmpty ||
      percentageOrGrade.trim().isNotEmpty ||
      reasonForLeaving.trim().isNotEmpty ||
      tcNumber.trim().isNotEmpty ||
      tcDate != null;

  PreviousSchoolInput copyWith({
    String? schoolName,
    SchoolBoard? board,
    String? lastClassAttended,
    String? yearOfPassing,
    String? percentageOrGrade,
    String? reasonForLeaving,
    String? tcNumber,
    DateTime? tcDate,
    bool clearTcDate = false,
  }) {
    return PreviousSchoolInput(
      schoolName: schoolName ?? this.schoolName,
      board: board ?? this.board,
      lastClassAttended: lastClassAttended ?? this.lastClassAttended,
      yearOfPassing: yearOfPassing ?? this.yearOfPassing,
      percentageOrGrade: percentageOrGrade ?? this.percentageOrGrade,
      reasonForLeaving: reasonForLeaving ?? this.reasonForLeaving,
      tcNumber: tcNumber ?? this.tcNumber,
      tcDate: clearTcDate ? null : (tcDate ?? this.tcDate),
    );
  }

  Map<String, dynamic> toJson() => {
        'school_name': schoolName.trim(),
        'board': board.label,
        'last_class_attended': _nullIfEmpty(lastClassAttended),
        'year_of_passing': _nullIfEmpty(yearOfPassing),
        'percentage_or_grade': _nullIfEmpty(percentageOrGrade),
        'reason_for_leaving': _nullIfEmpty(reasonForLeaving),
        'tc_number': _nullIfEmpty(tcNumber),
        'tc_date': tcDate?.toIso8601String().split('T').first,
      };
}

@immutable
class StudentDocumentInput {
  const StudentDocumentInput({
    required this.docType,
    this.fileName,
    this.fileUrl,
  });

  final DocumentType docType;
  final String? fileName;
  final String? fileUrl;

  bool get isUploaded => fileUrl != null && fileUrl!.isNotEmpty;

  StudentDocumentInput copyWith({
    String? fileName,
    String? fileUrl,
    bool clear = false,
  }) {
    return StudentDocumentInput(
      docType: docType,
      fileName: clear ? null : (fileName ?? this.fileName),
      fileUrl: clear ? null : (fileUrl ?? this.fileUrl),
    );
  }

  Map<String, dynamic> toJson() => {
        'doc_type': docType.dbValue,
        'file_name': fileName,
        'file_url': fileUrl,
      };
}

@immutable
class StudentAdmissionPayload {
  const StudentAdmissionPayload({
    // 1. Basic details
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.dateOfBirth,
    this.gender,
    this.photoUrl,
    this.bloodGroup,
    this.nationality = 'Indian',
    this.religion = '',
    this.motherTongue = '',
    this.category,
    this.aadhaarNumber = '',
    // 2. Admission details
    this.admissionNumber = 'AUTO-GENERATED',
    required this.admissionDate,
    this.grNumber = '',
    this.academicYear = '2026-2027',
    this.className,
    this.sectionName,
    this.rollNumber = '',
    this.admissionType = AdmissionType.newAdmission,
    this.studentType = StudentType.dayScholar,
    this.mediumOfInstruction = 'English',
    // 3. Contact & address
    this.currentAddress = '',
    this.permanentAddress = '',
    this.sameAsCurrentAddress = false,
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.studentPhone = '',
    this.studentEmail = '',
    // 4. Parent / guardian
    this.father = const GuardianInput(relationship: 'Father', isPrimary: true),
    this.mother = const GuardianInput(relationship: 'Mother'),
    this.hasSeparateGuardian = false,
    this.guardian = const GuardianInput(relationship: 'Guardian'),
    this.primaryContact = PrimaryContactRole.father,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelationship = '',
    // 5. Previous school
    this.previousSchools = const [PreviousSchoolInput()],
    // 6. Other info
    this.allergies = '',
    this.medicalConditions = '',
    this.doctorContact = '',
    this.siblingIds = const [],
    this.transportNeeded = false,
    this.transportRouteStop = '',
    this.specialNeeds = '',
    // 7. Documents
    this.documents = const [],
  });

  // 1. Basic details
  final String firstName;
  final String middleName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? photoUrl;
  final String? bloodGroup;
  final String nationality;
  final String religion;
  final String motherTongue;
  final StudentCategory? category;
  final String aadhaarNumber;

  // 2. Admission details
  final String admissionNumber;
  final DateTime admissionDate;
  final String grNumber;
  final String academicYear;
  final String? className;
  final String? sectionName;
  final String rollNumber;
  final AdmissionType admissionType;
  final StudentType studentType;
  final String mediumOfInstruction;

  // 3. Contact & address
  final String currentAddress;
  final String permanentAddress;
  final bool sameAsCurrentAddress;
  final String city;
  final String state;
  final String pincode;
  final String studentPhone;
  final String studentEmail;

  // 4. Parent / guardian
  final GuardianInput father;
  final GuardianInput mother;
  final bool hasSeparateGuardian;
  final GuardianInput guardian;
  final PrimaryContactRole primaryContact;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelationship;

  // 5. Previous school
  final List<PreviousSchoolInput> previousSchools;

  // 6. Other info
  final String allergies;
  final String medicalConditions;
  final String doctorContact;
  final List<String> siblingIds;
  final bool transportNeeded;
  final String transportRouteStop;
  final String specialNeeds;

  // 7. Documents
  final List<StudentDocumentInput> documents;

  GuardianInput get effectivePrimaryGuardian {
    switch (primaryContact) {
      case PrimaryContactRole.father:
        if (father.hasAnyData) return father;
      case PrimaryContactRole.mother:
        if (mother.hasAnyData) return mother;
      case PrimaryContactRole.guardian:
        if (hasSeparateGuardian && guardian.hasAnyData) return guardian;
    }
    if (father.hasAnyData) return father;
    if (mother.hasAnyData) return mother;
    if (hasSeparateGuardian && guardian.hasAnyData) return guardian;
    return father;
  }

  StudentAdmissionPayload copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? photoUrl,
    String? bloodGroup,
    String? nationality,
    String? religion,
    String? motherTongue,
    StudentCategory? category,
    bool clearCategory = false,
    String? aadhaarNumber,
    String? admissionNumber,
    DateTime? admissionDate,
    String? grNumber,
    String? academicYear,
    String? className,
    String? sectionName,
    String? rollNumber,
    AdmissionType? admissionType,
    StudentType? studentType,
    String? mediumOfInstruction,
    String? currentAddress,
    String? permanentAddress,
    bool? sameAsCurrentAddress,
    String? city,
    String? state,
    String? pincode,
    String? studentPhone,
    String? studentEmail,
    GuardianInput? father,
    GuardianInput? mother,
    bool? hasSeparateGuardian,
    GuardianInput? guardian,
    PrimaryContactRole? primaryContact,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    List<PreviousSchoolInput>? previousSchools,
    String? allergies,
    String? medicalConditions,
    String? doctorContact,
    List<String>? siblingIds,
    bool? transportNeeded,
    String? transportRouteStop,
    String? specialNeeds,
    List<StudentDocumentInput>? documents,
  }) {
    return StudentAdmissionPayload(
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      nationality: nationality ?? this.nationality,
      religion: religion ?? this.religion,
      motherTongue: motherTongue ?? this.motherTongue,
      category: clearCategory ? null : (category ?? this.category),
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      admissionDate: admissionDate ?? this.admissionDate,
      grNumber: grNumber ?? this.grNumber,
      academicYear: academicYear ?? this.academicYear,
      className: className ?? this.className,
      sectionName: sectionName ?? this.sectionName,
      rollNumber: rollNumber ?? this.rollNumber,
      admissionType: admissionType ?? this.admissionType,
      studentType: studentType ?? this.studentType,
      mediumOfInstruction: mediumOfInstruction ?? this.mediumOfInstruction,
      currentAddress: currentAddress ?? this.currentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      sameAsCurrentAddress: sameAsCurrentAddress ?? this.sameAsCurrentAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      studentPhone: studentPhone ?? this.studentPhone,
      studentEmail: studentEmail ?? this.studentEmail,
      father: father ?? this.father,
      mother: mother ?? this.mother,
      hasSeparateGuardian: hasSeparateGuardian ?? this.hasSeparateGuardian,
      guardian: guardian ?? this.guardian,
      primaryContact: primaryContact ?? this.primaryContact,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship:
          emergencyContactRelationship ?? this.emergencyContactRelationship,
      previousSchools: previousSchools ?? this.previousSchools,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      doctorContact: doctorContact ?? this.doctorContact,
      siblingIds: siblingIds ?? this.siblingIds,
      transportNeeded: transportNeeded ?? this.transportNeeded,
      transportRouteStop: transportRouteStop ?? this.transportRouteStop,
      specialNeeds: specialNeeds ?? this.specialNeeds,
      documents: documents ?? this.documents,
    );
  }

  /// Matches the jsonb payload expected by Postgres `create_student_admission(payload jsonb)`.
  Map<String, dynamic> toJson() {
    final guardiansList = <Map<String, dynamic>>[];
    if (father.hasAnyData) {
      guardiansList.add(
        father
            .copyWith(isPrimary: primaryContact == PrimaryContactRole.father)
            .toJson(),
      );
    }
    if (mother.hasAnyData) {
      guardiansList.add(
        mother
            .copyWith(isPrimary: primaryContact == PrimaryContactRole.mother)
            .toJson(),
      );
    }
    if (hasSeparateGuardian && guardian.hasAnyData) {
      guardiansList.add(
        guardian
            .copyWith(isPrimary: primaryContact == PrimaryContactRole.guardian)
            .toJson(),
      );
    }

    final effectivePermanent =
        sameAsCurrentAddress ? currentAddress : permanentAddress;

    return {
      'student': {
        'first_name': firstName.trim(),
        'middle_name': _nullIfEmpty(middleName),
        'last_name': lastName.trim(),
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'gender': gender,
        'photo_url': photoUrl,
        'blood_group': bloodGroup,
        'nationality': _nullIfEmpty(nationality),
        'religion': _nullIfEmpty(religion),
        'mother_tongue': _nullIfEmpty(motherTongue),
        'category': category?.label,
        'aadhaar_number': _nullIfEmpty(aadhaarNumber),
        'admission_date': admissionDate.toIso8601String().split('T').first,
        'gr_number': _nullIfEmpty(grNumber),
        'admission_type': admissionType.dbValue,
        'student_type': studentType.dbValue,
        'medium_of_instruction': _nullIfEmpty(mediumOfInstruction),
        'current_address': _nullIfEmpty(currentAddress),
        'permanent_address': _nullIfEmpty(effectivePermanent),
        'city': _nullIfEmpty(city),
        'state': _nullIfEmpty(state),
        'pincode': _nullIfEmpty(pincode),
        'phone': _nullIfEmpty(studentPhone),
        'email': _nullIfEmpty(studentEmail),
        'emergency_contact_name': _nullIfEmpty(emergencyContactName),
        'emergency_contact_phone': _nullIfEmpty(emergencyContactPhone),
        'emergency_contact_relationship':
            _nullIfEmpty(emergencyContactRelationship),
        'transport_needed': transportNeeded,
        'transport_route_stop':
            transportNeeded ? _nullIfEmpty(transportRouteStop) : null,
        'special_needs': _nullIfEmpty(specialNeeds),
        'sibling_ids': siblingIds,
      },
      'enrollment': {
        'academic_year': academicYear,
        'class_name': className,
        'section_name': sectionName,
        'roll_number': int.tryParse(rollNumber.trim()),
      },
      'guardians': guardiansList,
      'previous_schools': previousSchools
          .where((s) => s.hasAnyData && s.schoolName.trim().isNotEmpty)
          .map((s) => s.toJson())
          .toList(),
      'medical_info': {
        'allergies': _nullIfEmpty(allergies),
        'conditions': _nullIfEmpty(medicalConditions),
        'doctor_contact': _nullIfEmpty(doctorContact),
      },
      'documents': documents
          .where((d) => d.isUploaded)
          .map((d) => d.toJson())
          .toList(),
    };
  }
}

String? _nullIfEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
