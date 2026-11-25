import '../../../core/widgets/status_chip.dart';

class NoticeItem {
  const NoticeItem({
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.audience,
  });

  final String title;
  final String subtitle;
  final String dateLabel;
  final String audience;
}

class PrincipalDashboardData {
  const PrincipalDashboardData({
    required this.totalStudents,
    required this.todayAttendance,
    required this.feesCollected,
    required this.pendingDues,
    required this.notices,
  });

  final String totalStudents;
  final String todayAttendance;
  final String feesCollected;
  final String pendingDues;
  final List<NoticeItem> notices;
}

class TeacherClassItem {
  const TeacherClassItem({
    required this.className,
    required this.subject,
    required this.timeSlot,
    required this.studentCount,
    required this.attendanceMarked,
  });

  final String className;
  final String subject;
  final String timeSlot;
  final int studentCount;
  final bool attendanceMarked;
}

class ParentChildSummary {
  const ParentChildSummary({
    required this.id,
    required this.name,
    required this.classLabel,
    required this.attendancePercent,
    required this.todayStatus,
    required this.feeDueAmount,
    required this.feeDueDate,
    required this.feeStatus,
    required this.latestNotice,
  });

  final String id;
  final String name;
  final String classLabel;
  final String attendancePercent;
  final StatusType todayStatus;
  final String feeDueAmount;
  final String feeDueDate;
  final StatusType feeStatus;
  final NoticeItem latestNotice;
}

class FeeReceiptItem {
  const FeeReceiptItem({
    required this.receiptNo,
    required this.studentName,
    required this.classLabel,
    required this.amount,
    required this.mode,
    required this.status,
  });

  final String receiptNo;
  final String studentName;
  final String classLabel;
  final String amount;
  final String mode;
  final StatusType status;
}

class FeeClerkDashboardData {
  const FeeClerkDashboardData({
    required this.todayCollection,
    required this.pendingDues,
    required this.receiptsToday,
    required this.recentReceipts,
  });

  final String todayCollection;
  final String pendingDues;
  final String receiptsToday;
  final List<FeeReceiptItem> recentReceipts;
}

/// Dummy data for pre-migration UI development.
/// Replace these providers with Supabase queries once the V1 schema is live.
abstract final class HomeDummyData {
  static const principal = PrincipalDashboardData(
    totalStudents: '1,248',
    todayAttendance: '94.2%',
    feesCollected: '₹4,82,500',
    pendingDues: '₹1,14,000',
    notices: [
      NoticeItem(
        title: 'Annual Science Exhibition',
        subtitle: 'Project submissions close this Friday at 3:00 PM.',
        dateLabel: 'Today',
        audience: 'All',
      ),
      NoticeItem(
        title: 'Parent-Teacher Meeting (Term 1)',
        subtitle: 'Scheduled for Saturday, 9:30 AM – 1:30 PM.',
        dateLabel: 'Yesterday',
        audience: 'Parents',
      ),
      NoticeItem(
        title: 'Winter Uniform Transition',
        subtitle: 'Students to wear winter uniform from next Monday.',
        dateLabel: '2 days ago',
        audience: 'Students',
      ),
    ],
  );

  static const teacherClasses = [
    TeacherClassItem(
      className: 'Class 8-A',
      subject: 'Mathematics',
      timeSlot: '08:30 AM – 09:15 AM',
      studentCount: 38,
      attendanceMarked: true,
    ),
    TeacherClassItem(
      className: 'Class 9-B',
      subject: 'Mathematics',
      timeSlot: '09:30 AM – 10:15 AM',
      studentCount: 41,
      attendanceMarked: false,
    ),
    TeacherClassItem(
      className: 'Class 7-A',
      subject: 'Science',
      timeSlot: '11:00 AM – 11:45 AM',
      studentCount: 36,
      attendanceMarked: false,
    ),
  ];

  static const parentChildren = [
    ParentChildSummary(
      id: 'stu-1',
      name: 'Aarav Sharma',
      classLabel: 'Class 6-A • Roll #14',
      attendancePercent: '96%',
      todayStatus: StatusType.present,
      feeDueAmount: '₹8,500',
      feeDueDate: 'Due 30 Nov',
      feeStatus: StatusType.pending,
      latestNotice: NoticeItem(
        title: 'Parent-Teacher Meeting (Term 1)',
        subtitle: 'Scheduled for Saturday, 9:30 AM – 1:30 PM.',
        dateLabel: 'Yesterday',
        audience: 'Class 6-A',
      ),
    ),
    ParentChildSummary(
      id: 'stu-2',
      name: 'Ananya Sharma',
      classLabel: 'Class 3-B • Roll #07',
      attendancePercent: '91%',
      todayStatus: StatusType.late,
      feeDueAmount: '₹0',
      feeDueDate: 'All clear',
      feeStatus: StatusType.paid,
      latestNotice: NoticeItem(
        title: 'Art & Craft Supply List',
        subtitle: 'Please send watercolor pencils by Thursday.',
        dateLabel: '2 days ago',
        audience: 'Class 3-B',
      ),
    ),
  ];

  static const feeClerk = FeeClerkDashboardData(
    todayCollection: '₹64,500',
    pendingDues: '₹1,14,000',
    receiptsToday: '18',
    recentReceipts: [
      FeeReceiptItem(
        receiptNo: 'RCP-1042',
        studentName: 'Rohan Verma',
        classLabel: 'Class 9-A',
        amount: '₹12,000',
        mode: 'UPI',
        status: StatusType.paid,
      ),
      FeeReceiptItem(
        receiptNo: 'RCP-1041',
        studentName: 'Meera Nair',
        classLabel: 'Class 5-C',
        amount: '₹6,500',
        mode: 'Cash',
        status: StatusType.partial,
      ),
      FeeReceiptItem(
        receiptNo: 'RCP-1040',
        studentName: 'Kabir Patel',
        classLabel: 'Class 10-B',
        amount: '₹14,200',
        mode: 'Due',
        status: StatusType.overdue,
      ),
    ],
  );
}
