import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/diploma_bloc.dart';
import '../../bloc/diploma_event.dart';
import '../../bloc/diploma_state.dart';
import '../../data/models/diploma_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class DiplomaListScreen extends StatelessWidget {
  const DiplomaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Мои дипломы',
      body: BlocBuilder<DiplomaBloc, DiplomaState>(
        builder: (context, state) {
          if (state is! DiplomaLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return _Body(state: state);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final DiplomaLoaded state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _FilterChip(
                label: 'Все',
                selected: state.activeFilter == null,
                onTap: () => context
                    .read<DiplomaBloc>()
                    .add(const DiplomaFilterChanged(null)),
              ),
              const SizedBox(width: 8),
              ...DiplomaStatus.values.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: s.label,
                    selected: state.activeFilter == s,
                    onTap: () => context
                        .read<DiplomaBloc>()
                        .add(DiplomaFilterChanged(s)),
                  ),
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: state.filteredDiplomas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('Дипломы не найдены',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.filteredDiplomas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final d = state.filteredDiplomas[index];
                    return _DiplomaCard(diploma: d);
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _DiplomaCard extends StatelessWidget {
  final Diploma diploma;
  const _DiplomaCard({required this.diploma});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(diploma.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/student/diploma/${diploma.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(_statusIcon(diploma.status),
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(diploma.title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(diploma.university,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(diploma.status.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: color, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoPill(
                      icon: Icons.numbers,
                      text: diploma.diplomaNumber),
                  const SizedBox(width: 12),
                  _InfoPill(
                      icon: Icons.school_outlined,
                      text: diploma.speciality),
                ],
              ),
              if (diploma.trustScore > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Trust Score: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: diploma.trustScore,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          color: _trustColor(diploma.trustScore),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(diploma.trustScore * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _trustColor(diploma.trustScore))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(DiplomaStatus s) {
    switch (s) {
      case DiplomaStatus.verified:
        return Colors.green;
      case DiplomaStatus.processing:
      case DiplomaStatus.pending:
        return Colors.orange;
      case DiplomaStatus.revoked:
        return Colors.red;
    }
  }

  IconData _statusIcon(DiplomaStatus s) {
    switch (s) {
      case DiplomaStatus.verified:
        return Icons.verified;
      case DiplomaStatus.processing:
        return Icons.hourglass_top;
      case DiplomaStatus.pending:
        return Icons.cloud_upload;
      case DiplomaStatus.revoked:
        return Icons.cancel;
    }
  }

  Color _trustColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
