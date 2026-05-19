import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_attendance/core/models/attendance_model.dart';
import 'package:school_attendance/core/models/exam_model.dart';
import 'package:school_attendance/core/models/fees_model.dart';
import 'package:school_attendance/core/models/meeting_model.dart';
import 'package:school_attendance/core/models/result_model.dart';
import 'package:school_attendance/core/utils/logger.dart';
import '../../../core/api/odoo_client.dart';
import '../../../core/api/parent_service.dart';
import '../../../core/models/student_model.dart';
import '../../auth/screens/auth_provider.dart';

// ── Service provider ──────────────────────────────────────────

final parentServiceProvider = Provider<ParentService>((ref) {
  return ParentService(ref.read(odooClientProvider));
});

// ── State ─────────────────────────────────────────────────────

class ParentState {
  final List<StudentModel> children;
  final List<FeesModel> fees;
  final List<ExamModel> exams;
  final List<ResultModel> results;
  final List<AttendanceModel> attendance;
  final List<MeetingModel> meetings;
  final bool isLoading;
  final String? error;

  const ParentState({
    this.children = const [],
    this.fees = const [],
    this.exams = const [],
    this.results = const [],
    this.attendance = const [],
    this.meetings = const [],
    this.isLoading = false,
    this.error,
  });

  ParentState copyWith({
    List<StudentModel>? children,
    List<FeesModel>? fees,
    List<ExamModel>? exams,
    List<ResultModel>? results,
    List<AttendanceModel>? attendance,
    List<MeetingModel>? meetings,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ParentState(
      children:   children   ?? this.children,
      fees:       fees       ?? this.fees,
      exams:      exams      ?? this.exams,
      results:    results    ?? this.results,
      attendance: attendance ?? this.attendance,
      meetings:   meetings   ?? this.meetings,
      isLoading:  isLoading  ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────

class ParentNotifier extends StateNotifier<ParentState> {
  final ParentService _service;
  final int _parentPartnerId;

  ParentNotifier(this._service, this._parentPartnerId)
      : super(const ParentState()) {
    loadChildren();
  }

  Future<void> loadChildren() async {
    if (_parentPartnerId == 0) {
      state = state.copyWith(
        error: 'Parent partner ID not found. Please re-login.',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final children = await _service.fetchMyChildren(_parentPartnerId);
      final studentIds = children.map((s) => s.id).toList();

      // Fetch all data in parallel
      // Note: meetings uses parentPartnerId directly, not studentIds
      final fetched = await Future.wait([
        _service.fetchFees(studentIds),
        _service.fetchExams(studentIds),
        _service.fetchResults(studentIds),
        _service.fetchAttendance(studentIds),
        _service.fetchMeetings(_parentPartnerId),
      ]);

      state = state.copyWith(
        children:   children,
        fees:       fetched[0] as List<FeesModel>,
        exams:      fetched[1] as List<ExamModel>,
        results:    fetched[2] as List<ResultModel>,
        attendance: fetched[3] as List<AttendanceModel>,
        meetings:   fetched[4] as List<MeetingModel>,
        isLoading:  false,
      );
    } on OdooException catch (e, st) {
      AppLogger.i('OdooException in loadChildren: ${e.message}\n$st');
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e, st) {
      AppLogger.i('ERROR in loadChildren: $e\n$st');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final parentProvider =
    StateNotifierProvider.autoDispose<ParentNotifier, ParentState>((ref) {
  final svc = ref.read(parentServiceProvider);
  final auth = ref.read(authProvider);
  AppLogger.i(
      'parentProvider building — partnerId: ${auth.partnerId}, role: ${auth.role}');
  return ParentNotifier(svc, auth.partnerId ?? 0);
});