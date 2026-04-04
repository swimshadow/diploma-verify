import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/admin_bloc.dart';
import '../../bloc/admin_state.dart';
import '../../data/models/admin_models.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class AdminMonitoringScreen extends StatelessWidget {
  const AdminMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Мониторинг',
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is! AdminLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Summary ──
                    Row(
                      children: [
                        _SummaryChip('Healthy',
                            state.healthyServices, Colors.green),
                        const SizedBox(width: 8),
                        _SummaryChip('Degraded',
                            state.degradedServices, Colors.orange),
                        const SizedBox(width: 8),
                        _SummaryChip(
                            'Down', state.downServices, Colors.red),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Services table ──
                    Text('Состояние сервисов',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...state.services.map((s) => _ServiceCard(service: s)),

                    const SizedBox(height: 32),

                    // ── Queues ──
                    Text('Очереди задач',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: state.services
                              .where((s) => s.queueSize > 0)
                              .map((s) => Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Text(s.name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500))),
                                        SizedBox(
                                          width: 120,
                                          child: LinearProgressIndicator(
                                            value: (s.queueSize / 50)
                                                .clamp(0.0, 1.0),
                                            backgroundColor: Colors.grey
                                                .withValues(alpha: 0.2),
                                            color: s.queueSize > 20
                                                ? Colors.orange
                                                : Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text('${s.queueSize}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: s.queueSize > 20
                                                  ? Colors.orange
                                                  : null,
                                            )),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── OCR/ML errors stub ──
                    Text('Ошибки OCR/ML (24ч)',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: state.services
                              .where((s) => s.errorsLast24h > 0)
                              .map((s) => ListTile(
                                    leading: Icon(
                                      Icons.error_outline,
                                      color: s.errorsLast24h > 10
                                          ? Colors.red
                                          : Colors.orange,
                                    ),
                                    title: Text(s.name),
                                    trailing: Text(
                                      '${s.errorsLast24h} ошибок',
                                      style: TextStyle(
                                        color: s.errorsLast24h > 10
                                            ? Colors.red
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    if (state.services
                        .every((s) => s.errorsLast24h == 0))
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade300),
                              const SizedBox(width: 8),
                              const Text('Ошибок за 24ч нет'),
                            ],
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
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $count',
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceHealth service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final (color, icon, statusText) = switch (service.status) {
      ServiceStatus.healthy =>
        (Colors.green, Icons.check_circle, 'Работает'),
      ServiceStatus.degraded =>
        (Colors.orange, Icons.speed, 'Деградация'),
      ServiceStatus.down => (Colors.red, Icons.cloud_off, 'Недоступен'),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(service.name,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          'Ответ: ${service.avgResponseMs > 0 ? '${service.avgResponseMs.toInt()} мс' : '—'}'
          ' · Очередь: ${service.queueSize}'
          ' · Ошибки: ${service.errorsLast24h}',
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(statusText,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ),
      ),
    );
  }
}
