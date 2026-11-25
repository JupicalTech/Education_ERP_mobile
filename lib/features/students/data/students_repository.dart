import '../../../core/widgets/status_chip.dart';
import 'student_model.dart';

abstract interface class StudentsRepository {
  Future<List<Student>> fetchStudents();
  Future<Student> addStudent(Student student);
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
}
