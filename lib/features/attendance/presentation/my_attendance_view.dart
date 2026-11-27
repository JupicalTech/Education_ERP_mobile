import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/attendance_providers.dart';
import 'leave_requests_view.dart';

class MyAttendanceView extends ConsumerStatefulWidget {
  const MyAttendanceView({super.key, this.isParent = false});

  final bool isParent;

  @override
  ConsumerState<MyAttendanceView> createState() => _MyAttendanceViewState();
}

class _MyAttendanceViewState extends ConsumerState<MyAttendanceView> {
  String? _selectedStudentId;

  String _fmtMonth(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(myAttendanceStudentsProvider);
    final selectedMonth = ref.watch(studentAttendanceMonthProvider);
    final textTheme = Theme.of(context).textTheme;

    return studentsAsync.when(
      loading: () => const LoadingView(message: 'Loading attendance...'),
      error: (e, _) => ErrorView(
        message: 'Could not load student profile: $e',
        onRetry: () => ref.invalidate(myAttendanceStudentsProvider),
      ),
      data: (students) {
        if (students.isEmpty) {
          return const EmptyState(
            icon: Icons.event_available_outlined,
            title: 'No student linked',
            subtitle: 'No student record is linked to your account yet.',
          );
        }

        final activeId =
            students.any((s) => s.studentId == _selectedStudentId)
            ? _selectedStudentId!
            : students.first.studentId;

        final summaryAsync = ref.watch(studentMonthlySummaryProvider(activeId));
        final historyAsync = ref.watch(
          studentAttendanceHistoryProvider(activeId),
        );

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (widget.isParent && students.length > 1) ...[
              const SectionHeader(title: 'Select Child'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: students
                    .map(
                      (s) => ChoiceChip(
                        selected: s.studentId == activeId,
                        label: Text(s.studentName),
                        onSelected: (_) =>
                            setState(() => _selectedStudentId = s.studentId),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    _fmtMonth(selectedMonth),
                    style: textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Previous month',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref
                      .read(studentAttendanceMonthProvider.notifier)
                      .setMonth(
                        DateTime(selectedMonth.year, selectedMonth.month - 1),
                      ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => ref
                      .read(studentAttendanceMonthProvider.notifier)
                      .setMonth(
                        DateTime(selectedMonth.year, selectedMonth.month + 1),
                      ),
                ),
                if (widget.isParent) ...[
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: 'Leave Requests',
                    variant: AppButtonVariant.tonal,
                    icon: Icons.event_busy_outlined,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Leave Requests')),
                          body: const LeaveRequestsView(allowApply: true),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            summaryAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Could not load summary: $e'),
              data: (summary) => Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.percent_outlined,
                      value: '${summary.percentage.toStringAsFixed(0)}%',
                      label: 'Monthly Rate',
                      tone: summary.percentage >= 75
                          ? StatTone.success
                          : StatTone.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: StatCard(
                      icon: Icons.check_circle_outline,
                      value: '${summary.presentDays}',
                      label: 'Present',
                      tone: StatTone.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: StatCard(
                      icon: Icons.cancel_outlined,
                      value: '${summary.absentDays}',
                      label: 'Absent',
                      tone: StatTone.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Daily Log'),
            const SizedBox(height: AppSpacing.sm),
            historyAsync.when(
              loading: () => const LoadingView(message: 'Loading log...'),
              error: (e, _) => ErrorView(
                message: 'Could not load log: $e',
                onRetry: () =>
                    ref.invalidate(studentAttendanceHistoryProvider(activeId)),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return const EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'No records this month',
                    subtitle: 'Attendance entries will appear here once marked.',
                  );
                }
                return Column(
                  children: records
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _fmtDate(r.date),
                                    style: textTheme.titleSmall,
                                  ),
                                ),
                                StatusChip(
                                  status: r.status.chipType,
                                  label: r.status.label,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
