import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../student/bloc/diploma_bloc.dart';
import '../../../student/bloc/diploma_state.dart';
import '../../../student/data/models/diploma_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Кабинет студента',
      body: BlocBuilder<DiplomaBloc, DiplomaState>(
        builder: (context, state) {
          if (state is DiplomaLoading || state is DiplomaInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DiplomaLoaded) {
            return _DashboardBody(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DiplomaLoaded state;
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
                        label: 'Всего',
                        value: '${state.totalCount}',
                        icon: Icons.description_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      _StatCard(
                        label: 'Подтверждено',
                        value: '${state.verifiedCount}',
                        icon: Icons.verified,
                        color: Colors.green,
                      ),
                      _StatCard(
                        label: 'В обработке',
                        value: '${state.processingCount}',
                        icon: Icons.hourglass_top,
                        color: Colors.orange,
                      ),
                      _StatCard(
                        label: 'Отклонено',
                        value: '${state.rejectedCount}',
                        icon: Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              // Quick actions
              Text('Быстрые действия',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ActionChip(
                    icon: Icons.upload_file,
                    label: 'Загрузить диплом',
                    onTap: () => context.push('/student/upload'),
                  ),
                  _ActionChip(
                    icon: Icons.list_alt,
                    label: 'Мои дипломы',
                    onTap: () => context.push('/student/diplomas'),
                  ),
                  _ActionChip(
                    icon: Icons.chat_outlined,
                    label: 'Сообщения',
                    onTap: () => context.push('/student/chats'),
                  ),
                  _ActionChip(
                    icon: Icons.person_outlined,
                    label: 'Профиль',
                    onTap: () => context.push('/student/profile'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Recent diplomas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Последние дипломы',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.push('/student/diplomas'),
                    child: const Text('Все →'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...state.allDiplomas.take(3).map(
                    (d) => Card(
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(d.status).withValues(alpha: 0.15),
                          child: Icon(_statusIcon(d.status),
                              color: _statusColor(d.status), size: 20),
                        ),
                        title: Text(d.title),
                        subtitle: Text(d.university),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(d.status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                d.status.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: _statusColor(d.status),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => context.push('/student/diploma/${d.id}'),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(DiplomaStatus status) {
    switch (status) {
      case DiplomaStatus.verified:
        return Colors.green;
      case DiplomaStatus.processing:
      case DiplomaStatus.uploaded:
      case DiplomaStatus.recognized:
        return Colors.orange;
      case DiplomaStatus.rejected:
        return Colors.red;
    }
  }

  IconData _statusIcon(DiplomaStatus status) {
    switch (status) {
      case DiplomaStatus.verified:
        return Icons.verified;
      case DiplomaStatus.processing:
        return Icons.hourglass_top;
      case DiplomaStatus.uploaded:
        return Icons.cloud_upload;
      case DiplomaStatus.recognized:
        return Icons.auto_awesome;
      case DiplomaStatus.rejected:
        return Icons.cancel;
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
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 4),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
