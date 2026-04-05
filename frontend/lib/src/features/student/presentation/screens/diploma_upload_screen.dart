import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/logging/app_logger.dart';
import '../../bloc/diploma_bloc.dart';
import '../../bloc/diploma_event.dart';
import '../../bloc/diploma_state.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

class DiplomaUploadScreen extends StatefulWidget {
  const DiplomaUploadScreen({super.key});

  @override
  State<DiplomaUploadScreen> createState() => _DiplomaUploadScreenState();
}

class _DiplomaUploadScreenState extends State<DiplomaUploadScreen> {
  static const _tag = 'DiplomaUploadScreen';
  final _log = AppLogger.instance;
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;

  @override
  void initState() {
    super.initState();
    _log.info(_tag, 'Screen opened');
  }

  @override
  void dispose() {
    _log.info(_tag, 'Screen disposed');
    super.dispose();
  }

  Future<void> _pickFile() async {
    _log.info(_tag, 'BTN: Выбрать файл — нажата');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        _log.info(_tag, 'Файл выбран: ${file.name} (${file.size} байт)');
        if (file.bytes == null || file.bytes!.isEmpty) {
          _log.error(_tag, 'Файл не содержит данных (bytes == null)');
          if (mounted) {
            AppSnackBar.error(context, 'Не удалось прочитать файл. Попробуйте другой.');
          }
          return;
        }
        if (file.size > 10 * 1024 * 1024) {
          _log.warning(_tag, 'Файл слишком большой: ${file.size} байт');
          if (mounted) {
            AppSnackBar.warning(context, 'Файл слишком большой (макс. 10 МБ)');
          }
          return;
        }
        setState(() {
          _selectedFileName = file.name;
          _selectedFileBytes = file.bytes;
        });
      } else {
        _log.info(_tag, 'Выбор файла отменён пользователем');
      }
    } catch (e, st) {
      _log.error(_tag, 'Ошибка при выборе файла', e, st);
    }
  }

  void _upload() {
    if (_selectedFileBytes == null || _selectedFileName == null) {
      _log.warning(_tag, 'BTN: Загрузить — нажата, но файл не выбран');
      return;
    }
    _log.info(_tag, 'BTN: Загрузить — отправка файла $_selectedFileName (${_selectedFileBytes!.length} байт)');
    context.read<DiplomaBloc>().add(
          DiplomaUploadRequested(
            fileBytes: _selectedFileBytes!,
            fileName: _selectedFileName!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Загрузка диплома',
      body: BlocListener<DiplomaBloc, DiplomaState>(
        listener: (context, state) {
          if (state is DiplomaUploadSuccess) {
            AppSnackBar.success(context, 'Диплом успешно загружен!');
            Navigator.of(context).pop();
          } else if (state is DiplomaFailure) {
            AppSnackBar.error(context, state.message);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Upload area
                  InkWell(
                    onTap: _pickFile,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: theme.colorScheme.surfaceContainerLowest,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _selectedFileName != null
                                ? Icons.check_circle
                                : Icons.cloud_upload_outlined,
                            size: 56,
                            color: _selectedFileName != null
                                ? Colors.green
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFileName ?? 'Нажмите для выбора файла',
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PDF, PNG, JPG — до 10 МБ',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Как это работает',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          _StepItem(
                              number: '1',
                              text: 'Загрузите скан или фото диплома'),
                          _StepItem(
                              number: '2',
                              text:
                                  'AI-система распознает и извлечёт данные'),
                          _StepItem(
                              number: '3',
                              text:
                                  'Университет подтвердит подлинность'),
                          _StepItem(
                              number: '4',
                              text:
                                  'Вы получите цифровой сертификат с QR-кодом'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<DiplomaBloc, DiplomaState>(
                    builder: (context, state) {
                      final loading = state is DiplomaUploadInProgress;
                      return ElevatedButton.icon(
                        onPressed: (_selectedFileBytes != null && !loading)
                            ? _upload
                            : null,
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.upload),
                        label: Text(loading ? 'Загрузка...' : 'Загрузить'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;
  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(number,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
