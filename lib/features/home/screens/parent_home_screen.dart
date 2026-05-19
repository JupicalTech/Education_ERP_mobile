import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_attendance/core/utils/logger.dart';
import 'package:school_attendance/features/home/screens/parent_meetings_screen.dart';
import 'package:school_attendance/features/home/screens/reports_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/home_widgets.dart';
import '../../auth/screens/auth_provider.dart';
import 'parent_provider.dart';
import 'parent_children_screen.dart';
import 'parent_fees_screen.dart';
import 'parent_exams_screen.dart';
import 'parent_results_screen.dart';
import 'parent_attendance_screen.dart';

// ─────────────────────────────────────────────────────────────
// Parent Home Screen
// ─────────────────────────────────────────────────────────────

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final parentState = ref.watch(parentProvider);

    AppLogger.i(
      'UI state — children: ${parentState.children.length}, '
      'fees: ${parentState.fees.length}, '
      'exams: ${parentState.exams.length}, '
      'results: ${parentState.results.length}, '
      'isLoading: ${parentState.isLoading}',
    );

    // ── Derived counts for subtitle text ──────────────────────
    final unpaidFees =
        parentState.fees.where((f) => f.state.toLowerCase() == 'unpaid').length;
    final paidFees =
        parentState.fees.where((f) => f.state.toLowerCase() == 'paid').length;

    final ongoingExams = parentState.exams
        .where((e) => e.state.toLowerCase() == 'ongoing')
        .length;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(parentProvider.notifier).loadChildren(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(parentProvider.notifier).loadChildren(),
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome card ────────────────────────────────
              WelcomeCard(
                name: auth.userName ?? 'Parent',
                role: 'Parent',
                icon: Icons.family_restroom_outlined,
                color: const Color(0xFF25A667),
              ),
              const SizedBox(height: 28),

              // ── Section label ────────────────────────────────
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D23),
                    ),
              ),
              const SizedBox(height: 14),

              // ── 4 Summary Cards ──────────────────────────────
              if (parentState.isLoading)
                const _LoadingGrid()
              else if (parentState.error != null)
                _ErrorState(
                  error: parentState.error!,
                  onRetry: () =>
                      ref.read(parentProvider.notifier).loadChildren(),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    // ── My Children ──────────────────────────
                    _SummaryCard(
                      title: 'My Children',
                      icon: Icons.school_outlined,
                      color: const Color(0xFF2E7D32),
                      count: parentState.children.length,
                      subtitle: parentState.children.isEmpty
                          ? 'No students linked'
                          : '${parentState.children.length} student${parentState.children.length == 1 ? '' : 's'} enrolled',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentChildrenScreen(
                            students: parentState.children,
                          ),
                        ),
                      ),
                    ),

                    // ── Fees ─────────────────────────────────
                    _SummaryCard(
                      title: 'Fees',
                      icon: Icons.receipt_long_outlined,
                      color: const Color(0xFF2E7D32),
                      count: parentState.fees.length,
                      subtitle: parentState.fees.isEmpty
                          ? 'No records'
                          : '$unpaidFees unpaid · $paidFees paid',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentFeesScreen(
                            fees: parentState.fees,
                          ),
                        ),
                      ),
                    ),

                    // ── Exams ────────────────────────────────
                    _SummaryCard(
                      title: 'Exams',
                      icon: Icons.assignment_outlined,
                      color: const Color(0xFF2E7D32),
                      count: parentState.exams.length,
                      subtitle: parentState.exams.isEmpty
                          ? 'No exams scheduled'
                          : '$ongoingExams ongoing · ${parentState.exams.length - ongoingExams} others',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentExamsScreen(
                            exams: parentState.exams,
                          ),
                        ),
                      ),
                    ),

                    // ── Results ──────────────────────────────
                    _SummaryCard(
                      title: 'Results',
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFF2E7D32),
                      count: parentState.results.length,
                      subtitle: parentState.results.isEmpty
                          ? 'No results yet'
                          : '${parentState.results.length} result${parentState.results.length == 1 ? '' : 's'} available',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentResultsScreen(
                            results: parentState.results,
                          ),
                        ),
                      ),
                    ),

                    _SummaryCard(
                      title: 'Meetings',
                      icon: Icons.event_available_outlined,
                      color: const Color(0xFF2E7D32),
                      count: parentState.meetings.length,
                      subtitle: parentState.meetings.isEmpty
                          ? 'No meetings scheduled'
                          : '${parentState.meetings.length} meeting${parentState.meetings.length == 1 ? '' : 's'}',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentMeetingsScreen(
                            meetings: parentState.meetings,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // ── Attendance full-width card ─────────────────
              if (!parentState.isLoading && parentState.error == null)
                _AttendanceCard(
                  count: parentState.attendance.length,
                  presentCount: parentState.attendance
                      .expand((a) => a.lines)
                      .where((l) => l.present)
                      .length,
                  totalLines: parentState.attendance
                      .expand((a) => a.lines)
                      .length,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentAttendanceScreen(
                        attendance: parentState.attendance,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // ── Reports full-width card ────────────────────────────
              if (!parentState.isLoading && parentState.error == null)
                _ReportsCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Summary Card
// ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final String subtitle;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const Spacer(),
            // Count
            Text(
              '$count',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D23),
              ),
            ),
            const SizedBox(height: 2),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


class _ReportsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ReportsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.download_outlined,
                color: Color(0xFF6A1B9A),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reports',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D23),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Download score summary & attendance',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Color(0xFF6A1B9A),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// Loading / Error
// ─────────────────────────────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: List.generate(4, (_) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8ECF0)),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF25A667),
              strokeWidth: 2.5,
            ),
          ),
        );
      }),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(error,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Attendance full-width card
// ─────────────────────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  final int count;
  final int presentCount;
  final int totalLines;
  final VoidCallback onTap;

  const _AttendanceCard({
    required this.count,
    required this.presentCount,
    required this.totalLines,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalLines > 0
        ? (presentCount * 100 / totalLines).round()
        : 0;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  color: Color(0xFF2E7D32), size: 22),
            ),
            const SizedBox(width: 14),

            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D23),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count == 0
                        ? 'No records found'
                        : '$count session${count == 1 ? '' : 's'} · $presentCount present',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  if (totalLines > 0) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: presentCount / totalLines,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFE8ECF0),
                        valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF25A667)),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$pct% overall attendance',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade400),
                    ),
                  ],
                ],
              ),
            ),

            const Icon(Icons.chevron_right,
                color: Color(0xFF25A667), size: 20),
          ],
        ),
      ),
    );
  }
}