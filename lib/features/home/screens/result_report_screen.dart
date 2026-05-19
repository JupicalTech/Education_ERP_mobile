import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_attendance/core/models/result_model.dart';
import '../../../core/api/odoo_client.dart';
import '../../auth/screens/auth_provider.dart';

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

final resultReportProvider =
    FutureProvider.autoDispose<List<ResultModel>>((ref) async {
  final client = ref.read(odooClientProvider);
  return _fetchResultReport(client);
});

Future<List<ResultModel>> _fetchResultReport(OdooClient client) async {
  // Step 1: fetch student.result records for the logged-in user
  // Odoo's record rules + session handle filtering by parent automatically
  final resultRecords = await client.callKw(
    model: 'student.result',
    method: 'search_read',
    args: [[]], // no extra domain — Odoo session filters by logged-in parent
    kwargs: {
      'fields': [
        'student_id',
        'exam_id',
        'standard',
        'division',
        'academic_year',
        'percentage',
        'total_mark',
        'total_mark_scored',
        'grade_id',
        'pass_fail_full',
        'subject_line',
      ],
    },
  );

  if (resultRecords is! List) return [];

  final List<ResultModel> results = [];

  for (final rec in resultRecords) {
    if (rec is! Map<String, dynamic>) continue;

    final rawLineIds = rec['subject_line'];
    if (rawLineIds is! List || rawLineIds.isEmpty) continue;

    final lineIds = rawLineIds.whereType<int>().toList();

    // Step 2: fetch subject line details
    final lineRecords = await client.callKw(
      model: 'result.subject.line',
      method: 'search_read',
      args: [
        [
          ['id', 'in', lineIds],
        ]
      ],
      kwargs: {
        'fields': [
          'subject_id',
          'mark',
          'pass_mark',
          'mark_scored',
          'grade_id',
          'pass_or_fail',
          'date',
        ],
      },
    );

    final lines = <ResultSubjectLine>[];
    if (lineRecords is List) {
      for (final line in lineRecords) {
        if (line is Map<String, dynamic>) {
          lines.add(ResultSubjectLine.fromJson(line));
        }
      }
    }

    results.add(ResultModel.fromJson(rec, subjectLines: lines));
  }

  return results;
}

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────

class ResultReportScreen extends ConsumerWidget {
  const ResultReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(resultReportProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Result Report'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: resultAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
        ),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(resultReportProvider),
        ),
        data: (results) {
          if (results.isEmpty) return const _EmptyView();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) =>
                _ResultCard(result: results[index]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Result Card
// ─────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final ResultModel result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(result: result),
          _InfoRow(result: result),
          const Divider(height: 1, color: Color(0xFFE8ECF0)),
          _SubjectTable(result: result),
          _SummaryFooter(result: result),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card Header
// ─────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final ResultModel result;
  const _CardHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    final isPassed = result.isPassed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isPassed
            ? const Color(0xFF1565C0).withOpacity(0.06)
            : Colors.red.withOpacity(0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Avatar initial
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPassed
                  ? const Color(0xFF1565C0).withOpacity(0.15)
                  : Colors.red.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                result.studentName.isNotEmpty
                    ? result.studentName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isPassed ? const Color(0xFF1565C0) : Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.studentName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D23),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.examName ?? 'Exam',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // Pass / Fail badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isPassed ? const Color(0xFF2E7D32) : Colors.red.shade600,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPassed ? 'PASS' : 'FAIL',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Info Row (standard / division / year)
// ─────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final ResultModel result;
  const _InfoRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (result.standardName != null)
            _InfoChip(icon: Icons.school_outlined, label: result.standardName!),
          if (result.divisionName != null)
            _InfoChip(icon: Icons.group_outlined, label: 'Div: ${result.divisionName}'),
          if (result.academicYear != null)
            _InfoChip(icon: Icons.calendar_month_outlined, label: result.academicYear!),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Subject Table (horizontal scroll)
// ─────────────────────────────────────────────

class _SubjectTable extends StatelessWidget {
  final ResultModel result;
  const _SubjectTable({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.subjectLines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No subject data available.',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder(
          horizontalInside: BorderSide(color: const Color(0xFFE8ECF0)),
        ),
        children: [
          // Header
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF7F9FC)),
            children: [
              _tableHeader('Subject'),
              _tableHeader('Total'),
              _tableHeader('Pass Mark'),
              _tableHeader('Scored'),
              _tableHeader('Grade'),
              _tableHeader('Status'),
            ],
          ),
          // Data rows — uses ResultSubjectLine fields directly
          for (final sub in result.subjectLines)
            TableRow(
              children: [
                _tableCell(sub.subjectName, isLabel: true),
                _tableCell(sub.mark.toStringAsFixed(0)),
                _tableCell(sub.passMark.toStringAsFixed(0)),
                _tableCell(sub.markScored.toStringAsFixed(0), isBold: true),
                _tableCell(sub.grade ?? '-'),
                _StatusCell(passed: sub.passOrFail),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _tableCell(String value,
      {bool isLabel = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBold
              ? FontWeight.w700
              : isLabel
                  ? FontWeight.w500
                  : FontWeight.w400,
          color: isLabel
              ? const Color(0xFF1A1D23)
              : const Color(0xFF374151),
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  final bool passed;
  const _StatusCell({required this.passed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: passed
              ? const Color(0xFF2E7D32).withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          passed ? 'Pass' : 'Fail',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: passed ? const Color(0xFF2E7D32) : Colors.red.shade700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Summary Footer
// ─────────────────────────────────────────────

class _SummaryFooter extends StatelessWidget {
  final ResultModel result;
  const _SummaryFooter({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: 'Total Obtained',
            // Uses totalMarkScored and subjectTotal getter
            value:
                '${result.totalMarkScored.toStringAsFixed(0)} / ${result.subjectTotal.toStringAsFixed(0)}',
            color: const Color(0xFF1565C0),
          ),
          _divider(),
          _SummaryItem(
            label: 'Percentage',
            value: result.isPassed
                ? '${result.percentage.toStringAsFixed(2)}%'
                : '-',
            color: const Color(0xFF6A1B9A),
          ),
          _divider(),
          _SummaryItem(
            label: 'Grade',
            // Uses grade field added to ResultModel
            value: result.grade ?? '-',
            color: const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: const Color(0xFFE8ECF0),
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty & Error States
// ─────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Result data will appear here once available.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 14),
            Text(
              'Failed to load results',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}