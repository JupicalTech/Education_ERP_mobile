import 'package:flutter/material.dart';
import 'package:school_attendance/core/models/attendance_model.dart';
import 'package:school_attendance/shared/widgets/parent_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────
// Parent Attendance Screen  (list of sessions)
// ─────────────────────────────────────────────────────────────

class ParentAttendanceScreen extends StatelessWidget {
  final List<AttendanceModel> attendance;
  const ParentAttendanceScreen({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Attendance',
      headerColor: const Color(0xFF25A667),
      body: attendance.isEmpty
          ? const EmptyState(
              icon: Icons.calendar_today_outlined,
              message: 'No attendance records found',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Summary cards per student ──────────────
                  _AttendanceSummary(attendance: attendance),
                  const SizedBox(height: 20),

                  // ── Session list ───────────────────────────
                  const Text(
                    'Attendance Records',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D23),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AttendanceTable(attendance: attendance),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Summary cards (present / absent / late per student)
// ─────────────────────────────────────────────────────────────

class _AttendanceSummary extends StatelessWidget {
  final List<AttendanceModel> attendance;
  const _AttendanceSummary({required this.attendance});

  @override
  Widget build(BuildContext context) {
    // Build per-student summary from all lines across all sessions
    final Map<int, _StudentStat> stats = {};
    for (final session in attendance) {
      for (final line in session.lines) {
        if (line.studentId == null) continue;
        stats.putIfAbsent(
          line.studentId!,
          () => _StudentStat(name: line.studentName),
        );
        final s = stats[line.studentId!]!;
        s.total++;
        if (line.present) s.present++;
        if (line.absenceReason || line.absenceNoreason) s.absent++;
        if (line.late) s.late++;
      }
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1D23),
          ),
        ),
        const SizedBox(height: 12),
        ...stats.values.map((s) => _StudentSummaryCard(stat: s)),
      ],
    );
  }
}

class _StudentStat {
  final String name;
  int present = 0;
  int absent = 0;
  int late = 0;
  int total = 0;
  _StudentStat({required this.name});
}

class _StudentSummaryCard extends StatelessWidget {
  final _StudentStat stat;
  const _StudentSummaryCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final pct = stat.total > 0
        ? (stat.present * 100 / stat.total).round()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF25A667).withOpacity(0.3)),
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
          // Student name
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 16, color: Color(0xFF25A667)),
              const SizedBox(width: 6),
              Text(
                stat.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D23),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _StatChip(
                  label: 'Present',
                  value: stat.present,
                  color: const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'Absent',
                  value: stat.absent,
                  color: const Color(0xFFC62828)),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'Late',
                  value: stat.late,
                  color: const Color(0xFFF57C00)),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stat.total > 0 ? stat.present / stat.total : 0,
              minHeight: 7,
              backgroundColor: const Color(0xFFE8ECF0),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF25A667)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$pct% attendance (${stat.total} sessions)',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Attendance Table  (tapping a row → session detail)
// ─────────────────────────────────────────────────────────────

class _AttendanceTable extends StatelessWidget {
  final List<AttendanceModel> attendance;
  const _AttendanceTable({required this.attendance});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: tableContainerDecoration(
        borderColor: const Color.fromARGB(255, 248, 246, 218),
      ),
      child: Column(
        children: [
          TableHeader(
            color: const Color(0xFF25A667),
            columns: const ['Date', 'Standard', 'Div', 'Subject(s)', ''],
            flexes: const [3, 2, 1, 4, 1],
          ),
          ...attendance.asMap().entries.map((e) {
            final idx = e.key;
            final session = e.value;
            final isLast = idx == attendance.length - 1;

            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      _AttendanceSessionDetail(session: session),
                ),
              ),
              borderRadius: isLast
                  ? const BorderRadius.vertical(bottom: Radius.circular(13))
                  : null,
              child: TableRowWidget(
                isEven: idx.isEven,
                isLast: isLast,
                evenColor: const Color.fromARGB(255, 248, 246, 218),
                cells: [
                  TDCell(session.date),
                  TDCell(session.standardName ?? '—'),
                  TDCell(session.divisionName ?? '—'),
                  TDCell(session.subjects.isEmpty
                      ? '—'
                      : session.subjects.join(', ')),
                  const Icon(Icons.chevron_right,
                      size: 18, color: Color(0xFF25A667)),
                ],
                flexes: const [3, 2, 1, 4, 1],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Attendance Session Detail Screen
// ─────────────────────────────────────────────────────────────

class _AttendanceSessionDetail extends StatelessWidget {
  final AttendanceModel session;
  const _AttendanceSessionDetail({required this.session});

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Session Detail',
      headerColor: const Color(0xFF25A667),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Session info card ──────────────────────────
            Container(
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
                children: [
                  _InfoRow('Date', session.date),
                  _InfoRow('Faculty', session.facultyName ?? '—'),
                  _InfoRow('Standard', session.standardName ?? '—'),
                  _InfoRow('Division', session.divisionName ?? '—'),
                  if (session.subjects.isNotEmpty)
                    _InfoRow('Subjects', session.subjects.join(', ')),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Children lines ─────────────────────────────
            const Text(
              "Your Children's Attendance",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D23),
              ),
            ),
            const SizedBox(height: 12),

            if (session.lines.isEmpty)
              const EmptyState(
                icon: Icons.people_outline,
                message: 'No attendance data for your children in this session',
              )
            else
              Container(
                decoration: tableContainerDecoration(),
                child: Column(
                  children: [
                    TableHeader(
                      color: const Color(0xFF25A667),
                      columns: const ['Student', 'Roll', 'Status'],
                      flexes: const [4, 2, 3],
                    ),
                    ...session.lines.asMap().entries.map((e) {
                      final idx = e.key;
                      final line = e.value;
                      final isLast = idx == session.lines.length - 1;
                      return TableRowWidget(
                        isEven: idx.isEven,
                        isLast: isLast,
                        evenColor: const Color.fromARGB(255, 248, 246, 218),
                        cells: [
                          NameCell(line.studentName),
                          TDCell(line.rollNo ?? '—'),
                          StatusBadge(
                            label: line.statusLabel,
                            color: _statusColor(line),
                          ),
                        ],
                        flexes: const [4, 2, 3],
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(AttendanceLine line) {
    if (line.withdraw) return const Color(0xFF424242);
    if (line.absenceReason) return const Color(0xFFF57C00);
    if (line.absenceNoreason) return const Color(0xFFC62828);
    if (line.present && line.late) return const Color(0xFF1565C0);
    if (line.present) return const Color(0xFF2E7D32);
    return Colors.grey;
  }
}

// ─────────────────────────────────────────────────────────────
// Info row for session detail card
// ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D23),
              ),
            ),
          ),
        ],
      ),
    );
  }
}