import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../bloc/diploma_bloc.dart';
import '../../bloc/diploma_state.dart';
import '../../data/models/diploma_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/anti_fraud_badge.dart';

class DiplomaDetailScreen extends StatelessWidget {
  final String diplomaId;
  const DiplomaDetailScreen({super.key, required this.diplomaId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiplomaBloc, DiplomaState>(
      builder: (context, state) {
        if (state is! DiplomaLoaded) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final diploma = state.allDiplomas.where((d) => d.id == diplomaId).firstOrNull;
        if (diploma == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Диплом не найден')),
          );
        }
        return _DetailView(diploma: diploma);
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  final Diploma diploma;
  const _DetailView({required this.diploma});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');
    final statusColor = _statusColor(diploma.status);

    return DashboardScaffold(
      title: 'Карточка диплома',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.isMobile(context) ? double.infinity : 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(diploma.title,
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(diploma.status.label,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                            label: 'Университет', value: diploma.university),
                        _DetailRow(
                            label: 'Специальность',
                            value: diploma.speciality),
                        _DetailRow(
                            label: 'Номер диплома',
                            value: diploma.diplomaNumber),
                        _DetailRow(
                            label: 'Дата выдачи',
                            value: dateFormat.format(diploma.issueDate)),
                        if (diploma.certificateId != null)
                          _DetailRow(
                              label: 'ID сертификата',
                              value: diploma.certificateId!),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Trust Score
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trust Score',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: diploma.trustScore,
                                    strokeWidth: 6,
                                    backgroundColor: theme
                                        .colorScheme.surfaceContainerHighest,
                                    color: _trustColor(diploma.trustScore),
                                  ),
                                  Text(
                                    '${(diploma.trustScore * 100).toInt()}%',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: _trustColor(
                                                diploma.trustScore)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                _trustDescription(diploma.trustScore),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Anti-fraud indicator
                if (diploma.antifraudVerdict.isNotEmpty)
                  AntiFraudBadge(
                    score: diploma.antifraudScore,
                    verdict: diploma.antifraudVerdict,
                    warnings: diploma.antifraudWarnings,
                  ),

                const SizedBox(height: 20),

                // Timeline
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ход проверки',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        ...List.generate(diploma.timeline.length, (i) {
                          final step = diploma.timeline[i];
                          final isLast = i == diploma.timeline.length - 1;
                          return _TimelineItem(
                            step: step,
                            isLast: isLast,
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                if (diploma.status == DiplomaStatus.verified) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push(
                              '/student/certificate/${diploma.certificateId}'),
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Сертификат'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Share.share(
                                'Проверить мой диплом: ${AppConstants.publicBaseUrl}/verify/${diploma.certificateId}',
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Поделиться'),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(DiplomaStatus s) {
    switch (s) {
      case DiplomaStatus.verified:
        return Colors.green;
      case DiplomaStatus.processing:
      case DiplomaStatus.pending:
        return Colors.orange;
      case DiplomaStatus.revoked:
        return Colors.red;
    }
  }

  Color _trustColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _trustDescription(double score) {
    if (score >= 0.9) return 'Высокий уровень доверия. Диплом подтверждён.';
    if (score >= 0.7) return 'Хороший уровень доверия. Проверка завершена.';
    if (score >= 0.4) return 'Средний уровень. Проверка продолжается.';
    return 'Низкий уровень доверия. Требуется дополнительная проверка.';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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

class _TimelineItem extends StatelessWidget {
  final VerificationStep step;
  final bool isLast;
  const _TimelineItem({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    Color dotColor;
    if (step.isCompleted) {
      dotColor = Colors.green;
    } else if (step.isCurrent) {
      dotColor = Colors.orange;
    } else {
      dotColor = theme.colorScheme.outlineVariant;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                  child: step.isCompleted
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : step.isCurrent
                          ? const Icon(Icons.more_horiz,
                              size: 10, color: Colors.white)
                          : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: step.isCompleted
                          ? Colors.green.withValues(alpha: 0.4)
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: step.isCurrent || step.isCompleted
                              ? FontWeight.w600
                              : FontWeight.normal)),
                  if (step.completedAt != null)
                    Text(dateFormat.format(step.completedAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  if (step.isCurrent)
                    Text('В процессе...',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.orange)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
