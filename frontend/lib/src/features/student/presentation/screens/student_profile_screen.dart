import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Профиль студента',
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = state.user;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        _initials(user),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(user.profile['full_name']?.toString() ?? user.email,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Chip(label: Text('Студент')),
                    const SizedBox(height: 28),

                    // Personal info
                    _Section(
                      title: 'Личные данные',
                      children: [
                        _InfoTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email),
                        _InfoTile(
                            icon: Icons.person_outlined,
                            label: 'ФИО',
                            value: user.profile['full_name']?.toString() ??
                                '—'),
                        _InfoTile(
                            icon: Icons.cake_outlined,
                            label: 'Дата рождения',
                            value:
                                user.profile['date_of_birth']?.toString() ??
                                    '—'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Privacy settings
                    _Section(
                      title: 'Приватность',
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.visibility_outlined),
                          title: const Text('Показывать профиль работодателям'),
                          value: true,
                          onChanged: (v) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Настройки приватности будут доступны позже')),
                            );
                          },
                        ),
                        SwitchListTile(
                          secondary: const Icon(Icons.email_outlined),
                          title: const Text('Получать уведомления на email'),
                          value: true,
                          onChanged: (v) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Настройки уведомлений будут доступны позже')),
                            );
                          },
                        ),
                        SwitchListTile(
                          secondary: const Icon(Icons.share_outlined),
                          title:
                              const Text('Разрешить делиться дипломами по ссылке'),
                          value: true,
                          onChanged: (v) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Настройки приватности будут доступны позже')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Account actions
                    _Section(
                      title: 'Аккаунт',
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outlined),
                          title: const Text('Сменить пароль'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Смена пароля будет доступна позже')),
                            );
                          },
                        ),
                        ListTile(
                          leading:
                              Icon(Icons.delete_outline, color: Colors.red),
                          title: Text('Удалить аккаунт',
                              style: TextStyle(color: Colors.red)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Удаление аккаунта будет доступно позже')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _initials(AuthUser user) {
    final name = user.profile['full_name'] as String? ?? user.email;
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
