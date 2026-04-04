import 'package:flutter/material.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class UniversityDashboardScreen extends StatelessWidget {
  const UniversityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Панель университета',
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 64,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Панель управления университета',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Здесь будут инструменты для управления дипломами',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
