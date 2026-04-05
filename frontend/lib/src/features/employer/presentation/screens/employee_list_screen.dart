import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/employer_bloc.dart';
import '../../bloc/employer_event.dart';
import '../../bloc/employer_state.dart';
import '../../data/models/employee_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';
import '../../../../shared/widgets/error_state_widget.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Сотрудники',
      body: BlocBuilder<EmployerBloc, EmployerState>(
        builder: (context, state) {
          if (state is EmployerFailure) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<EmployerBloc>().add(EmployerLoadRequested()),
            );
          }
          if (state is! EmployerLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return _EmployeeList(employees: state.employees);
        },
      ),
    );
  }
}

class _EmployeeList extends StatelessWidget {
  final List<Employee> employees;
  const _EmployeeList({required this.employees});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${employees.length} сотрудников',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Table ──
              Card(
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5)),
                    columns: const [
                      DataColumn(label: Text('ФИО')),
                      DataColumn(label: Text('Должность')),
                      DataColumn(label: Text('Отдел')),
                      DataColumn(label: Text('Статус диплома')),
                      DataColumn(label: Text('')),
                    ],
                    rows: employees
                        .map((e) => DataRow(
                              cells: [
                                DataCell(Text(e.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500))),
                                DataCell(Text(e.position)),
                                DataCell(Text(e.department)),
                                DataCell(_StatusBadge(
                                    status: e.diplomaStatus)),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios,
                                        size: 16),
                                    onPressed: () => context.push(
                                        '/employer/employee/${e.id}'),
                                  ),
                                ),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final VerificationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(VerificationStatus s) {
    switch (s) {
      case VerificationStatus.verified:
        return Colors.green;
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.suspicious:
        return Colors.red;
      case VerificationStatus.notChecked:
        return Colors.grey;
    }
  }
}
