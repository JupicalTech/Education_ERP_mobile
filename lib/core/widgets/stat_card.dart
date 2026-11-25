import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

enum StatTone { primary, success, warning, error, info }

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.tone = StatTone.primary,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final StatTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    final (fg, bg) = switch (tone) {
      StatTone.primary => (colorScheme.primary, colorScheme.primaryContainer),
      StatTone.success => (semantic.success, semantic.successContainer),
      StatTone.warning => (semantic.warning, semantic.warningContainer),
      StatTone.error => (semantic.error, semantic.errorContainer),
      StatTone.info => (semantic.info, semantic.infoContainer),
    };

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: textTheme.headlineSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
