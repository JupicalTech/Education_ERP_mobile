import 'package:flutter/material.dart';
import 'package:school_attendance/core/models/fees_model.dart';
import 'package:school_attendance/shared/widgets/parent_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────
// Fees Detail Screen
// ─────────────────────────────────────────────────────────────

class ParentFeesScreen extends StatelessWidget {
  final List<FeesModel> fees;
  const ParentFeesScreen({super.key, required this.fees});

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Fees',
      headerColor: const Color(0xFF25A667),
      body: fees.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_outlined,
              message: 'No fees records found',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _FeesTable(fees: fees),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Fees Table
// ─────────────────────────────────────────────────────────────

class _FeesTable extends StatelessWidget {
  final List<FeesModel> fees;
  const _FeesTable({required this.fees});

  Color _stateColor(String state) {
    switch (state.toLowerCase()) {
      case 'paid':
        return const Color(0xFF2E7D32);
      case 'partial':
        return const Color(0xFFF57C00);
      case 'unpaid':
      default:
        return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: tableContainerDecoration(),
      child: Column(
        children: [
          TableHeader(
            color: const Color(0xFF25A667),
            columns: const ['Student', 'Receipt', 'Year', 'Status'],
            flexes: const [3, 3, 2, 2],
          ),
          ...fees.asMap().entries.map((e) {
            final idx = e.key;
            final f = e.value;
            final isLast = idx == fees.length - 1;
            return TableRowWidget(
              isEven: idx.isEven,
              isLast: isLast,
              evenColor: const Color.fromARGB(255, 248, 246, 218),
              cells: [
                TDCell(f.studentName ?? '—'),
                TDCell(f.receiptNumber),
                TDCell(f.year ?? '—'),
                StatusBadge(
                  label: f.state,
                  color: _stateColor(f.state),
                ),
              ],
              flexes: const [3, 3, 2, 2],
            );
          }),
        ],
      ),
    );
  }
}