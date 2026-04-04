import 'package:flutter/material.dart';

import '../../../../shared/widgets/dashboard_scaffold.dart';

class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  bool _emailNotifications = true;
  bool _webhookNotifications = false;
  bool _autoCheck = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Профиль компании',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Company info ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: theme.colorScheme.primary
                              .withValues(alpha: 0.1),
                          child: Icon(Icons.business,
                              size: 32, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 12),
                        Text('ООО «ТехноСофт»',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('IT-компания · Москва',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        _InfoRow(
                            label: 'ИНН', value: '7701234567'),
                        _InfoRow(
                            label: 'ОГРН', value: '1037700012345'),
                        _InfoRow(
                            label: 'Email', value: 'hr@technosoft.ru'),
                        _InfoRow(
                            label: 'Телефон',
                            value: '+7 (495) 123-45-67'),
                        _InfoRow(
                            label: 'Адрес',
                            value: 'г. Москва, ул. IT-парк, д. 1'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Settings ──
                Text('Настройки',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Email-уведомления'),
                        subtitle: const Text(
                            'Получать результаты проверок на email'),
                        value: _emailNotifications,
                        onChanged: (v) =>
                            setState(() => _emailNotifications = v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Webhook-уведомления'),
                        subtitle: const Text(
                            'Отправлять события на webhook URL'),
                        value: _webhookNotifications,
                        onChanged: (v) =>
                            setState(() => _webhookNotifications = v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Автопроверка дипломов'),
                        subtitle: const Text(
                            'Автоматически проверять новых сотрудников'),
                        value: _autoCheck,
                        onChanged: (v) =>
                            setState(() => _autoCheck = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Account actions ──
                Text('Аккаунт',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Изменить пароль'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Смена пароля будет доступна позже')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Редактировать данные'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Редактирование будет доступно позже')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.delete_outline,
                            color: Colors.red.shade400),
                        title: Text('Удалить аккаунт',
                            style: TextStyle(color: Colors.red.shade400)),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
