import 'package:flutter/material.dart';

class TechniqueAssessmentCard extends StatelessWidget {
  final List<String>? techniqueIssues;
  final String? exercise;

  const TechniqueAssessmentCard({
    super.key,
    required this.techniqueIssues,
    required this.exercise,
  });

  /// Склонение слов в зависимости от числа
  String _getPluralForm(int number, String one, String few, String many) {
    final n = number % 100;
    if (n >= 11 && n <= 19) return many;
    final lastDigit = n % 10;
    if (lastDigit == 1) return one;
    if (lastDigit >= 2 && lastDigit <= 4) return few;
    return many;
  }

  @override
  Widget build(BuildContext context) {
    if (exercise == null) {
      return SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: (techniqueIssues?.isEmpty ?? true)
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          // Легкое свечение
          BoxShadow(
            color: (techniqueIssues?.isEmpty ?? true)
                ? colorScheme.primary.withValues(alpha: 0.08)
                : colorScheme.error.withValues(alpha: 0.08),
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
                (techniqueIssues?.isEmpty ?? true)
                    ? Icons.check_circle_rounded
                    : Icons.warning_rounded,
                size: 32,
                color: (techniqueIssues?.isEmpty ?? true)
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Оценка техники',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (techniqueIssues?.isEmpty ?? true) ...[
            // Хорошая техника
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.thumb_up_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Техника идеальна!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Предупреждений не обнаружено',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Есть проблемы с техникой
            Text(
              'Обнаружено ${techniqueIssues!.length} ${_getPluralForm(techniqueIssues!.length, 'проблема', 'проблемы', 'проблем')}:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            ...techniqueIssues!.asMap().entries.map((entry) {
              final index = entry.key;
              final issue = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: colorScheme.onError,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          issue,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
