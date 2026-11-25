import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum StatusType {
  present('Present'),
  absent('Absent'),
  late('Late'),
  halfDay('Half Day'),
  paid('Paid'),
  pending('Pending'),
  partial('Partial'),
  overdue('Overdue'),
  info('Info');

  const StatusType(this.defaultLabel);
  final String defaultLabel;
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.label,
  });

  final StatusType status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    final (fg, bg) = switch (status) {
      StatusType.present || StatusType.paid => (
        semantic.success,
        semantic.successContainer,
      ),
      StatusType.late || StatusType.pending || StatusType.partial => (
        semantic.warning,
        semantic.warningContainer,
      ),
      StatusType.absent || StatusType.overdue => (
        semantic.error,
        semantic.errorContainer,
      ),
      StatusType.halfDay || StatusType.info => (
        semantic.info,
        semantic.infoContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label ?? status.defaultLabel,
        style: textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
