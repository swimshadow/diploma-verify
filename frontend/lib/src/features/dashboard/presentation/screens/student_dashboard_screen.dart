import 'package:flutter/material.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Панель студента',
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 64,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Панель студента',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Здесь будут ваши дипломы и ссылки для проверки',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
