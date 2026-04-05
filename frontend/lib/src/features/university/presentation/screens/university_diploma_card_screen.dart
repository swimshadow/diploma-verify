import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/logging/app_logger.dart';
import '../../bloc/university_bloc.dart';
import '../../bloc/university_event.dart';
import '../../bloc/university_state.dart';
import '../../data/models/registry_diploma_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';
import '../../../../shared/widgets/anti_fraud_badge.dart';
import '../../../../shared/widgets/error_state_widget.dart';

const _tag = 'UniversityDiplomaCardScreen';

class UniversityDiplomaCardScreen extends StatelessWidget {
  final String diplomaId;
  const UniversityDiplomaCardScreen({super.key, required this.diplomaId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd.MM.yyyy');
    final dateTimeFmt = DateFormat('dd.MM.yyyy HH:mm');

    return DashboardScaffold(
      title: 'Карточка диплома',
      body: BlocBuilder<UniversityBloc, UniversityState>(
        builder: (context, state) {
          if (state is UniversityFailure) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<UniversityBloc>().add(UniversityLoadRequested()),
            );
          }
          if (state is! UniversityLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final diploma = state.diplomas
              .cast<RegistryDiploma?>()
              .firstWhere((d) => d!.id == diplomaId, orElse: () => null);

          if (diploma == null) {
            return const Center(child: Text('Диплом не найден'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                          child: Text(
                            diploma.holderFullName
                                .split(' ')
                                .take(2)
                                .map((w) => w[0])
                                .join(),
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(diploma.holderFullName,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                '${diploma.diplomaSeries} ${diploma.diplomaNumber}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme
                                        .colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              _StatusChip(status: diploma.status),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // ── Diploma data ──
                    Text('Данные диплома',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _InfoRow('Факультет', diploma.faculty),
                    _InfoRow('Специальность', diploma.speciality),
                    _InfoRow('Уровень', diploma.educationLevel),
                    _InfoRow('GPA', diploma.gpa.toStringAsFixed(2)),
                    _InfoRow('Дата выдачи', dateFmt.format(diploma.issueDate)),
                    _InfoRow(
                        'Сертификат', diploma.certificateId ?? 'Не выдан'),
                    _InfoRow('Trust Score',
                        '${(diploma.trustScore * 100).toInt()}%'),
                    _InfoRow('Добавлен', dateFmt.format(diploma.createdAt)),

                    // ── Anti-fraud indicator ──
                    if (diploma.antifraudVerdict.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      AntiFraudBadge(
                        score: diploma.antifraudScore,
                        verdict: diploma.antifraudVerdict,
                        warnings: diploma.antifraudWarnings,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Employer verification history ──
                    Text('История проверок работодателями',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    if (diploma.employerChecks.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: theme
                                      .colorScheme.onSurfaceVariant),
                              const SizedBox(width: 12),
                              const Text(
                                  'Этот диплом ещё не проверялся работодателями'),
                            ],
                          ),
                        ),
                      )
                    else
                      ...diploma.employerChecks.map((check) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: (check.isAuthentic
                                        ? Colors.green
                                        : Colors.red)
                                    .withValues(alpha: 0.12),
                                child: Icon(
                                  check.isAuthentic
                                      ? Icons.verified
                                      : Icons.warning,
                                  color: check.isAuthentic
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(check.employerName),
                              subtitle: Text(
                                  dateTimeFmt.format(check.checkedAt)),
                              trailing: Text(
                                check.isAuthentic
                                    ? 'Подлинный'
                                    : 'Сомнительный',
                                style: TextStyle(
                                  color: check.isAuthentic
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )),

                    const SizedBox(height: 32),

                    // ── Revoke ──
                    if (diploma.status != RegistryDiplomaStatus.revoked)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmRevoke(context),
                          icon: const Icon(Icons.block, color: Colors.red),
                          label: const Text('Отозвать диплом',
                              style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmRevoke(BuildContext context) {
    final log = AppLogger.instance;
    log.info(_tag, 'BTN: Отозвать диплом — нажата, diplomaId=$diplomaId');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отозвать диплом?'),
        content: const Text(
            'Это действие пометит диплом как отозванный. '
            'Работодатели будут уведомлены при проверке.'),
        actions: [
          TextButton(
              onPressed: () {
                log.info(_tag, 'BTN: Отмена отзыва диплома');
                Navigator.pop(ctx);
              },
              child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              log.info(_tag, 'BTN: Подтвердить отзыв diplomaId=$diplomaId');
              context.read<UniversityBloc>().add(
                    UniversityRevokeDiploma(diplomaId),
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Диплом отозван'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Отозвать'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final RegistryDiplomaStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      RegistryDiplomaStatus.active => (Colors.green, Icons.verified),
      RegistryDiplomaStatus.revoked => (Colors.red, Icons.block),
      RegistryDiplomaStatus.pendingReview =>
        (Colors.orange, Icons.hourglass_top),
    };

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(status.label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
    );
  }
}
