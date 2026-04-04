import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Профиль',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          _initials(user),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(user.email,
                          style: theme.textTheme.titleMedium),
                    ),
                    Center(
                      child: Chip(label: Text(_roleLabel(user.role))),
                    ),
                    const SizedBox(height: 32),

                    // Profile details
                    Text('Данные профиля',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ..._profileFields(user, theme),

                    const SizedBox(height: 32),
                    // Settings stubs
                    Text('Настройки',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.lock_outlined),
                            title: const Text('Сменить пароль'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Функция смены пароля будет доступна позже')),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.notifications_outlined),
                            title: const Text('Настройки уведомлений'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Настройки уведомлений будут доступны позже')),
                              );
                            },
                          ),
                        ],
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

  String _initials(AuthUser user) {
    final name = user.profile['full_name'] as String? ??
        user.profile['name'] as String? ??
        user.profile['company_name'] as String? ??
        user.email;
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'university':
        return 'Университет';
      case 'student':
        return 'Студент';
      case 'employer':
        return 'Работодатель';
      default:
        return role;
    }
  }

  List<Widget> _profileFields(AuthUser user, ThemeData theme) {
    final fields = <MapEntry<String, String>>[];
    final p = user.profile;

    switch (user.role) {
      case 'university':
        fields.addAll([
          MapEntry('Название', p['name']?.toString() ?? '—'),
          MapEntry('ИНН', p['inn']?.toString() ?? '—'),
          MapEntry('ОГРН', p['ogrn']?.toString() ?? '—'),
        ]);
      case 'student':
        fields.addAll([
          MapEntry('ФИО', p['full_name']?.toString() ?? '—'),
          MapEntry('Дата рождения', p['date_of_birth']?.toString() ?? '—'),
        ]);
      case 'employer':
        fields.addAll([
          MapEntry('Компания', p['company_name']?.toString() ?? '—'),
          MapEntry('ИНН', p['inn']?.toString() ?? '—'),
        ]);
    }

    return [
      Card(
        child: Column(
          children: fields.map((f) {
            return ListTile(
              title: Text(f.key,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              subtitle:
                  Text(f.value, style: theme.textTheme.bodyLarge),
            );
          }).toList(),
        ),
      ),
    ];
  }
}
