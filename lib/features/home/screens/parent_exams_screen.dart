import 'package:flutter/material.dart';
import 'package:school_attendance/core/models/exam_model.dart';
import 'package:school_attendance/shared/widgets/parent_shared_widgets.dart';


// ─────────────────────────────────────────────────────────────
// Exams Detail Screen
// ─────────────────────────────────────────────────────────────

class ParentExamsScreen extends StatelessWidget {
  final List<ExamModel> exams;
  const ParentExamsScreen({super.key, required this.exams});

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Exams',
      headerColor: const Color(0xFF25A667),
      body: exams.isEmpty
          ? const EmptyState(
              icon: Icons.assignment_outlined,
              message: 'No exams found for your students',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _ExamTable(exams: exams),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Exam Table
// ─────────────────────────────────────────────────────────────

class _ExamTable extends StatelessWidget {
  final List<ExamModel> exams;
  const _ExamTable({required this.exams});

  Color _stateColor(String state) {
    switch (state.toLowerCase()) {
      case 'ongoing':
        return const Color(0xFF1565C0);
      case 'close':
        return const Color(0xFF2E7D32);
      case 'cancel':
        return const Color(0xFFC62828);
      case 'draft':
      default:
        return const Color(0xFFF57C00);
    }
  }

  String _stateLabel(String state) {
    switch (state.toLowerCase()) {
      case 'ongoing':
        return 'On Going';
      case 'close':
        return 'Closed';
      case 'cancel':
        return 'Cancelled';
      case 'draft':
      default:
        return 'Draft';
    }
  }

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
            columns: const ['Exam', 'Start', 'End', 'Status'],
            flexes: const [3, 2, 2, 2],
          ),
          ...exams.asMap().entries.map((e) {
            final idx = e.key;
            final exam = e.value;
            final isLast = idx == exams.length - 1;
            return TableRowWidget(
              isEven: idx.isEven,
              isLast: isLast,
              evenColor: const Color.fromARGB(255, 248, 246, 218),
              cells: [
                NameCell(exam.name),
                TDCell(exam.startDate ?? '—'),
                TDCell(exam.endDate ?? '—'),
                StatusBadge(
                  label: _stateLabel(exam.state),
                  color: _stateColor(exam.state),
                ),
              ],
              flexes: const [3, 2, 2, 2],
            );
          }),
        ],
      ),
    );
  }
}