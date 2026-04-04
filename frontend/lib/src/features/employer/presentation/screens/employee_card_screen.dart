import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../bloc/employer_bloc.dart';
import '../../bloc/employer_state.dart';
import '../../data/models/employee_model.dart';
import '../../../student/data/models/diploma_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class EmployeeCardScreen extends StatelessWidget {
  final String employeeId;
  const EmployeeCardScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    final employerState = context.read<EmployerBloc>().state;
    Employee? employee;
    if (employerState is EmployerLoaded) {
      employee = employerState.employees
          .where((e) => e.id == employeeId)
          .firstOrNull;
    }

    if (employee == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Сотрудник не найден')),
      );
    }

    return _CardView(employee: employee);
  }
}

class _CardView extends StatelessWidget {
  final Employee employee;
  const _CardView({required this.employee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');
    const List<Diploma> diplomas = [];

    return DashboardScaffold(
      title: 'Карточка сотрудника',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Personal info ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: theme.colorScheme.primary
                              .withValues(alpha: 0.1),
                          child: Text(
                            _initials(employee.fullName),
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(employee.fullName,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${employee.position} · ${employee.department}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        _DetailRow(label: 'Email', value: employee.email),
                        if (employee.phone != null)
                          _DetailRow(
                              label: 'Телефон', value: employee.phone!),
                        _DetailRow(
                          label: 'Дата найма',
                          value: dateFormat.format(employee.hiredAt),
                        ),
                        _DetailRow(
                          label: 'Статус',
                          value: employee.diplomaStatus.label,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Diplomas ──
                Text('Дипломы',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (diplomas.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text('Дипломы не загружены',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                      ),
                    ),
                  )
                else
                  ...diplomas.map((d) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _diplomaStatusColor(d.status)
                                    .withValues(alpha: 0.15),
                            child: Icon(
                              _diplomaStatusIcon(d.status),
                              color: _diplomaStatusColor(d.status),
                              size: 20,
                            ),
                          ),
                          title: Text(d.title),
                          subtitle: Text(
                              '${d.university} · ${d.diplomaNumber}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(d.status.label,
                                  style: TextStyle(
                                    color:
                                        _diplomaStatusColor(d.status),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  )),
                              const SizedBox(height: 4),
                              Text(
                                'Trust: ${(d.trustScore * 100).toInt()}%',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      )),

                const SizedBox(height: 20),

                // ── Chat button ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/employer/chats');
                    },
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Написать сообщение'),
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

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.isNotEmpty ? name[0] : '?';
  }

  Color _diplomaStatusColor(DiplomaStatus status) {
    switch (status) {
      case DiplomaStatus.verified:
        return Colors.green;
      case DiplomaStatus.processing:
      case DiplomaStatus.uploaded:
      case DiplomaStatus.recognized:
        return Colors.orange;
      case DiplomaStatus.rejected:
        return Colors.red;
    }
  }

  IconData _diplomaStatusIcon(DiplomaStatus status) {
    switch (status) {
      case DiplomaStatus.verified:
        return Icons.verified;
      case DiplomaStatus.processing:
        return Icons.hourglass_top;
      case DiplomaStatus.uploaded:
        return Icons.cloud_upload;
      case DiplomaStatus.recognized:
        return Icons.auto_awesome;
      case DiplomaStatus.rejected:
        return Icons.cancel;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
