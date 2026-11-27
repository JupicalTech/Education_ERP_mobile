import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/attendance_model.dart';
import '../data/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => StubAttendanceRepository(),
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
        .saveAttendance(sectionId: section.id, date: date, entries: entries);
  }
}

final attendanceRosterProvider =
    AsyncNotifierProvider<AttendanceRosterNotifier, List<AttendanceRosterEntry>>(
      AttendanceRosterNotifier.new,
    );
