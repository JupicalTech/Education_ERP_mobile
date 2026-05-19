import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// Shared detail screen scaffold
// ─────────────────────────────────────────────────────────────

class DetailScaffold extends StatelessWidget {
  final String title;
  final Color headerColor;
  final Widget body;

  const DetailScaffold({
    super.key,
    required this.title,
    required this.headerColor,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: body,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared Table Building Blocks
// ─────────────────────────────────────────────────────────────

class TableHeader extends StatelessWidget {
  final Color color;
  final List<String> columns;
  final List<int> flexes;

  const TableHeader({
    super.key,
    required this.color,
    required this.columns,
    required this.flexes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
      ),
      child: Row(
        children: List.generate(columns.length, (i) {
          return Expanded(
            flex: flexes[i],
            child: Text(
              columns[i],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class TableRowWidget extends StatelessWidget {
  final bool isEven;
  final bool isLast;
  final Color evenColor;
  final List<Widget> cells;
  final List<int> flexes;

  const TableRowWidget({
    super.key,
    required this.isEven,
    required this.isLast,
    required this.evenColor,
    required this.cells,
    required this.flexes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : evenColor,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(13))
            : null,
        border: !isLast
            ? const Border(
                bottom: BorderSide(color: Color(0xFFE8ECF0), width: 1))
            : null,
      ),
      child: Row(
        children: List.generate(cells.length, (i) {
          return Expanded(flex: flexes[i], child: cells[i]);
        }),
      ),
    );
  }
}

// ── Cell types ────────────────────────────────────────────────

class NameCell extends StatelessWidget {
  final String text;
  const NameCell(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1D23),
        ),
      );
}

class TDCell extends StatelessWidget {
  final String text;
  const TDCell(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      );
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Table container decoration helper
// ─────────────────────────────────────────────────────────────

BoxDecoration tableContainerDecoration({Color? borderColor}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: borderColor ?? const Color(0xFFE8ECF0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );