import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class UniversityDiplomaUploadScreen extends StatefulWidget {
  const UniversityDiplomaUploadScreen({super.key});

  @override
  State<UniversityDiplomaUploadScreen> createState() =>
      _UniversityDiplomaUploadScreenState();
}

class _UniversityDiplomaUploadScreenState
    extends State<UniversityDiplomaUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _facultyCtrl = TextEditingController();
  final _specialityCtrl = TextEditingController();
  final _seriesCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _gpaCtrl = TextEditingController();

  String _educationLevel = 'Бакалавр';
  DateTime? _issueDate;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _facultyCtrl.dispose();
    _specialityCtrl.dispose();
    _seriesCtrl.dispose();
    _numberCtrl.dispose();
    _gpaCtrl.dispose();
    super.dispose();
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
                  Text('Данные выпускника',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _fullNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ФИО выпускника *',
                      prefixIcon: Icon(Icons.person_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _facultyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Факультет *',
                      prefixIcon: Icon(Icons.business_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _specialityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Специальность *',
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
                    onChanged: (v) => setState(() => _educationLevel = v!),
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
                            labelText: 'Серия *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Обязательно' : null,
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
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Обязательно' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _gpaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'GPA *',
                      prefixIcon: Icon(Icons.grade_outlined),
                      border: OutlineInputBorder(),
                      hintText: '0.00 – 4.00',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Обязательное поле';
                      final gpa = double.tryParse(v.trim());
                      if (gpa == null || gpa < 0 || gpa > 4) {
                        return 'GPA от 0 до 4';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _issueDate = picked);
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
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить в реестр'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.pop(),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_issueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату выдачи')),
      );
      return;
    }
    // Mock save
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Диплом успешно добавлен в реестр'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }
}
