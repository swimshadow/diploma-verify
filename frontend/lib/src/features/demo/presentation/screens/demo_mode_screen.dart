import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';

/// Demo accounts with pre-filled data for presentation mode.
class DemoAccount {
  final String label;
  final String email;
  final String password;
  final String role;
  final IconData icon;
  final Color color;
  final String description;

  const DemoAccount({
    required this.label,
    required this.email,
    required this.password,
    required this.role,
    required this.icon,
    required this.color,
    required this.description,
  });
}

const demoAccounts = [
  DemoAccount(
    label: 'Студент',
    email: 'demo.student@diplomaverify.ru',
    password: 'demo123456',
    role: 'student',
    icon: Icons.school,
    color: Colors.teal,
    description: '3 диплома, переписки с работодателями, верифицированный сертификат',
  ),
  DemoAccount(
    label: 'Работодатель',
    email: 'demo.employer@diplomaverify.ru',
    password: 'demo123456',
    role: 'employer',
    icon: Icons.business,
    color: Colors.indigo,
    description: '5 сотрудников, история проверок, 3 метода верификации',
  ),
  DemoAccount(
    label: 'Университет',
    email: 'demo.university@diplomaverify.ru',
    password: 'demo123456',
    role: 'university',
    icon: Icons.account_balance,
    color: Colors.deepPurple,
    description: 'Реестр дипломов, загрузка и импорт, сертификаты',
  ),
  DemoAccount(
    label: 'Администратор',
    email: 'demo.admin@diplomaverify.ru',
    password: 'demo123456',
    role: 'admin',
    icon: Icons.admin_panel_settings,
    color: Colors.brown,
    description: 'Панель управления, модерация, мониторинг, статистика',
  ),
];

class DemoModeScreen extends StatelessWidget {
  const DemoModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Mode'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Header
                Icon(Icons.play_circle_outline,
                    size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text('Режим презентации',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Выберите роль для входа с предзаполненными тестовыми данными',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),

                // Account cards
                ...demoAccounts.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _DemoAccountCard(account: a),
                    )),

                const SizedBox(height: 16),
                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demo-аккаунты содержат тестовые данные. Изменения не сохраняются.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccountCard extends StatelessWidget {
  final DemoAccount account;
  const _DemoAccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.read<AuthBloc>().add(
                AuthLoginRequested(
                  email: account.email,
                  password: account.password,
                ),
              );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: account.color.withValues(alpha: 0.12),
                child: Icon(account.icon,
                    color: account.color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.label,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(account.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(account.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: account.color),
            ],
          ),
        ),
      ),
    );
  }
}
