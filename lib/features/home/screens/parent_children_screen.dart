import 'package:flutter/material.dart';
import 'package:school_attendance/core/models/student_model.dart';
import 'package:school_attendance/shared/widgets/parent_shared_widgets.dart';


// ─────────────────────────────────────────────────────────────
// Children Detail Screen
// ─────────────────────────────────────────────────────────────

class ParentChildrenScreen extends StatelessWidget {
  final List<StudentModel> students;
  const ParentChildrenScreen({super.key, required this.students});

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'My Children',
      headerColor: const Color(0xFF25A667),
      body: students.isEmpty
          ? const EmptyState(
              icon: Icons.child_care_outlined,
              message: 'No students linked to your account',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _StudentsTable(students: students),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Students Table
// ─────────────────────────────────────────────────────────────

class _StudentsTable extends StatelessWidget {
  final List<StudentModel> students;
  const _StudentsTable({required this.students});

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
            columns: const ['Name', 'Standard', 'Division', 'Academic Year'],
            flexes: const [3, 2, 2, 3],
          ),
          ...students.asMap().entries.map((e) {
            final idx = e.key;
            final s = e.value;
            final isLast = idx == students.length - 1;
            return TableRowWidget(
              isEven: idx.isEven,
              isLast: isLast,
              evenColor: const Color.fromARGB(255, 248, 246, 218),
              cells: [
                NameCell(s.name),
                TDCell(s.standardName ?? '—'),
                TDCell(s.divisionName ?? '—'),
                TDCell(s.academicYear ?? '—'),
              ],
              flexes: const [3, 2, 2, 3],
            );
          }),
        ],
      ),
    );
  }
}