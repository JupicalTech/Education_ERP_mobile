import 'package:education_erp/features/students/data/student_admission_model.dart';
import 'package:education_erp/features/students/presentation/widgets/admission_step_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Admission field validators', () {
    test('validateTenDigitPhone accepts empty when optional and 10 digits', () {
      expect(validateTenDigitPhone(''), isNull);
      expect(validateTenDigitPhone('9876543210'), isNull);
      expect(validateTenDigitPhone('98765'), isNotNull);
      expect(validateTenDigitPhone('', required: true), isNotNull);
    });

    test('validateSixDigitPincode validates 6 digits when filled', () {
      expect(validateSixDigitPincode(''), isNull);
      expect(validateSixDigitPincode('380001'), isNull);
      expect(validateSixDigitPincode('3800'), isNotNull);
    });

    test('validateTwelveDigitAadhaar validates 12 digits when filled', () {
      expect(validateTwelveDigitAadhaar(''), isNull);
      expect(validateTwelveDigitAadhaar('123456789012'), isNull);
      expect(validateTwelveDigitAadhaar('123456'), isNotNull);
    });
  });

  group('StudentAdmissionPayload.toJson', () {
    test('serializes RPC payload structure with primary guardian', () {
      final payload = StudentAdmissionPayload(
        firstName: 'Aarav',
        lastName: 'Mehta',
        dateOfBirth: DateTime(2015, 5, 12),
        gender: 'Male',
        admissionDate: DateTime(2026, 4, 1),
        className: 'Class 5',
        sectionName: 'A',
        rollNumber: '12',
        currentAddress: '12 MG Road',
        sameAsCurrentAddress: true,
        father: const GuardianInput(
          name: 'Ramesh Mehta',
          phone: '9876543210',
          relationship: 'Father',
        ),
        primaryContact: PrimaryContactRole.father,
        previousSchools: const [
          PreviousSchoolInput(
            schoolName: 'Sunrise Public School',
            board: SchoolBoard.cbse,
          ),
        ],
      );

      final json = payload.toJson();
      final student = json['student'] as Map<String, dynamic>;
      final enrollment = json['enrollment'] as Map<String, dynamic>;
      final guardians = json['guardians'] as List<dynamic>;
      final prevSchools = json['previous_schools'] as List<dynamic>;

      expect(student['first_name'], 'Aarav');
      expect(student['last_name'], 'Mehta');
      expect(student['permanent_address'], '12 MG Road');
      expect(enrollment['class_name'], 'Class 5');
      expect(enrollment['roll_number'], 12);
      expect(guardians.length, 1);
      expect((guardians.first as Map<String, dynamic>)['is_primary'], isTrue);
      expect(prevSchools.length, 1);
    });
  });
}
