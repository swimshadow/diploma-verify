import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/admin_bloc.dart';
import '../../bloc/admin_state.dart';
import '../../data/models/admin_models.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Панель администратора',
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminLoaded) {
            return _Body(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final AdminLoaded state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Users by role ──
              Text('Пользователи по ролям',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, constraints) {
                final cross = constraints.maxWidth > 600 ? 5 : 3;
                return GridView.count(
                  crossAxisCount: cross,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _StatCard('Всего', '${state.totalUsers}',
                        Icons.people, theme.colorScheme.primary),
                    _StatCard('Студенты', '${state.studentCount}',
                        Icons.school_outlined, Colors.blue),
                    _StatCard('Работодатели', '${state.employerCount}',
                        Icons.business, Colors.teal),
                    _StatCard('Вузы', '${state.universityCount}',
                        Icons.account_balance, Colors.purple),
                    _StatCard('Админы', '${state.adminCount}',
                        Icons.admin_panel_settings, Colors.deepOrange),
                  ],
                );
              }),

              const SizedBox(height: 24),

              // ── Diploma & verification stats ──
              Text('Дипломы и проверки',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, constraints) {
                final cross = constraints.maxWidth > 500 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: cross,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard('Дипломов', '${state.diplomas.length}',
                        Icons.description, theme.colorScheme.primary),
                    _StatCard('Подтверждено', '${state.verifiedDiplomas}',
                        Icons.verified, Colors.green),
                    _StatCard('Спорных/Ожид.', '${state.disputedDiplomas}',
                        Icons.warning_amber, Colors.orange),
                    _StatCard('Забл. польз.', '${state.blockedCount}',
                        Icons.block, Colors.red),
                  ],
                );
              }),

              const SizedBox(height: 24),

              // ── Quick actions ──
              Text('Быстрые действия',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ActionChip(Icons.people, 'Пользователи',
                      () => context.push('/admin/users')),
                  _ActionChip(Icons.account_balance, 'Модерация вузов',
                      () => context.push('/admin/moderation')),
                  _ActionChip(Icons.list_alt, 'Реестр дипломов',
                      () => context.push('/admin/diplomas')),
                  _ActionChip(Icons.monitor_heart, 'Мониторинг',
                      () => context.push('/admin/monitoring')),
                  _ActionChip(Icons.bar_chart, 'Статистика',
                      () => context.push('/admin/statistics')),
                  _ActionChip(Icons.receipt_long, 'Логи',
                      () => context.push('/admin/logs')),
                  _ActionChip(Icons.person_add, 'Создать админа',
                      () => context.push('/admin/create-admin')),
                ],
              ),

              const SizedBox(height: 24),

              // ── Alerts ──
              if (state.pendingUniversities > 0)
                _AlertBanner(
                  icon: Icons.account_balance,
                  color: Colors.orange,
                  text: '${state.pendingUniversities} вузов ожидают модерации',
                  action: 'Модерация',
                  onTap: () => context.push('/admin/moderation'),
                ),
              if (state.disputedDiplomas > 0) ...[
                const SizedBox(height: 12),
                _AlertBanner(
                  icon: Icons.warning_amber,
                  color: Colors.red,
                  text: '${state.disputedDiplomas} дипломов требуют ручной проверки',
                  action: 'Проверить',
                  onTap: () => context.push('/admin/diplomas'),
                ),
              ],
              if (state.downServices > 0) ...[
                const SizedBox(height: 12),
                _AlertBanner(
                  icon: Icons.cloud_off,
                  color: Colors.red,
                  text: '${state.downServices} сервисов недоступно',
                  action: 'Мониторинг',
                  onTap: () => context.push('/admin/monitoring'),
                ),
              ],
              if (state.degradedServices > 0) ...[
                const SizedBox(height: 12),
                _AlertBanner(
                  icon: Icons.speed,
                  color: Colors.amber,
                  text: '${state.degradedServices} сервисов деградировано',
                  action: 'Мониторинг',
                  onTap: () => context.push('/admin/monitoring'),
                ),
              ],

              const SizedBox(height: 24),

              // ── Recent logs ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Последние действия',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.push('/admin/logs'),
                    child: const Text('Все →'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...state.logs.take(5).map((log) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: _logColor(log.action)
                            .withValues(alpha: 0.12),
                        child: Icon(_logIcon(log.action),
                            size: 18, color: _logColor(log.action)),
                      ),
                      title: Text(log.targetDescription,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Text(
                          '${log.action.label} · ${log.actorEmail}',
                          style: theme.textTheme.bodySmall),
                      trailing: Text(
                        _formatTime(log.timestamp),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static Color _logColor(LogAction action) {
    switch (action) {
      case LogAction.login:
      case LogAction.logout:
        return Colors.blue;
      case LogAction.block:
        return Colors.red;
      case LogAction.unblock:
        return Colors.green;
      case LogAction.roleChange:
      case LogAction.statusChange:
        return Colors.orange;
      case LogAction.diplomaReview:
        return Colors.purple;
      case LogAction.moderationDecision:
        return Colors.teal;
    }
  }

  static IconData _logIcon(LogAction action) {
    switch (action) {
      case LogAction.login:
        return Icons.login;
      case LogAction.logout:
        return Icons.logout;
      case LogAction.block:
        return Icons.block;
      case LogAction.unblock:
        return Icons.check_circle;
      case LogAction.roleChange:
        return Icons.swap_horiz;
      case LogAction.statusChange:
        return Icons.published_with_changes;
      case LogAction.diplomaReview:
        return Icons.rate_review;
      case LogAction.moderationDecision:
        return Icons.gavel;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
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
  const _ActionChip(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String action;
  final VoidCallback onTap;
  const _AlertBanner({
    required this.icon,
    required this.color,
    required this.text,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}
