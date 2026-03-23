import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/admin_bloc.dart';
import '../../bloc/admin_event.dart';
import '../../bloc/admin_state.dart';
import '../../data/models/admin_models.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class AdminDiplomaReviewScreen extends StatelessWidget {
  final String diplomaId;
  const AdminDiplomaReviewScreen({super.key, required this.diplomaId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Ручная проверка диплома',
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is! AdminLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final diploma = state.diplomas
              .cast<AdminDiploma?>()
              .firstWhere((d) => d!.id == diplomaId, orElse: () => null);

          if (diploma == null) {
            return const Center(child: Text('Диплом не найден'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Status banner ──
                    _StatusBanner(status: diploma.status),
                    const SizedBox(height: 24),

                    // ── Two-column layout ──
                    LayoutBuilder(builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: _FilePreview(
                                    diploma: diploma, theme: theme)),
                            const SizedBox(width: 20),
                            Expanded(
                                child: _DiplomaInfo(
                                    diploma: diploma, theme: theme)),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _FilePreview(diploma: diploma, theme: theme),
                          const SizedBox(height: 20),
                          _DiplomaInfo(diploma: diploma, theme: theme),
                        ],
                      );
                    }),

                    const SizedBox(height: 24),

                    // ── OCR result ──
                    Text('Результат OCR',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.colorScheme.outlineVariant),
                      ),
                      child: SelectableText(
                        diploma.ocrText ?? '[OCR результат отсутствует]',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── DB match ──
                    Text('Запись в базе данных',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: diploma.trustScore >= 0.7
                            ? Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      const Text('Найдено совпадение',
                                          style: TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: Colors.green)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _Field('Владелец', diploma.holderName),
                                  _Field('ВУЗ', diploma.universityName),
                                  _Field('Номер', diploma.diplomaNumber),
                                  _Field('Совпадение',
                                      '${(diploma.trustScore * 100).toInt()}%'),
                                ],
                              )
                            : Row(
                                children: [
                                  const Icon(Icons.help_outline,
                                      color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      diploma.trustScore > 0.3
                                          ? 'Частичное совпадение (${(diploma.trustScore * 100).toInt()}%). Требуется ручная верификация.'
                                          : 'Совпадений в базе не найдено. Trust Score: ${(diploma.trustScore * 100).toInt()}%',
                                      style: TextStyle(
                                          color: diploma.trustScore > 0.3
                                              ? Colors.orange
                                              : Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Action buttons ──
                    if (diploma.status != AdminDiplomaStatus.verified)
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                context.read<AdminBloc>().add(
                                    AdminVerifyDiploma(diploma.id));
                                _showSnack(
                                    context, 'Диплом подтверждён');
                              },
                              icon: const Icon(Icons.verified),
                              label: const Text('Подтвердить'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize:
                                    const Size.fromHeight(48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.read<AdminBloc>().add(
                                    AdminRejectDiploma(diploma.id));
                                _showSnack(
                                    context, 'Диплом отклонён');
                              },
                              icon: const Icon(Icons.cancel,
                                  color: Colors.red),
                              label: const Text('Отклонить',
                                  style:
                                      TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.red),
                                minimumSize:
                                    const Size.fromHeight(48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.read<AdminBloc>().add(
                                    AdminRetryDiploma(diploma.id));
                                _showSnack(context,
                                    'Отправлен на повторную проверку');
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('На повтор'),
                              style: OutlinedButton.styleFrom(
                                minimumSize:
                                    const Size.fromHeight(48),
                              ),
                            ),
                          ),
                        ],
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

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }
}

class _StatusBanner extends StatelessWidget {
  final AdminDiplomaStatus status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon, text) = switch (status) {
      AdminDiplomaStatus.verified =>
        (Colors.green, Icons.verified, 'Подтверждён'),
      AdminDiplomaStatus.rejected =>
        (Colors.red, Icons.cancel, 'Отклонён'),
      AdminDiplomaStatus.disputed =>
        (Colors.orange, Icons.warning_amber, 'Спорный — требуется ручная проверка'),
      AdminDiplomaStatus.pendingReview =>
        (Colors.blue, Icons.hourglass_top, 'Ожидает проверки'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(text,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  final AdminDiploma diploma;
  final ThemeData theme;
  const _FilePreview({required this.diploma, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Файл диплома',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description,
                    size: 48, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 8),
                Text('${diploma.diplomaNumber}.pdf',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text('(превью файла)',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DiplomaInfo extends StatelessWidget {
  final AdminDiploma diploma;
  final ThemeData theme;
  const _DiplomaInfo({required this.diploma, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Информация',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Field('Владелец', diploma.holderName),
                _Field('ВУЗ', diploma.universityName),
                _Field('Номер', diploma.diplomaNumber),
                _Field('Trust Score',
                    '${(diploma.trustScore * 100).toInt()}%'),
                _Field('Загружен',
                    '${diploma.uploadedAt.day.toString().padLeft(2, '0')}.${diploma.uploadedAt.month.toString().padLeft(2, '0')}.${diploma.uploadedAt.year}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
