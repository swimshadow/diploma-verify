import 'package:flutter/material.dart';

/// Reusable anti-fraud indicator widget.
///
/// Shows a color-coded score bar with verdict and optional warnings.
class AntiFraudBadge extends StatelessWidget {
  final double score; // 0.0 – 1.0
  final String verdict;
  final List<String> warnings;

  const AntiFraudBadge({
    super.key,
    required this.score,
    required this.verdict,
    this.warnings = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color(score);
    final pct = (score * 100).toInt();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Icon(Icons.shield_outlined, color: color, size: 22),
                const SizedBox(width: 8),
                Text('Антифрод-анализ',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$pct%',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: color, fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: score,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: color,
              ),
            ),

            const SizedBox(height: 12),

            // Verdict
            Text(verdict,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: color, fontWeight: FontWeight.w500)),

            // Warnings
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: Colors.orange, size: 18),
                        const SizedBox(width: 6),
                        Text('Предупреждения',
                            style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...warnings.map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Icon(Icons.circle,
                                    size: 5, color: Colors.orange.shade700),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(w,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            color: Colors.orange.shade900)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _color(double s) {
    if (s >= 0.7) return Colors.green;
    if (s >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
