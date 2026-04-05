import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/employer_bloc.dart';
import '../../bloc/employer_event.dart';
import '../../bloc/employer_state.dart';
import '../../data/models/verification_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';
import '../../../../shared/widgets/error_state_widget.dart';

class VerificationHistoryScreen extends StatelessWidget {
  const VerificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'История проверок',
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
          return _HistoryList(history: state.history);
        },
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<VerificationHistoryEntry> history;
  const _HistoryList({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${history.length} проверок',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              Card(
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5)),
                    columns: const [
                      DataColumn(label: Text('Дата')),
                      DataColumn(label: Text('ID диплома')),
                      DataColumn(label: Text('Способ')),
                      DataColumn(label: Text('Результат')),
                    ],
                    rows: history
                        .map((h) => DataRow(cells: [
                              DataCell(Text(
                                  dateFormat.format(h.checkedAt),
                                  style: theme.textTheme.bodySmall)),
                              DataCell(Text(h.diplomaId ?? '—',
                                  style: theme.textTheme.bodySmall)),
                              DataCell(_MethodBadge(method: h.method)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      h.isAuthentic
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 16,
                                      color: h.isAuthentic
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      h.isAuthentic
                                          ? 'Подлинный'
                                          : 'Невалидный',
                                      style: TextStyle(
                                        color: h.isAuthentic
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]))
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

class _MethodBadge extends StatelessWidget {
  final VerifyMethod method;
  const _MethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        method.label,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
