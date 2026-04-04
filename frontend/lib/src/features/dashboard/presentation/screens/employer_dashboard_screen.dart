import 'package:flutter/material.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class EmployerDashboardScreen extends StatelessWidget {
  const EmployerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Панель работодателя',
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business, size: 64,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Панель работодателя',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Здесь будут инструменты для проверки дипломов',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
