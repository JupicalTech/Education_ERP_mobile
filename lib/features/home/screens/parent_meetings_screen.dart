import 'package:flutter/material.dart';
import 'package:school_attendance/core/models/meeting_model.dart';
import 'package:school_attendance/shared/widgets/parent_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────
// Parent Meetings Screen  (list)
// ─────────────────────────────────────────────────────────────

class ParentMeetingsScreen extends StatelessWidget {
  final List<MeetingModel> meetings;
  const ParentMeetingsScreen({super.key, required this.meetings});

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Meetings',
      headerColor: const Color(0xFF25A667),
      body: meetings.isEmpty
          ? const EmptyState(
              icon: Icons.event_outlined,
              message: 'No meetings scheduled',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Summary chips ──────────────────────────
                  _MeetingSummary(meetings: meetings),
                  const SizedBox(height: 20),

                  const Text(
                    'All Meetings',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D23),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Table ──────────────────────────────────
                  _MeetingsTable(meetings: meetings),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Summary row of status counts
// ─────────────────────────────────────────────────────────────

class _MeetingSummary extends StatelessWidget {
  final List<MeetingModel> meetings;
  const _MeetingSummary({required this.meetings});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{
      'New':         meetings.where((m) => m.state == 'draft').length,
      'Ongoing':     meetings.where((m) => m.state == 'ongoing').length,
      'Conducted':   meetings.where((m) => m.state == 'conducted').length,
      'Rescheduled': meetings.where((m) => m.state == 'rescheduled').length,
      'Cancelled':   meetings.where((m) => m.state == 'cancel').length,
    };

    final colors = <String, Color>{
      'New':         const Color(0xFF757575),
      'Ongoing':     const Color(0xFFF57C00),
      'Conducted':   const Color(0xFF2E7D32),
      'Rescheduled': const Color(0xFF1565C0),
      'Cancelled':   const Color(0xFFC62828),
    };

    // Only show states that have at least 1 meeting
    final active = counts.entries.where((e) => e.value > 0).toList();
    if (active.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: active.map((e) {
        final color = colors[e.key]!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${e.value}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                e.key,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Meetings Table  (tapping a row → detail)
// ─────────────────────────────────────────────────────────────

class _MeetingsTable extends StatelessWidget {
  final List<MeetingModel> meetings;
  const _MeetingsTable({required this.meetings});

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
            columns: const ['Topic', 'Student', 'Date', 'Status', ''],
            flexes: const [3, 3, 2, 2, 1],
          ),
          ...meetings.asMap().entries.map((e) {
            final idx = e.key;
            final m = e.value;
            final isLast = idx == meetings.length - 1;

            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _MeetingDetailScreen(meeting: m),
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
                  NameCell(m.topic ?? '—'),
                  TDCell(m.studentName ?? '—'),
                  TDCell(_formatDate(m.startDate)),
                  StatusBadge(
                    label: m.stateLabel,
                    color: _stateColor(m.state),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: Color(0xFF25A667)),
                ],
                flexes: const [3, 3, 2, 2, 1],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    // raw is "2026-05-13 11:30:00" — return just the date part
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'ongoing':     return const Color(0xFFF57C00);
      case 'conducted':   return const Color(0xFF2E7D32);
      case 'rescheduled': return const Color(0xFF1565C0);
      case 'cancel':      return const Color(0xFFC62828);
      case 'draft':
      default:            return const Color(0xFF757575);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Meeting Detail Screen
// ─────────────────────────────────────────────────────────────

class _MeetingDetailScreen extends StatelessWidget {
  final MeetingModel meeting;
  const _MeetingDetailScreen({required this.meeting});

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: meeting.meetingSeq.isNotEmpty ? meeting.meetingSeq : 'Meeting',
      headerColor: const Color(0xFF25A667),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status badge ───────────────────────────────
            StatusBadge(
              label: meeting.stateLabel,
              color: _stateColor(meeting.state),
            ),
            const SizedBox(height: 16),

            // ── Info card ──────────────────────────────────
            Container(
              width: double.infinity,
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
                  _InfoRow('Reference', meeting.meetingSeq),
                  _InfoRow('Topic', meeting.topic ?? '—'),
                  _InfoRow('Student', meeting.studentName ?? '—'),
                  _InfoRow('Standard', meeting.standardName ?? '—'),
                  _InfoRow('Faculty', meeting.facultyName ?? '—'),
                  const Divider(height: 24),
                  _InfoRow('Date', _formatDate(meeting.startDate)),
                  _InfoRow('Start Time', _formatTime(meeting.startDate)),
                  _InfoRow('End Time', _formatTime(meeting.endDate)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';

    try {
      // Odoo sends UTC datetime without 'Z' — append it so Dart parses it as UTC
      final utc = DateTime.parse(
        raw.endsWith('Z') ? raw : '${raw}Z',
      );
      // Convert to IST (+5:30)
      final ist = utc.add(const Duration(hours: 5, minutes: 30));

      final hour = ist.hour;
      final minute = ist.minute.toString().padLeft(2, '0');
      final isAM = hour < 12;
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;

      return '$hour12:$minute ${isAM ? 'AM' : 'PM'}';
    } catch (e) {
      return '—';
    }
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'ongoing':     return const Color(0xFFF57C00);
      case 'conducted':   return const Color(0xFF2E7D32);
      case 'rescheduled': return const Color(0xFF1565C0);
      case 'cancel':      return const Color(0xFFC62828);
      case 'draft':
      default:            return const Color(0xFF757575);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Info row widget
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
            width: 95,
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