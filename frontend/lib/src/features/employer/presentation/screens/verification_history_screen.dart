import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/employer_bloc.dart';
import '../../bloc/employer_state.dart';
import '../../data/models/verification_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class VerificationHistoryScreen extends StatelessWidget {
  const VerificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'История проверок',
      body: BlocBuilder<EmployerBloc, EmployerState>(
        builder: (context, state) {
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
                      DataColumn(label: Text('Диплом')),
                      DataColumn(label: Text('Владелец')),
                      DataColumn(label: Text('Способ')),
                      DataColumn(label: Text('Результат')),
                      DataColumn(label: Text('Confidence')),
                    ],
                    rows: history
                        .map((h) => DataRow(cells: [
                              DataCell(Text(
                                  dateFormat.format(h.checkedAt),
                                  style: theme.textTheme.bodySmall)),
                              DataCell(Text(h.diplomaTitle)),
                              DataCell(Text(h.holderName)),
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
                                          : 'Подозрительный',
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
                              DataCell(
                                _ConfidenceBar(
                                    score: h.confidenceScore),
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

class _ConfidenceBar extends StatelessWidget {
  final double score;
  const _ConfidenceBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 0.7
        ? Colors.green
        : score >= 0.4
            ? Colors.orange
            : Colors.red;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(score * 100).toInt()}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
