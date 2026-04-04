import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/mock_data.dart';
import '../../data/models/verification_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class VerifyResultScreen extends StatelessWidget {
  final String resultId;
  const VerifyResultScreen({super.key, required this.resultId});

  @override
  Widget build(BuildContext context) {
    final result = mockVerificationResults
        .where((r) => r.id == resultId)
        .firstOrNull;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Результат не найден')),
      );
    }

    return _ResultView(result: result);
  }
}

class _ResultView extends StatelessWidget {
  final VerificationResult result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return DashboardScaffold(
      title: 'Результат проверки',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Verdict Banner ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (result.isAuthentic ? Colors.green : Colors.red)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (result.isAuthentic ? Colors.green : Colors.red)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        result.isAuthentic
                            ? Icons.verified
                            : Icons.dangerous,
                        color:
                            result.isAuthentic ? Colors.green : Colors.red,
                        size: 48,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.isAuthentic
                                  ? 'Диплом подлинный'
                                  : 'Подозрение на подделку',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: result.isAuthentic
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Проверено: ${dateFormat.format(result.verifiedAt)} · ${result.method.label}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Diploma Data ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Данные диплома',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _InfoRow(
                            label: 'Диплом', value: result.diplomaTitle),
                        _InfoRow(
                            label: 'Владелец', value: result.holderName),
                        _InfoRow(
                            label: 'Университет',
                            value: result.university),
                        _InfoRow(
                            label: 'Специальность',
                            value: result.speciality),
                        _InfoRow(
                            label: 'Номер',
                            value: result.diplomaNumber),
                        _InfoRow(
                            label: 'Дата выдачи',
                            value: dateFormat.format(result.issueDate)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Trust Score + Anti-fraud ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ScoreCard(
                        title: 'Trust Score',
                        score: result.trustScore,
                        color: _trustColor(result.trustScore),
                        description: _trustDescription(result.trustScore),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ScoreCard(
                        title: 'Антифрод',
                        score: result.antifraudScore,
                        color: _antifraudColor(result.antifraudScore),
                        description: result.antifraudVerdict,
                      ),
                    ),
                  ],
                ),

                // ── Warnings ──
                if (result.warnings.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Card(
                    color: Colors.orange.withValues(alpha: 0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber,
                                  color: Colors.orange, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Предупреждения',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...result.warnings.map(
                            (w) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.circle,
                                      size: 6,
                                      color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(w,
                                        style: theme
                                            .textTheme.bodyMedium
                                            ?.copyWith(
                                                color: Colors
                                                    .orange.shade900)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Actions ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Новая проверка'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _trustColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _trustDescription(double score) {
    if (score >= 0.7) return 'Высокий уровень доверия';
    if (score >= 0.4) return 'Средний уровень доверия';
    return 'Низкий уровень доверия';
  }

  Color _antifraudColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final double score;
  final Color color;
  final String description;

  const _ScoreCard({
    required this.title,
    required this.score,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score,
                    strokeWidth: 6,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    color: color,
                  ),
                  Text(
                    '${(score * 100).toInt()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
