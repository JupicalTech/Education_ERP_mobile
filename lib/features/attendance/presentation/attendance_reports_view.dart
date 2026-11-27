import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/attendance_providers.dart';
import 'leave_requests_view.dart';
import 'mark_attendance_view.dart';

class AttendanceReportsView extends ConsumerWidget {
  const AttendanceReportsView({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(attendanceDateProvider);
    final summaryAsync = ref.watch(dailyAttendanceSummaryProvider);
    final threshold = ref.watch(lowAttendanceThresholdProvider);
    final lowAsync = ref.watch(lowAttendanceStudentsProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Attendance Reports', style: textTheme.titleLarge),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      ref.read(attendanceDateProvider.notifier).setDate(picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(_fmtDate(selectedDate)),
                ),
                AppButton(
                  label: 'Mark Roll Call',
                  variant: AppButtonVariant.tonal,
                  icon: Icons.fact_check_outlined,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Mark Attendance')),
                        body: const MarkAttendanceView(),
                      ),
                    ),
                  ),
                ),
                AppButton(
                  label: 'Leave Approvals',
                  variant: AppButtonVariant.tonal,
                  icon: Icons.event_busy_outlined,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Leave Approvals')),
                        body: const LeaveRequestsView(canReview: true),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Daily Section Summary'),
        const SizedBox(height: AppSpacing.sm),
        summaryAsync.when(
          loading: () => const LoadingView(message: 'Loading summary...'),
          error: (e, _) => ErrorView(
            message: 'Could not load summary: $e',
            onRetry: () => ref.invalidate(dailyAttendanceSummaryProvider),
          ),
          data: (sections) {
            if (sections.isEmpty) {
              return const EmptyState(
                icon: Icons.class_outlined,
                title: 'No sections found',
                subtitle: 'Add classes and sections first.',
              );
            }
            return Column(
              children: sections
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.sectionLabel,
                                    style: textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Total: ${s.totalStudents} • '
                                    'Present: ${s.presentCount} • '
                                    'Absent: ${s.absentCount} • '
                                    'Late: ${s.lateCount} • '
                                    'Leave: ${s.leaveCount}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              status: s.isMarked
                                  ? StatusType.present
                                  : StatusType.pending,
                              label: s.isMarked ? 'Marked' : 'Pending',
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
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                title: 'Students Below ${threshold.toInt()}%',
              ),
            ),
            DropdownButton<double>(
              value: threshold,
              items: const [
                DropdownMenuItem(value: 75.0, child: Text('Below 75%')),
                DropdownMenuItem(value: 70.0, child: Text('Below 70%')),
                DropdownMenuItem(value: 65.0, child: Text('Below 65%')),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref
                      .read(lowAttendanceThresholdProvider.notifier)
                      .setThreshold(v);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        lowAsync.when(
          loading: () => const LoadingView(message: 'Checking attendance...'),
          error: (e, _) => ErrorView(
            message: 'Could not load report: $e',
            onRetry: () => ref.invalidate(lowAttendanceStudentsProvider),
          ),
          data: (students) {
            if (students.isEmpty) {
              return EmptyState(
                icon: Icons.verified_outlined,
                title: 'All students above ${threshold.toInt()}%',
                subtitle: 'No students are currently below the threshold.',
              );
            }
            return Column(
              children: students
                  .map(
                    (st) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${st.studentName} (${st.classSection})',
                            style: textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            '${st.admissionNumber} • '
                            '${st.attendedDays.toStringAsFixed(1)} / ${st.markedDays} days',
                          ),
                          trailing: StatusChip(
                            status: StatusType.absent,
                            label: '${st.percentage.toStringAsFixed(1)}%',
                          ),
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
  }
}
