import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/admin_bloc.dart';
import '../../bloc/admin_event.dart';
import '../../bloc/admin_state.dart';
import '../../data/models/admin_models.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class AdminModerationScreen extends StatelessWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd.MM.yyyy');

    return DashboardScaffold(
      title: 'Модерация вузов',
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is! AdminLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final pending = state.universities
              .where((u) => u.status == ModerationStatus.pending)
              .toList();
          final processed = state.universities
              .where((u) => u.status != ModerationStatus.pending)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Pending ──
                    Text(
                        'Ожидают модерации (${pending.length})',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (pending.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade300),
                              const SizedBox(width: 8),
                              const Text('Нет заявок на модерации'),
                            ],
                          ),
                        ),
                      )
                    else
                      ...pending.map((uni) => _PendingCard(
                            uni: uni,
                            dateFmt: dateFmt,
                          )),

                    const SizedBox(height: 32),

                    // ── Processed ──
                    Text('Обработанные (${processed.length})',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...processed.map((uni) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _statusColor(uni.status)
                                      .withValues(alpha: 0.12),
                              child: Icon(
                                uni.status == ModerationStatus.approved
                                    ? Icons.verified
                                    : Icons.cancel,
                                color: _statusColor(uni.status),
                                size: 20,
                              ),
                            ),
                            title: Text(uni.name),
                            subtitle: Text(
                              '${uni.city} · ${uni.contactEmail}'
                              '${uni.moderatorComment != null ? '\n${uni.moderatorComment}' : ''}',
                            ),
                            trailing: Text(uni.status.label,
                                style: TextStyle(
                                    color: _statusColor(uni.status),
                                    fontWeight: FontWeight.w600)),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Color _statusColor(ModerationStatus status) {
    switch (status) {
      case ModerationStatus.approved:
        return Colors.green;
      case ModerationStatus.rejected:
        return Colors.red;
      case ModerationStatus.pending:
        return Colors.orange;
    }
  }
}

class _PendingCard extends StatelessWidget {
  final ModerationUniversity uni;
  final DateFormat dateFmt;
  const _PendingCard({required this.uni, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance,
                    color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(uni.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${uni.city} · ${uni.contactEmail}',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Заявка подана: ${dateFmt.format(uni.appliedAt)}',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context),
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                  label: const Text('Отклонить',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red)),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    context
                        .read<AdminBloc>()
                        .add(AdminApproveUniversity(uni.id));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${uni.name} подтверждён'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Подтвердить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Отклонить: ${uni.name}'),
        content: TextField(
          controller: commentCtrl,
          decoration: const InputDecoration(
            labelText: 'Причина отклонения',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              context.read<AdminBloc>().add(
                    AdminRejectUniversity(
                      uni.id,
                      commentCtrl.text.isNotEmpty
                          ? commentCtrl.text
                          : 'Без комментария',
                    ),
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${uni.name} отклонён'),
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }
}
