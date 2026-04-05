import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/admin_bloc.dart';
import '../../bloc/admin_event.dart';
import '../../bloc/admin_state.dart';
import '../../data/models/admin_models.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';
import '../../../../shared/widgets/error_state_widget.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  LogAction? _filterAction;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Журнал действий',
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminFailure) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<AdminBloc>().add(AdminLoadRequested()),
            );
          }
          if (state is! AdminLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final query = _searchController.text.toLowerCase();
          final filtered = state.logs.where((log) {
            if (_filterAction != null && log.action != _filterAction) {
              return false;
            }
            if (query.isNotEmpty) {
              return log.actorEmail.toLowerCase().contains(query) ||
                  log.targetDescription.toLowerCase().contains(query) ||
                  (log.details?.toLowerCase().contains(query) ?? false);
            }
            return true;
          }).toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return Column(
            children: [
              // ── Filters ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Поиск по email или цели...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<LogAction?>(
                      value: _filterAction,
                      hint: const Text('Все действия'),
                      items: [
                        const DropdownMenuItem(
                            value: null,
                            child: Text('Все действия')),
                        ...LogAction.values.map((a) =>
                            DropdownMenuItem(
                                value: a,
                                child: Text(_actionLabel(a)))),
                      ],
                      onChanged: (v) =>
                          setState(() => _filterAction = v),
                    ),
                  ],
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Записей: ${filtered.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Log list ──
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('Нет записей по фильтру'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final log = filtered[i];
                          return _LogTile(log: log);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _actionLabel(LogAction a) => switch (a) {
        LogAction.login => 'Вход',
        LogAction.logout => 'Выход',
        LogAction.roleChange => 'Смена роли',
        LogAction.statusChange => 'Смена статуса',
        LogAction.block => 'Блокировка',
        LogAction.unblock => 'Разблокировка',
        LogAction.diplomaReview => 'Ревью диплома',
        LogAction.moderationDecision => 'Модерация',
      };
}

class _LogTile extends StatelessWidget {
  final AuditLog log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (log.action) {
      LogAction.login => (Icons.login, Colors.blue),
      LogAction.logout => (Icons.logout, Colors.grey),
      LogAction.roleChange =>
        (Icons.swap_horiz, Colors.purple),
      LogAction.statusChange =>
        (Icons.change_circle, Colors.teal),
      LogAction.block => (Icons.block, Colors.red),
      LogAction.unblock =>
        (Icons.lock_open, Colors.green),
      LogAction.diplomaReview =>
        (Icons.fact_check, Colors.indigo),
      LogAction.moderationDecision =>
        (Icons.gavel, Colors.orange),
    };

    final dateStr =
        DateFormat('dd.MM.yyyy HH:mm').format(log.timestamp);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        log.targetDescription,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text('${log.actorEmail}  ·  $dateStr'),
      trailing: log.details != null
          ? Tooltip(
              message: log.details!,
              child: const Icon(Icons.info_outline, size: 18),
            )
          : null,
    );
  }
}
