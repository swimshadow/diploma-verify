import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/responsive.dart';
import '../../bloc/university_bloc.dart';
import '../../bloc/university_event.dart';
import '../../bloc/university_state.dart';
import '../../data/models/registry_diploma_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';
import '../../../../shared/widgets/error_state_widget.dart';

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
          if (state is UniversityFailure) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<UniversityBloc>().add(UniversityLoadRequested()),
            );
          }
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
                child: Responsive.isMobile(context)
                    ? Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Поиск по ФИО, номеру...',
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
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<RegistryDiplomaStatus?>(
                                  initialValue: _statusFilter,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  hint: const Text('Статус'),
                                  items: [
                                    const DropdownMenuItem(
                                        value: null, child: Text('Все')),
                                    ...RegistryDiplomaStatus.values.map((s) =>
                                        DropdownMenuItem(
                                            value: s, child: Text(s.label))),
                                  ],
                                  onChanged: (v) {
                                    _log.info(_tag, 'Фильтр статуса: $v');
                                    setState(() => _statusFilter = v);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: () {
                                  _log.info(_tag, 'BTN: Добавить диплом — нажата');
                                  context.push('/university/diploma-upload');
                                },
                                icon: const Icon(Icons.add, size: 20),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
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

              // ── Table or Card list ──
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Дипломы не найдены'))
                    : Responsive.isMobile(context)
                        ? _MobileRegistryList(
                            diplomas: filtered,
                            onTap: (d) {
                              _log.info(_tag, 'Открыть диплом ${d.id}');
                              context.push('/university/diploma/${d.id}');
                            },
                          )
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

class _MobileRegistryList extends StatelessWidget {
  final List<RegistryDiploma> diplomas;
  final ValueChanged<RegistryDiploma> onTap;

  const _MobileRegistryList({
    required this.diplomas,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: diplomas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final d = diplomas[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onTap(d),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          d.holderFullName,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      _StatusBadge(status: d.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Номер', value: '${d.diplomaSeries} ${d.diplomaNumber}'),
                  _InfoRow(label: 'Факультет', value: d.faculty),
                  _InfoRow(label: 'Уровень', value: d.educationLevel),
                  _InfoRow(label: 'GPA', value: d.gpa.toStringAsFixed(2)),
                  if (d.certificateId != null)
                    _InfoRow(label: 'Сертификат', value: d.certificateId!),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
