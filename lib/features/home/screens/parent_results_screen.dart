import 'package:flutter/material.dart';
import 'package:school_attendance/core/models/result_model.dart';
import 'package:school_attendance/features/home/screens/result_detail_screen.dart';
import 'package:school_attendance/shared/widgets/parent_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────
// Results Detail Screen
// ─────────────────────────────────────────────────────────────

class ParentResultsScreen extends StatelessWidget {
  final List<ResultModel> results;
  const ParentResultsScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Results',
      headerColor: const Color(0xFF25A667),
      body: results.isEmpty
          ? const EmptyState(
              icon: Icons.bar_chart_rounded,
              message: 'No results found for your students',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _ResultsTable(results: results),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Results Table  (tapping a row → ResultDetailScreen)
// ─────────────────────────────────────────────────────────────

class _ResultsTable extends StatelessWidget {
  final List<ResultModel> results;
  const _ResultsTable({required this.results});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: tableContainerDecoration(
        borderColor: const Color.fromARGB(255, 247, 246, 222),
      ),
      child: Column(
        children: [
          TableHeader(
            color: const Color(0xFF25A667),
            columns: const ['Student', 'Exam', 'Std', 'Div', ''],
            flexes: const [3, 3, 2, 2, 1],
          ),
          ...results.asMap().entries.map((e) {
            final idx = e.key;
            final r = e.value;
            final isLast = idx == results.length - 1;

            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultDetailScreen(
                    resultId: r.id,
                    title: '${r.studentName} — ${r.examName ?? "Result"}',
                  ),
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
                  NameCell(r.studentName),
                  TDCell(r.examName ?? '—'),
                  TDCell(r.standardName ?? '—'),
                  TDCell(r.divisionName ?? '—'),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Color(0xFF25A667),
                  ),
                ],
                flexes: const [3, 3, 2, 2, 1],
              ),
            );
          }),
        ],
      ),
    );
  }
}