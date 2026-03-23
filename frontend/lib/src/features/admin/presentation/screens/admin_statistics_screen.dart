import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/admin_bloc.dart';
import '../../bloc/admin_state.dart';
import '../../data/models/admin_models.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Статистика',
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is! AdminLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final verified = state.diplomas
              .where((d) => d.status == AdminDiplomaStatus.verified)
              .length;
          final rejected = state.diplomas
              .where((d) => d.status == AdminDiplomaStatus.rejected)
              .length;
          final disputed = state.diplomas
              .where((d) => d.status == AdminDiplomaStatus.disputed)
              .length;
          final pending = state.diplomas
              .where(
                  (d) => d.status == AdminDiplomaStatus.pendingReview)
              .length;

          final universityApproved = state.universities
              .where(
                  (u) => u.status == ModerationStatus.approved)
              .length;
          final universityPending = state.universities
              .where(
                  (u) => u.status == ModerationStatus.pending)
              .length;
          final universityRejected = state.universities
              .where(
                  (u) => u.status == ModerationStatus.rejected)
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Users ──
                    Text('Пользователи',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _StatsGrid(items: [
                      _StatItem('Всего', state.totalUsers,
                          Icons.people, Colors.blue),
                      _StatItem('Студенты', state.studentCount,
                          Icons.school, Colors.teal),
                      _StatItem('Работодатели',
                          state.employerCount,
                          Icons.business, Colors.indigo),
                      _StatItem('Университеты',
                          state.universityCount,
                          Icons.account_balance, Colors.deepPurple),
                      _StatItem('Администраторы',
                          state.adminCount,
                          Icons.admin_panel_settings, Colors.brown),
                      _StatItem('Заблокировано',
                          state.blockedCount,
                          Icons.block, Colors.red),
                    ]),

                    const SizedBox(height: 32),

                    // ── Diplomas ──
                    Text('Дипломы',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _StatsGrid(items: [
                      _StatItem('Всего',
                          state.diplomas.length,
                          Icons.description, Colors.blue),
                      _StatItem('Верифицировано', verified,
                          Icons.check_circle, Colors.green),
                      _StatItem('Отклонено', rejected,
                          Icons.cancel, Colors.red),
                      _StatItem('Спорные', disputed,
                          Icons.warning, Colors.orange),
                      _StatItem('На проверке', pending,
                          Icons.hourglass_top, Colors.grey),
                    ]),

                    const SizedBox(height: 32),

                    // ── Universities ──
                    Text('Модерация университетов',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _StatsGrid(items: [
                      _StatItem('Всего',
                          state.universities.length,
                          Icons.account_balance, Colors.blue),
                      _StatItem('Одобрено',
                          universityApproved,
                          Icons.check_circle, Colors.green),
                      _StatItem('На рассмотрении',
                          universityPending,
                          Icons.hourglass_top, Colors.orange),
                      _StatItem('Отклонено',
                          universityRejected,
                          Icons.cancel, Colors.red),
                    ]),

                    const SizedBox(height: 32),

                    // ── Services ──
                    Text('Платформа',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _StatsGrid(items: [
                      _StatItem('Сервисы',
                          state.services.length,
                          Icons.dns, Colors.blue),
                      _StatItem('Работает',
                          state.healthyServices,
                          Icons.check_circle, Colors.green),
                      _StatItem('Деградация',
                          state.degradedServices,
                          Icons.speed, Colors.orange),
                      _StatItem('Недоступно',
                          state.downServices,
                          Icons.cloud_off, Colors.red),
                    ]),

                    const SizedBox(height: 32),

                    // ── Activity ──
                    Text('Активность (последние действия)',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _ActivityBar(
                      label: 'Логины',
                      count: state.logs
                          .where((l) => l.action == LogAction.login)
                          .length,
                      total: state.logs.length,
                      color: Colors.blue,
                    ),
                    _ActivityBar(
                      label: 'Смена ролей',
                      count: state.logs
                          .where(
                              (l) => l.action == LogAction.roleChange)
                          .length,
                      total: state.logs.length,
                      color: Colors.purple,
                    ),
                    _ActivityBar(
                      label: 'Блокировки',
                      count: state.logs
                          .where((l) =>
                              l.action == LogAction.block ||
                              l.action == LogAction.unblock)
                          .length,
                      total: state.logs.length,
                      color: Colors.red,
                    ),
                    _ActivityBar(
                      label: 'Ревью дипломов',
                      count: state.logs
                          .where(
                              (l) => l.action == LogAction.diplomaReview)
                          .length,
                      total: state.logs.length,
                      color: Colors.green,
                    ),
                    _ActivityBar(
                      label: 'Модерация',
                      count: state.logs
                          .where((l) =>
                              l.action ==
                              LogAction.moderationDecision)
                          .length,
                      total: state.logs.length,
                      color: Colors.orange,
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
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;
  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map((i) => SizedBox(
                width: 150,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(i.icon, color: i.color, size: 28),
                        const SizedBox(height: 8),
                        Text('${i.value}',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: i.color)),
                        const SizedBox(height: 4),
                        Text(i.label,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _ActivityBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _ActivityBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text('$count',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
