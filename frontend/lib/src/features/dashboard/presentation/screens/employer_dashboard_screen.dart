import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../employer/bloc/employer_bloc.dart';
import '../../../employer/bloc/employer_state.dart';
import '../../../employer/data/models/verification_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class EmployerDashboardScreen extends StatelessWidget {
  const EmployerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Панель работодателя',
      body: BlocBuilder<EmployerBloc, EmployerState>(
        builder: (context, state) {
          if (state is EmployerLoading || state is EmployerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EmployerLoaded) {
            return _DashboardBody(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final EmployerLoaded state;
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
                        label: 'Сотрудников',
                        value: '${state.totalEmployees}',
                        icon: Icons.people_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      _StatCard(
                        label: 'Подтверждено',
                        value: '${state.verifiedCount}',
                        icon: Icons.verified,
                        color: Colors.green,
                      ),
                      _StatCard(
                        label: 'На проверке',
                        value: '${state.pendingCount}',
                        icon: Icons.hourglass_top,
                        color: Colors.orange,
                      ),
                      _StatCard(
                        label: 'Подозрительные',
                        value: '${state.suspiciousCount}',
                        icon: Icons.warning_amber,
                        color: Colors.red,
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
                    icon: Icons.search,
                    label: 'Проверить диплом',
                    onTap: () => context.push('/employer/verify'),
                  ),
                  _ActionChip(
                    icon: Icons.people_outlined,
                    label: 'Сотрудники',
                    onTap: () => context.push('/employer/employees'),
                  ),
                  _ActionChip(
                    icon: Icons.history,
                    label: 'История проверок',
                    onTap: () => context.push('/employer/history'),
                  ),
                  _ActionChip(
                    icon: Icons.chat_outlined,
                    label: 'Сообщения',
                    onTap: () => context.push('/employer/chats'),
                  ),
                  _ActionChip(
                    icon: Icons.api,
                    label: 'API / Интеграция',
                    onTap: () => context.push('/employer/api'),
                  ),
                  _ActionChip(
                    icon: Icons.settings_outlined,
                    label: 'Профиль',
                    onTap: () => context.push('/employer/profile'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Recent verifications ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Последние проверки',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.push('/employer/history'),
                    child: const Text('Все →'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...state.history.take(3).map(
                    (h) => Card(
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (h.isAuthentic
                                  ? Colors.green
                                  : Colors.red)
                              .withValues(alpha: 0.15),
                          child: Icon(
                            h.isAuthentic ? Icons.verified : Icons.warning,
                            color:
                                h.isAuthentic ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        title: Text(h.diplomaTitle),
                        subtitle: Text(
                            '${h.holderName} · ${h.method.label}'),
                        trailing: Text(
                          '${(h.confidenceScore * 100).toInt()}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: h.isAuthentic
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),

              const SizedBox(height: 32),

              // ── Suspicious alerts ──
              if (state.suspiciousCount > 0) ...[
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
                      const Icon(Icons.warning_amber,
                          color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Обнаружены подозрительные дипломы',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.suspiciousCount} сотрудник(ов) с подозрительными документами',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.push('/employer/employees'),
                        child: const Text('Подробнее'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──

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
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
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
