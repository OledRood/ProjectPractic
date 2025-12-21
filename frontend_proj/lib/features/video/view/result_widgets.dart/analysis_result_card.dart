import 'package:flutter/material.dart';

class AnalysisResultCard extends StatelessWidget {
  const AnalysisResultCard({
    super.key,
    required this.confidence,
    required this.exercise,
  });

  final double? confidence;
  final String? exercise;

  String _getExerciseDisplayName(String? exercise) {
    if (exercise == null) return 'Не определено';
    switch (exercise) {
      case 'pushup':
        return 'Отжимания';
      case 'pullup':
        return 'Подтягивания';
      case 'unknown':
        return 'Не определено';
      default:
        return exercise;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (exercise == null) {
      return SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          // Легкое свечение
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                size: 32,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Результаты анализа',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildResultRow(
            context,
            'Тип упражнения',
            _getExerciseDisplayName(exercise),
            Icons.fitness_center_rounded,
          ),
          const SizedBox(height: 12),
          _buildResultRow(
            context,
            'Уверенность модели',
            confidence != null
                ? '${confidence!.toStringAsFixed(1)}%'
                : 'Не определено',
            Icons.speed_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
