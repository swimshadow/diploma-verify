import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/logging/app_logger.dart';
import '../../bloc/university_bloc.dart';
import '../../bloc/university_event.dart';
import '../../data/university_repository.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

const _tag = 'UniversityDiplomaUpload';

class UniversityDiplomaUploadScreen extends StatefulWidget {
  const UniversityDiplomaUploadScreen({super.key});

  @override
  State<UniversityDiplomaUploadScreen> createState() =>
      _UniversityDiplomaUploadScreenState();
}

class _UniversityDiplomaUploadScreenState
    extends State<UniversityDiplomaUploadScreen> {
  final _log = AppLogger.instance;
  final _formKey = GlobalKey<FormState>();
  final _surnameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _patronymicCtrl = TextEditingController();
  final _specialityCtrl = TextEditingController();
  final _seriesCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _studentEmailCtrl = TextEditingController();
  final _studentPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;

  String _educationLevel = 'Бакалавр';
  DateTime? _issueDate;
  DateTime? _dateOfBirth;

  String? _pickedFileName;
  List<int>? _pickedFileBytes;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _log.info(_tag, 'Screen opened');
  }

  @override
  void dispose() {
    _surnameCtrl.dispose();
    _firstNameCtrl.dispose();
    _patronymicCtrl.dispose();
    _specialityCtrl.dispose();
    _seriesCtrl.dispose();
    _numberCtrl.dispose();
    _dobCtrl.dispose();
    _studentEmailCtrl.dispose();
    _studentPasswordCtrl.dispose();
    _log.info(_tag, 'Screen disposed');
    super.dispose();
  }

  Future<void> _pickPdf() async {
    _log.info(_tag, 'BTN: Выбрать PDF — нажата');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        _log.info(_tag, 'PDF выбран: ${file.name}, ${file.size} bytes');
        setState(() {
          _pickedFileName = file.name;
          _pickedFileBytes = file.bytes;
        });
      } else {
        _log.info(_tag, 'Выбор PDF отменён пользователем');
      }
    } catch (e, st) {
      _log.error(_tag, 'Ошибка выбора файла: $e', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DashboardScaffold(
      title: 'Добавить диплом',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── PDF file picker ───────────────────────
                  Text('PDF-файл диплома',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickPdf,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _pickedFileName != null
                              ? Colors.green
                              : theme.colorScheme.outlineVariant,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.surfaceContainerLowest,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _pickedFileName != null
                                ? Icons.check_circle
                                : Icons.upload_file,
                            size: 48,
                            color: _pickedFileName != null
                                ? Colors.green
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _pickedFileName ?? 'Нажмите для выбора PDF',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text('Данные выпускника',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _surnameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Фамилия *',
                      prefixIcon: Icon(Icons.person_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _firstNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Имя *',
                      prefixIcon: Icon(Icons.person_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _patronymicCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Отчество',
                      prefixIcon: Icon(Icons.person_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _specialityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Специализация *',
                      prefixIcon: Icon(Icons.book_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _educationLevel,
                    decoration: const InputDecoration(
                      labelText: 'Уровень образования *',
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Бакалавр', child: Text('Бакалавр')),
                      DropdownMenuItem(value: 'Магистр', child: Text('Магистр')),
                      DropdownMenuItem(value: 'Специалист', child: Text('Специалист')),
                      DropdownMenuItem(value: 'Доктор PhD', child: Text('Доктор PhD')),
                    ],
                    onChanged: (v) {
                      _log.info(_tag, 'BTN: Уровень образования изменён на $v');
                      setState(() => _educationLevel = v!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date of birth picker
                  InkWell(
                    onTap: () async {
                      _log.info(_tag, 'BTN: Дата рождения — нажата');
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000, 1, 1),
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        _log.info(_tag, 'Дата рождения выбрана: $picked');
                        setState(() => _dateOfBirth = picked);
                      } else {
                        _log.info(_tag, 'Выбор даты рождения отменён');
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата рождения',
                        prefixIcon: Icon(Icons.cake_outlined),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dateOfBirth != null
                            ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}.${_dateOfBirth!.month.toString().padLeft(2, '0')}.${_dateOfBirth!.year}'
                            : 'Выберите дату (необязательно)',
                        style: TextStyle(
                          color: _dateOfBirth != null
                              ? null
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text('Аккаунт студента',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'При загрузке диплома студенту будет автоматически создан аккаунт',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _studentEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email студента *',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Обязательное поле';
                      }
                      if (!v.contains('@')) return 'Некорректный email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _studentPasswordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Пароль студента *',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Минимум 6 символов';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),
                  Text('Данные диплома',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _seriesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Серия',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _numberCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Номер диплома *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Обязательно' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () async {
                      _log.info(_tag, 'BTN: Дата выдачи — нажата');
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        _log.info(_tag, 'Дата выдачи выбрана: $picked');
                        setState(() => _issueDate = picked);
                      } else {
                        _log.info(_tag, 'Выбор даты выдачи отменён');
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата выдачи *',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _issueDate != null
                            ? '${_issueDate!.day.toString().padLeft(2, '0')}.${_issueDate!.month.toString().padLeft(2, '0')}.${_issueDate!.year}'
                            : 'Выберите дату',
                        style: TextStyle(
                          color: _issueDate != null
                              ? null
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_loading ? 'Загрузка...' : 'Сохранить в реестр'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      _log.info(_tag, 'BTN: Отмена — нажата');
                      context.pop();
                    },
                    child: const Text('Отмена'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    _log.info(_tag, 'BTN: Сохранить в реестр — нажата');

    if (!_formKey.currentState!.validate()) {
      _log.warning(_tag, 'Валидация формы не пройдена');
      return;
    }
    if (_pickedFileBytes == null || _pickedFileName == null) {
      _log.warning(_tag, 'PDF файл не выбран');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите PDF-файл диплома')),
      );
      return;
    }
    if (_issueDate == null) {
      _log.warning(_tag, 'Дата выдачи не выбрана');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату выдачи')),
      );
      return;
    }

    final fullName = [
      _surnameCtrl.text.trim(),
      _firstNameCtrl.text.trim(),
      if (_patronymicCtrl.text.trim().isNotEmpty) _patronymicCtrl.text.trim(),
    ].join(' ');

    final metadata = {
      'full_name': fullName,
      'diploma_number': _numberCtrl.text.trim(),
      'series': _seriesCtrl.text.trim(),
      'degree': _educationLevel,
      'specialization': _specialityCtrl.text.trim(),
      'issue_date': '${_issueDate!.year}-${_issueDate!.month.toString().padLeft(2, '0')}-${_issueDate!.day.toString().padLeft(2, '0')}',
      'student_email': _studentEmailCtrl.text.trim(),
      'student_password': _studentPasswordCtrl.text,
      if (_dateOfBirth != null)
        'date_of_birth':
            '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
    };

    _log.info(_tag, 'Метаданные для отправки: ${jsonEncode(metadata)}');
    _log.info(_tag, 'Файл: $_pickedFileName, ${_pickedFileBytes!.length} bytes');

    setState(() => _loading = true);

    try {
      final repo = getIt<UniversityRepository>();
      _log.info(_tag, 'Вызов repo.uploadDiploma...');
      final diplomaId = await repo.uploadDiploma(
        fileBytes: _pickedFileBytes!,
        fileName: _pickedFileName!,
        metadata: metadata,
      );
      _log.info(_tag, 'Диплом загружен, ID: $diplomaId');
      if (!mounted) return;
      context.read<UniversityBloc>().add(UniversityLoadRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Диплом успешно добавлен в реестр'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e, st) {
      _log.error(_tag, 'Ошибка загрузки диплома: $e', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
