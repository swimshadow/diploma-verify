import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/admin_bloc.dart';
import '../../bloc/admin_event.dart';
import '../../bloc/admin_state.dart';
import '../../data/models/admin_models.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';
import '../../../../shared/widgets/error_state_widget.dart';

class AdminDiplomasScreen extends StatefulWidget {
  const AdminDiplomasScreen({super.key});

  @override
  State<AdminDiplomasScreen> createState() => _AdminDiplomasScreenState();
}

class _AdminDiplomasScreenState extends State<AdminDiplomasScreen> {
  String _search = '';
  AdminDiplomaStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Реестр дипломов (админ)',
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminFailure) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<AdminBloc>().add(AdminLoadRequested()),
            );
          }
          if (state is! AdminLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = state.diplomas.where((d) {
            final q = _search.toLowerCase();
            final matchesSearch = _search.isEmpty ||
                d.holderName.toLowerCase().contains(q) ||
                d.diplomaNumber.toLowerCase().contains(q) ||
                d.universityName.toLowerCase().contains(q);
            final matchesStatus =
                _statusFilter == null || d.status == _statusFilter;
            return matchesSearch && matchesStatus;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Поиск по ФИО, номеру, вузу...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<AdminDiplomaStatus?>(
                      value: _statusFilter,
                      hint: const Text('Статус'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все')),
                        ...AdminDiplomaStatus.values.map((s) =>
                            DropdownMenuItem(value: s, child: Text(s.label))),
                      ],
                      onChanged: (v) =>
                          setState(() => _statusFilter = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Дипломы не найдены'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateColor.resolveWith(
                                (_) => theme.colorScheme
                                    .surfaceContainerHighest),
                            columns: const [
                              DataColumn(label: Text('Владелец')),
                              DataColumn(label: Text('Номер')),
                              DataColumn(label: Text('ВУЗ')),
                              DataColumn(label: Text('Trust')),
                              DataColumn(label: Text('Статус')),
                              DataColumn(label: Text('')),
                            ],
                            rows: filtered
                                .map((d) => DataRow(cells: [
                                      DataCell(Text(d.holderName,
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w500))),
                                      DataCell(Text(d.diplomaNumber)),
                                      DataCell(Text(d.universityName)),
                                      DataCell(_TrustBadge(
                                          score: d.trustScore)),
                                      DataCell(_DiplomaStatusBadge(
                                          status: d.status)),
                                      DataCell(IconButton(
                                        icon: const Icon(
                                            Icons.rate_review,
                                            size: 18),
                                        tooltip: 'Ручная проверка',
                                        onPressed: () => context.push(
                                            '/admin/diploma/${d.id}'),
                                      )),
                                    ]))
                                .toList(),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final double score;
  const _TrustBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).toInt();
    final color = score >= 0.8
        ? Colors.green
        : score >= 0.5
            ? Colors.orange
            : Colors.red;
    return Text('$pct%',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold));
  }
}

class _DiplomaStatusBadge extends StatelessWidget {
  final AdminDiplomaStatus status;
  const _DiplomaStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      AdminDiplomaStatus.verified => (Colors.green, Icons.verified),
      AdminDiplomaStatus.rejected => (Colors.red, Icons.cancel),
      AdminDiplomaStatus.disputed => (Colors.orange, Icons.warning_amber),
      AdminDiplomaStatus.pendingReview =>
        (Colors.blue, Icons.hourglass_top),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
