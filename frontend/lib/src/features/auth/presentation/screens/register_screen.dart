import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // University fields
  final _uniNameCtrl = TextEditingController();
  final _uniInnCtrl = TextEditingController();
  final _uniOgrnCtrl = TextEditingController();

  // Student fields
  final _studentNameCtrl = TextEditingController();
  final _studentDobCtrl = TextEditingController();

  // Employer fields
  final _companyNameCtrl = TextEditingController();
  final _employerInnCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _uniNameCtrl.dispose();
    _uniInnCtrl.dispose();
    _uniOgrnCtrl.dispose();
    _studentNameCtrl.dispose();
    _studentDobCtrl.dispose();
    _companyNameCtrl.dispose();
    _employerInnCtrl.dispose();
    super.dispose();
  }

  String get _roleLabel {
    switch (widget.role) {
      case 'university':
        return 'Университет';
      case 'student':
        return 'Студент';
      case 'employer':
        return 'Работодатель';
      default:
        return 'Пользователь';
    }
  }

  Map<String, dynamic> _buildProfile() {
    switch (widget.role) {
      case 'university':
        return {
          'name': _uniNameCtrl.text.trim(),
          'inn': _uniInnCtrl.text.trim(),
          'ogrn': _uniOgrnCtrl.text.trim(),
        };
      case 'student':
        return {
          'full_name': _studentNameCtrl.text.trim(),
          'date_of_birth': _studentDobCtrl.text.trim(),
        };
      case 'employer':
        return {
          'company_name': _companyNameCtrl.text.trim(),
          'inn': _employerInnCtrl.text.trim(),
        };
      default:
        return {};
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            role: widget.role,
            profile: _buildProfile(),
          ),
        );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      _studentDobCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Регистрация: $_roleLabel')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthRegistered) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Регистрация успешна! Теперь войдите.')),
            );
            context.go('/login');
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Введите email';
                          }
                          if (!v.contains('@')) return 'Некорректный email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock_outlined),
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
                      const SizedBox(height: 16),
                      // Confirm password
                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Подтвердите пароль',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (v) {
                          if (v != _passwordCtrl.text) {
                            return 'Пароли не совпадают';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Role-specific fields
                      Text(
                        'Данные профиля',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      ..._buildProfileFields(),
                      const SizedBox(height: 24),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final loading = state is AuthLoading;
                          return ElevatedButton(
                            onPressed: loading ? null : _submit,
                            child: loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Зарегистрироваться'),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Уже есть аккаунт?'),
                          TextButton(
                            onPressed: () => context.push('/login'),
                            child: const Text('Войти'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProfileFields() {
    switch (widget.role) {
      case 'university':
        return [
          TextFormField(
            controller: _uniNameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Название университета',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _uniInnCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'ИНН',
              prefixIcon: Icon(Icons.numbers),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _uniOgrnCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'ОГРН',
              prefixIcon: Icon(Icons.numbers),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
          ),
        ];
      case 'student':
        return [
          TextFormField(
            controller: _studentNameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'ФИО',
              prefixIcon: Icon(Icons.person_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _studentDobCtrl,
            readOnly: true,
            onTap: _pickDate,
            decoration: const InputDecoration(
              labelText: 'Дата рождения',
              prefixIcon: Icon(Icons.calendar_today_outlined),
              hintText: 'ГГГГ-ММ-ДД',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
          ),
        ];
      case 'employer':
        return [
          TextFormField(
            controller: _companyNameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Название компании',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _employerInnCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'ИНН компании',
              prefixIcon: Icon(Icons.numbers),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
          ),
        ];
      default:
        return [];
    }
  }
}
