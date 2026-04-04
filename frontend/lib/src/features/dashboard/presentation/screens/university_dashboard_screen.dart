import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../university/bloc/university_bloc.dart';
import '../../../university/bloc/university_state.dart';
import '../../../university/data/models/import_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class UniversityDashboardScreen extends StatelessWidget {
  const UniversityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Панель университета',
      body: BlocBuilder<UniversityBloc, UniversityState>(
        builder: (context, state) {
          if (state is UniversityLoading || state is UniversityInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is UniversityLoaded) {
            return _DashboardBody(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final UniversityLoaded state;
  const _DashboardBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats ──
              Text('Статистика',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = constraints.maxWidth > 500 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: crossCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        label: 'Дипломов',
                        value: '${state.totalDiplomas}',
                        icon: Icons.school_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      _StatCard(
                        label: 'Активных',
                        value: '${state.activeDiplomas}',
                        icon: Icons.verified,
                        color: Colors.green,
                      ),
                      _StatCard(
                        label: 'Сертификатов',
                        value: '${state.activeCertificates}',
                        icon: Icons.card_membership,
                        color: Colors.teal,
                      ),
                      _StatCard(
                        label: 'Ошибок импорта',
                        value: '${state.totalImportErrors}',
                        icon: Icons.error_outline,
                        color: state.totalImportErrors > 0
                            ? Colors.orange
                            : Colors.grey,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // ── Quick actions ──
              Text('Быстрые действия',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ActionChip(
                    icon: Icons.add_circle_outlined,
                    label: 'Добавить диплом',
                    onTap: () => context.push('/university/diploma-upload'),
                  ),
                  _ActionChip(
                    icon: Icons.upload_file,
                    label: 'Массовый импорт',
                    onTap: () => context.push('/university/import'),
                  ),
                  _ActionChip(
                    icon: Icons.list_alt,
                    label: 'Реестр дипломов',
                    onTap: () => context.push('/university/registry'),
                  ),
                  _ActionChip(
                    icon: Icons.card_membership,
                    label: 'Сертификаты',
                    onTap: () => context.push('/university/certificates'),
                  ),
                  _ActionChip(
                    icon: Icons.settings_outlined,
                    label: 'Профиль вуза',
                    onTap: () => context.push('/university/profile'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Recent imports ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Последние импорты',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.push('/university/import'),
                    child: const Text('Все →'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...state.importJobs.take(3).map(
                    (job) => Card(
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _importColor(job.status)
                              .withValues(alpha: 0.15),
                          child: Icon(
                            _importIcon(job.status),
                            color: _importColor(job.status),
                            size: 20,
                          ),
                        ),
                        title: Text(job.fileName),
                        subtitle: Text(
                            '${job.format.label} · ${job.processedRecords}/${job.totalRecords} записей'),
                        trailing: job.status == ImportStatus.inProgress
                            ? SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  value: job.progress,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                job.status.label,
                                style: TextStyle(
                                  color: _importColor(job.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),

              const SizedBox(height: 32),

              // ── Pending review alert ──
              if (state.pendingDiplomas > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top,
                          color: Colors.orange, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${state.pendingDiplomas} дипломов ожидают рассмотрения',
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Перейдите в реестр для обработки',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.push('/university/registry'),
                        child: const Text('Открыть'),
                      ),
                    ],
                  ),
                ),

              if (state.revokedDiplomas > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.block,
                          color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            '${state.revokedDiplomas} отозванных дипломов',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _importColor(ImportStatus status) {
    switch (status) {
      case ImportStatus.completed:
        return Colors.green;
      case ImportStatus.inProgress:
        return Colors.blue;
      case ImportStatus.failed:
        return Colors.red;
      case ImportStatus.pending:
        return Colors.grey;
    }
  }

  static IconData _importIcon(ImportStatus status) {
    switch (status) {
      case ImportStatus.completed:
        return Icons.check_circle;
      case ImportStatus.inProgress:
        return Icons.sync;
      case ImportStatus.failed:
        return Icons.error;
      case ImportStatus.pending:
        return Icons.schedule;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
