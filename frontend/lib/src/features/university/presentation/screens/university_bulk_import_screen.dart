import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import '../../bloc/import_bloc.dart';
import '../../bloc/import_event.dart';
import '../../bloc/import_state.dart';
import '../../data/models/import_model.dart';
import '../../../university/bloc/university_bloc.dart';
import '../../../university/bloc/university_state.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class UniversityBulkImportScreen extends StatelessWidget {
  const UniversityBulkImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Массовый импорт',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Upload area ──
                _UploadSection(theme: theme),

                const SizedBox(height: 12),
                Text(
                  'Поддерживаемые форматы: CSV, XLSX, JSON, XML, ZIP-архив',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),

                const SizedBox(height: 32),

                // ── Import progress ──
                BlocBuilder<ImportBloc, ImportState>(
                  builder: (context, state) {
                    if (state is ImportRunning) {
                      return _ProgressCard(job: state.job, theme: theme);
                    }
                    if (state is ImportCompleted) {
                      return _CompletedCard(job: state.job, theme: theme);
                    }
                    if (state is ImportFailed) {
                      return Card(
                        color: Colors.red.withValues(alpha: 0.08),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 12),
                              Text(state.message,
                                  style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 32),

                // ── Import history ──
                Text('История импортов',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                BlocBuilder<UniversityBloc, UniversityState>(
                  builder: (context, state) {
                    if (state is! UniversityLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.importJobs.isEmpty) {
                      return const Text('Импортов пока нет');
                    }
                    return Column(
                      children: state.importJobs
                          .map((job) => _ImportHistoryTile(job: job))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadSection extends StatelessWidget {
  final ThemeData theme;
  const _UploadSection({required this.theme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pickFile(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.primary.withValues(alpha: 0.04),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined,
                size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Нажмите для загрузки файла',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Или перетащите файл сюда',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'json', 'xml', 'zip'],
    );
    if (result != null && result.files.isNotEmpty && context.mounted) {
      final file = result.files.first;
      context.read<ImportBloc>().add(ImportStarted(
            fileName: file.name,
            formatLabel: file.extension ?? 'csv',
          ));
    }
  }
}

class _ProgressCard extends StatelessWidget {
  final ImportJob job;
  final ThemeData theme;
  const _ProgressCard({required this.job, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text('Импорт: ${job.fileName}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: job.progress),
            const SizedBox(height: 8),
            Text(
              '${job.processedRecords} из ${job.totalRecords} записей '
              '(${(job.progress * 100).toInt()}%)',
              style: theme.textTheme.bodySmall,
            ),
            if (job.errorsCount > 0) ...[
              const SizedBox(height: 8),
              Text('Ошибок: ${job.errorsCount}',
                  style: const TextStyle(color: Colors.orange)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  final ImportJob job;
  final ThemeData theme;
  const _CompletedCard({required this.job, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Text('Импорт завершён: ${job.fileName}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Обработано: ${job.processedRecords} записей'),
            if (job.errorsCount > 0) ...[
              const SizedBox(height: 4),
              Text('Ошибок: ${job.errorsCount}',
                  style: const TextStyle(color: Colors.orange)),
              const SizedBox(height: 12),
              Text('Детали ошибок:',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...job.errors.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• Строка ${e.row}, поле «${e.field}»: ${e.message}',
                      style: theme.textTheme.bodySmall,
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImportHistoryTile extends StatelessWidget {
  final ImportJob job;
  const _ImportHistoryTile({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          job.status == ImportStatus.completed
              ? Icons.check_circle
              : job.status == ImportStatus.inProgress
                  ? Icons.sync
                  : job.status == ImportStatus.failed
                      ? Icons.error
                      : Icons.schedule,
          color: _color,
        ),
        title: Text(job.fileName),
        subtitle: Text(
            '${job.format.label} · ${job.processedRecords}/${job.totalRecords}${job.errorsCount > 0 ? ' · ${job.errorsCount} ошибок' : ''}'),
        trailing: Text(job.status.label,
            style: TextStyle(color: _color, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Color get _color {
    switch (job.status) {
      case ImportStatus.completed:
        return Colors.green;
      case ImportStatus.inProgress:
        return Colors.blue;
      case ImportStatus.failed:
        return Colors.red;
      case ImportStatus.pending:
        return Colors.grey;
    }
  }
}
