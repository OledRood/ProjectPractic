import 'package:flutter/material.dart';

class MetricsCard extends StatelessWidget {
  const MetricsCard({
    super.key,
    required this.metrics,
    required this.videoWidget,
  });

  final Map<String, dynamic>? metrics;
  final Widget videoWidget;

  /// Форматирование названия метрики для отображения
  String _formatMetricName(String key) {
    switch (key) {
      case 'elbow_angle':
        return 'Угол локтя';
      case 'torso_angle':
        return 'Угол туловища';
      case 'knee_angle':
        return 'Угол колена';
      case 'shoulders_high':
        return 'Плечи выше локтей';
      default:
        return key;
    }
  }

  /// Форматирование значения метрики
  String _formatMetricValue(dynamic value) {
    if (value is bool) {
      return value ? 'Да' : 'Нет';
    } else if (value is double) {
      return '${value.toStringAsFixed(1)}°';
    } else if (value is int) {
      return '$value°';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (metrics == null || metrics!.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.straighten_rounded,
                size: 32,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Измеренные углы',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics!.entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatMetricName(entry.key),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMetricValue(entry.value),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          videoWidget,
        ],
      ),
    );
  }
}
