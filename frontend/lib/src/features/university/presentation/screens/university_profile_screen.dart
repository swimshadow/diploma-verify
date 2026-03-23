import 'package:flutter/material.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class UniversityProfileScreen extends StatelessWidget {
  const UniversityProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Профиль вуза',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo & name ──
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                        child: Icon(Icons.school,
                            size: 48, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 12),
                      Text('Казахский Национальный Университет им. аль-Фараби',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('КазНУ · Алматы',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Moderation status ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Статус модерации: Подтверждён',
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                            const SizedBox(height: 2),
                            Text('Верификация пройдена 15.01.2024',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // ── Details ──
                Text('Сведения об учреждении',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _InfoRow('Полное название',
                    'Казахский Национальный Университет им. аль-Фараби'),
                _InfoRow('Сокращение', 'КазНУ'),
                _InfoRow('Город', 'Алматы, Казахстан'),
                _InfoRow('Адрес', 'пр. аль-Фараби, 71'),
                _InfoRow('ИИН/БИН', '990140003456'),
                _InfoRow('Тип', 'Национальный университет'),
                _InfoRow('Лицензия', '№ KZ-EDU-0001 от 01.09.2000'),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // ── Contact ──
                Text('Контактная информация',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _InfoRow('Email', 'registrar@kaznu.kz'),
                _InfoRow('Телефон', '+7 (727) 377-33-33'),
                _InfoRow('Веб-сайт', 'https://www.kaznu.kz'),
                _InfoRow('Ответственное лицо', 'Ахметов Б.К., Регистратор'),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // ── Statistics ──
                Text('Статистика на платформе',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _InfoRow('Дипломов в реестре', '6'),
                _InfoRow('Выдано сертификатов', '5'),
                _InfoRow('Проверок работодателями', '4'),
                _InfoRow('Средний Trust Score', '93%'),
                _InfoRow('Дата регистрации', '10.12.2023'),

                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Запрос на редактирование отправлен'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Запросить изменение данных'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
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
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
