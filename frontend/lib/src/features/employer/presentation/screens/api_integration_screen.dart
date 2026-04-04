import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/dashboard_scaffold.dart';

class ApiIntegrationScreen extends StatelessWidget {
  const ApiIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'API / Интеграция',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── API Key ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.key,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('API-ключ',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme
                                .colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'dvk_live_a1b2c3d4e5f6g7h8i9j0••••••••',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                          fontFamily: 'monospace'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                tooltip: 'Копировать',
                                onPressed: () {
                                  Clipboard.setData(const ClipboardData(
                                      text:
                                          'dvk_live_a1b2c3d4e5f6g7h8i9j0k1l2m3n4'));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                          content: Text(
                                              'API-ключ скопирован')));
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Используйте этот ключ для авторизации запросов к DiplomaVerify API.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Перегенерация ключа будет доступна позже')));
                              },
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Перегенерировать'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Webhooks ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.webhook,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('Webhooks',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _WebhookRow(
                          event: 'diploma.verified',
                          url: 'https://yourapp.com/webhooks/diploma',
                          active: true,
                        ),
                        const Divider(height: 24),
                        _WebhookRow(
                          event: 'diploma.rejected',
                          url: 'https://yourapp.com/webhooks/diploma',
                          active: true,
                        ),
                        const Divider(height: 24),
                        _WebhookRow(
                          event: 'diploma.suspicious',
                          url: '',
                          active: false,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Добавление вебхуков будет доступно позже')));
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Добавить webhook'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Documentation ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description_outlined,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('Документация',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _DocLink(
                          title: 'REST API Reference',
                          description:
                              'Полная документация по эндпоинтам API',
                          icon: Icons.code,
                        ),
                        const SizedBox(height: 12),
                        _DocLink(
                          title: 'Примеры интеграций',
                          description:
                              'Python, JavaScript, Go — готовые SDK',
                          icon: Icons.integration_instructions,
                        ),
                        const SizedBox(height: 12),
                        _DocLink(
                          title: 'Справка по webhook событиям',
                          description: 'Форматы payload, retry policy',
                          icon: Icons.webhook,
                        ),
                      ],
                    ),
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

class _WebhookRow extends StatelessWidget {
  final String event;
  final String url;
  final bool active;

  const _WebhookRow({
    required this.event,
    required this.url,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(
                url.isNotEmpty ? url : 'Не настроен',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: url.isNotEmpty ? 'monospace' : null),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocLink extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _DocLink({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Документация будет доступна позже')));
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  Text(description,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
