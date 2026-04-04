import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/logging/app_logger.dart';
import '../../bloc/university_bloc.dart';
import '../../bloc/university_state.dart';
import '../../data/models/registry_diploma_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

const _tag = 'UniversityRegistryScreen';

class UniversityRegistryScreen extends StatefulWidget {
  const UniversityRegistryScreen({super.key});

  @override
  State<UniversityRegistryScreen> createState() =>
      _UniversityRegistryScreenState();
}

class _UniversityRegistryScreenState extends State<UniversityRegistryScreen> {
  final _log = AppLogger.instance;
  String _searchQuery = '';
  RegistryDiplomaStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Реестр дипломов',
      body: BlocBuilder<UniversityBloc, UniversityState>(
        builder: (context, state) {
          if (state is! UniversityLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = state.diplomas.where((d) {
            final matchesSearch = _searchQuery.isEmpty ||
                d.holderFullName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                d.diplomaNumber.contains(_searchQuery) ||
                (d.certificateId?.contains(_searchQuery) ?? false);
            final matchesStatus =
                _statusFilter == null || d.status == _statusFilter;
            return matchesSearch && matchesStatus;
          }).toList();

          return Column(
            children: [
              // ── Filters ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Поиск по ФИО, номеру, сертификату...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          _log.debug(_tag, 'Поиск изменён: "$v"');
                          setState(() => _searchQuery = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<RegistryDiplomaStatus?>(
                      value: _statusFilter,
                      hint: const Text('Статус'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Все')),
                        ...RegistryDiplomaStatus.values.map((s) =>
                            DropdownMenuItem(value: s, child: Text(s.label))),
                      ],
                      onChanged: (v) {
                        _log.info(_tag, 'BTN: Фильтр статуса изменён на $v');
                        setState(() => _statusFilter = v);
                      },
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {
                        _log.info(_tag, 'BTN: Добавить диплом — нажата');
                        context.push('/university/diploma-upload');
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Добавить'),
                    ),
                  ],
                ),
              ),

              // ── Summary ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('Найдено: ${filtered.length}',
                        style: theme.textTheme.bodySmall),
                    const Spacer(),
                    Text(
                        'Активных: ${state.activeDiplomas} · Отозванных: ${state.revokedDiplomas}',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Table ──
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Дипломы не найдены'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateColor.resolveWith(
                                (_) => theme.colorScheme.surfaceContainerHighest),
                            columns: const [
                              DataColumn(label: Text('ФИО')),
                              DataColumn(label: Text('Серия/Номер')),
                              DataColumn(label: Text('Факультет')),
                              DataColumn(label: Text('Уровень')),
                              DataColumn(label: Text('GPA')),
                              DataColumn(label: Text('Статус')),
                              DataColumn(label: Text('Сертификат')),
                              DataColumn(label: Text('')),
                            ],
                            rows: filtered
                                .map((d) => DataRow(
                                      cells: [
                                        DataCell(
                                          Text(d.holderFullName,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w500)),
                                        ),
                                        DataCell(Text(
                                            '${d.diplomaSeries} ${d.diplomaNumber}')),
                                        DataCell(Text(d.faculty,
                                            overflow:
                                                TextOverflow.ellipsis)),
                                        DataCell(Text(d.educationLevel)),
                                        DataCell(Text(
                                            d.gpa.toStringAsFixed(2))),
                                        DataCell(_StatusBadge(
                                            status: d.status)),
                                        DataCell(Text(
                                            d.certificateId ?? '—')),
                                        DataCell(IconButton(
                                          icon: const Icon(
                                              Icons.open_in_new,
                                              size: 18),
                                          onPressed: () {
                                            _log.info(_tag, 'BTN: Открыть диплом ${d.id}');
                                            context.push('/university/diploma/${d.id}');
                                          },
                                        )),
                                      ],
                                    ))
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

class _StatusBadge extends StatelessWidget {
  final RegistryDiplomaStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      RegistryDiplomaStatus.active => (Colors.green, Icons.verified),
      RegistryDiplomaStatus.revoked => (Colors.red, Icons.block),
      RegistryDiplomaStatus.pendingReview =>
        (Colors.orange, Icons.hourglass_top),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
