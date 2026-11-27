import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client.dart';
import '../data/attendance_model.dart';
import '../data/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => SupabaseAttendanceRepository(ref.watch(supabaseProvider)),
);

final attendanceSectionsProvider = FutureProvider<List<AttendanceSection>>((
  ref,
) {
  return ref.watch(attendanceRepositoryProvider).fetchSections();
});

class _SelectedSectionNotifier extends Notifier<AttendanceSection?> {
  @override
  AttendanceSection? build() => null;

  void select(AttendanceSection? section) => state = section;
}

final selectedAttendanceSectionProvider =
    NotifierProvider<_SelectedSectionNotifier, AttendanceSection?>(
      _SelectedSectionNotifier.new,
    );

final activeAttendanceSectionProvider = Provider<AttendanceSection?>((ref) {
  final selected = ref.watch(selectedAttendanceSectionProvider);
  final sections = ref.watch(attendanceSectionsProvider).value ?? const [];
  if (selected != null && sections.contains(selected)) return selected;
  return sections.isNotEmpty ? sections.first : null;
});

class _AttendanceDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDate(DateTime date) =>
      state = DateTime(date.year, date.month, date.day);
}

final attendanceDateProvider =
    NotifierProvider<_AttendanceDateNotifier, DateTime>(
      _AttendanceDateNotifier.new,
    );

class AttendanceRosterNotifier
    extends AsyncNotifier<List<AttendanceRosterEntry>> {
  @override
  FutureOr<List<AttendanceRosterEntry>> build() async {
    final section = ref.watch(activeAttendanceSectionProvider);
    final date = ref.watch(attendanceDateProvider);
    if (section == null) return const [];
    return ref
        .read(attendanceRepositoryProvider)
        .fetchRoster(sectionId: section.id, date: date);
  }

  void setStatus(String studentId, AttendanceStatus status) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final entry in current)
        if (entry.studentId == studentId)
          entry.copyWith(status: status)
        else
          entry,
    ]);
  }

  void markAllPresent() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final entry in current)
        entry.copyWith(status: AttendanceStatus.present),
    ]);
  }

  Future<void> submit() async {
    final section = ref.read(activeAttendanceSectionProvider);
    final date = ref.read(attendanceDateProvider);
    final entries = state.value ?? const [];
    if (section == null || entries.isEmpty) return;

    await ref
        .read(attendanceRepositoryProvider)
        .submitSectionAttendance(
          sectionId: section.id,
          date: date,
          entries: entries,
        );

    ref.invalidate(attendanceDashboardStatsProvider);
    ref.invalidate(dailyAttendanceSummaryProvider);
    ref.invalidate(lowAttendanceStudentsProvider);
  }
}

final attendanceRosterProvider =
    AsyncNotifierProvider<AttendanceRosterNotifier, List<AttendanceRosterEntry>>(
      AttendanceRosterNotifier.new,
    );

// --- Leave Requests ---

class LeaveRequestsNotifier extends AsyncNotifier<List<LeaveRequestItem>> {
  @override
  FutureOr<List<LeaveRequestItem>> build() {
    return ref.watch(attendanceRepositoryProvider).fetchLeaveRequests();
  }

  Future<void> submit({
    required String studentId,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    await ref
        .read(attendanceRepositoryProvider)
        .submitLeaveRequest(
          studentId: studentId,
          fromDate: fromDate,
          toDate: toDate,
          reason: reason,
        );
    state = AsyncData(
      await ref.read(attendanceRepositoryProvider).fetchLeaveRequests(),
    );
  }

  Future<void> review({
    required String leaveId,
    required LeaveRequestStatus status,
    String? note,
  }) async {
    await ref
        .read(attendanceRepositoryProvider)
        .reviewLeaveRequest(leaveId: leaveId, status: status, note: note);
    state = AsyncData(
      await ref.read(attendanceRepositoryProvider).fetchLeaveRequests(),
    );
    ref.invalidate(attendanceRosterProvider);
    ref.invalidate(attendanceDashboardStatsProvider);
    ref.invalidate(dailyAttendanceSummaryProvider);
  }
}

final leaveRequestsProvider =
    AsyncNotifierProvider<LeaveRequestsNotifier, List<LeaveRequestItem>>(
      LeaveRequestsNotifier.new,
    );

// --- Parent & Student Views ---

final myAttendanceStudentsProvider = FutureProvider<List<MyStudentSummary>>((
  ref,
) {
  return ref.watch(attendanceRepositoryProvider).fetchMyStudents();
});

class _MonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void setMonth(DateTime month) => state = DateTime(month.year, month.month);
}

final studentAttendanceMonthProvider = NotifierProvider<_MonthNotifier, DateTime>(
  _MonthNotifier.new,
);

final studentMonthlySummaryProvider =
    FutureProvider.family<MonthlyAttendanceSummary, String>((ref, studentId) {
      final month = ref.watch(studentAttendanceMonthProvider);
      return ref
          .watch(attendanceRepositoryProvider)
          .fetchMonthlySummary(
            studentId: studentId,
            year: month.year,
            month: month.month,
          );
    });

final studentAttendanceHistoryProvider =
    FutureProvider.family<List<StudentAttendanceRecord>, String>((
      ref,
      studentId,
    ) {
      final month = ref.watch(studentAttendanceMonthProvider);
      return ref
          .watch(attendanceRepositoryProvider)
          .fetchStudentHistory(
            studentId: studentId,
            year: month.year,
            month: month.month,
          );
    });

// --- Principal Reports & Dashboard ---

final dailyAttendanceSummaryProvider =
    FutureProvider<List<DailySectionSummary>>((ref) {
      final date = ref.watch(attendanceDateProvider);
      return ref.watch(attendanceRepositoryProvider).fetchDailySummary(date);
    });

class _ThresholdNotifier extends Notifier<double> {
  @override
  double build() => 75.0;
  void setThreshold(double value) => state = value;
}

final lowAttendanceThresholdProvider =
    NotifierProvider<_ThresholdNotifier, double>(_ThresholdNotifier.new);

final lowAttendanceStudentsProvider =
    FutureProvider<List<LowAttendanceStudent>>((ref) {
      final threshold = ref.watch(lowAttendanceThresholdProvider);
      return ref
          .watch(attendanceRepositoryProvider)
          .fetchLowAttendanceStudents(threshold: threshold);
    });

final attendanceDashboardStatsProvider =
    FutureProvider<AttendanceDashboardStats>((ref) {
      final now = DateTime.now();
      return ref
          .watch(attendanceRepositoryProvider)
          .fetchDashboardStats(DateTime(now.year, now.month, now.day));
    });
