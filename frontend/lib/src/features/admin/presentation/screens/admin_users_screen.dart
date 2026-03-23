import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/admin_bloc.dart';
import '../../bloc/admin_event.dart';
import '../../bloc/admin_state.dart';
import '../../data/models/admin_models.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _search = '';
  String? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');

    return DashboardScaffold(
      title: 'Управление пользователями',
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is! AdminLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = state.users.where((u) {
            final q = _search.toLowerCase();
            final matchesSearch = _search.isEmpty ||
                u.fullName.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q);
            final matchesRole = _roleFilter == null || u.role == _roleFilter;
            return matchesSearch && matchesRole;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Поиск по имени или email...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String?>(
                      value: _roleFilter,
                      hint: const Text('Роль'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Все')),
                        DropdownMenuItem(value: 'student', child: Text('Студент')),
                        DropdownMenuItem(value: 'employer', child: Text('Работодатель')),
                        DropdownMenuItem(value: 'university', child: Text('Вуз')),
                        DropdownMenuItem(value: 'admin', child: Text('Админ')),
                      ],
                      onChanged: (v) => setState(() => _roleFilter = v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Найдено: ${filtered.length}',
                    style: theme.textTheme.bodySmall),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateColor.resolveWith(
                          (_) => theme.colorScheme.surfaceContainerHighest),
                      columns: const [
                        DataColumn(label: Text('ФИО')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Роль')),
                        DataColumn(label: Text('Статус')),
                        DataColumn(label: Text('Посл. вход')),
                        DataColumn(label: Text('Действия')),
                      ],
                      rows: filtered
                          .map((u) => DataRow(cells: [
                                DataCell(Text(u.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500))),
                                DataCell(Text(u.email)),
                                DataCell(_RoleBadge(role: u.role)),
                                DataCell(u.isBlocked
                                    ? const _BlockedBadge()
                                    : const Text('Активен',
                                        style: TextStyle(color: Colors.green))),
                                DataCell(Text(u.lastLoginAt != null
                                    ? dateFmt.format(u.lastLoginAt!)
                                    : '—')),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (u.isBlocked)
                                      IconButton(
                                        icon: const Icon(Icons.lock_open,
                                            size: 18, color: Colors.green),
                                        tooltip: 'Разблокировать',
                                        onPressed: () => context
                                            .read<AdminBloc>()
                                            .add(AdminUnblockUser(u.id)),
                                      )
                                    else
                                      IconButton(
                                        icon: const Icon(Icons.block,
                                            size: 18, color: Colors.red),
                                        tooltip: 'Заблокировать',
                                        onPressed: () => _confirmBlock(
                                            context, u),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.swap_horiz,
                                          size: 18),
                                      tooltip: 'Сменить роль',
                                      onPressed: () =>
                                          _showRoleDialog(context, u),
                                    ),
                                  ],
                                )),
                              ]))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmBlock(BuildContext context, PlatformUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Заблокировать пользователя?'),
        content: Text('${user.fullName} (${user.email})'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              context.read<AdminBloc>().add(AdminBlockUser(user.id));
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context, PlatformUser user) {
    String selected = user.role;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Роль: ${user.fullName}'),
          content: RadioGroup<String>(
            groupValue: selected,
            onChanged: (v) =>
                setDialogState(() => selected = v!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['student', 'employer', 'university', 'admin']
                  .map((r) => RadioListTile<String>(
                        value: r,
                        title: Text(r),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена')),
            FilledButton(
              onPressed: () {
                context
                    .read<AdminBloc>()
                    .add(AdminChangeUserRole(user.id, selected));
                Navigator.pop(ctx);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'student' => ('Студент', Colors.blue),
      'employer' => ('Работодатель', Colors.teal),
      'university' => ('Вуз', Colors.purple),
      'admin' => ('Админ', Colors.deepOrange),
      _ => (role, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _BlockedBadge extends StatelessWidget {
  const _BlockedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 12, color: Colors.red),
          SizedBox(width: 4),
          Text('Заблокирован',
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
