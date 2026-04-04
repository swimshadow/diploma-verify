import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/data/auth_repository.dart';

class UniversityProfileScreen extends StatefulWidget {
  const UniversityProfileScreen({super.key});

  @override
  State<UniversityProfileScreen> createState() =>
      _UniversityProfileScreenState();
}

class _UniversityProfileScreenState extends State<UniversityProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _editing = false;
  bool _saving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _shortNameCtrl;
  late final TextEditingController _innCtrl;
  late final TextEditingController _ogrnCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _licenseCtrl;
  late final TextEditingController _contactEmailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _responsibleCtrl;

  @override
  void initState() {
    super.initState();
    final profile = _currentProfile;
    _nameCtrl = TextEditingController(text: profile['name'] ?? '');
    _shortNameCtrl = TextEditingController(text: profile['short_name'] ?? '');
    _innCtrl = TextEditingController(text: profile['inn'] ?? '');
    _ogrnCtrl = TextEditingController(text: profile['ogrn'] ?? '');
    _cityCtrl = TextEditingController(text: profile['city'] ?? '');
    _addressCtrl = TextEditingController(text: profile['address'] ?? '');
    _typeCtrl = TextEditingController(text: profile['university_type'] ?? '');
    _licenseCtrl =
        TextEditingController(text: profile['license_number'] ?? '');
    _contactEmailCtrl =
        TextEditingController(text: profile['contact_email'] ?? '');
    _phoneCtrl = TextEditingController(text: profile['phone'] ?? '');
    _websiteCtrl = TextEditingController(text: profile['website'] ?? '');
    _responsibleCtrl =
        TextEditingController(text: profile['responsible_person'] ?? '');
  }

  Map<String, dynamic> get _currentProfile {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) return state.user.profile;
    return {};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortNameCtrl.dispose();
    _innCtrl.dispose();
    _ogrnCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _typeCtrl.dispose();
    _licenseCtrl.dispose();
    _contactEmailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _responsibleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await getIt<AuthRepository>().updateProfile({
        'name': _nameCtrl.text.trim(),
        'short_name': _shortNameCtrl.text.trim(),
        'inn': _innCtrl.text.trim(),
        'ogrn': _ogrnCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'university_type': _typeCtrl.text.trim(),
        'license_number': _licenseCtrl.text.trim(),
        'contact_email': _contactEmailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'responsible_person': _responsibleCtrl.text.trim(),
      });
      if (mounted) {
        context.read<AuthBloc>().add(AuthCheckRequested());
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль сохранён'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Профиль вуза',
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final profile = authState is AuthAuthenticated
              ? authState.user.profile
              : <String, dynamic>{};
          final isVerified = authState is AuthAuthenticated
              ? (authState.user.profile['is_verified'] == true)
              : false;

          if (!_editing) {
            _nameCtrl.text = profile['name'] ?? '';
            _shortNameCtrl.text = profile['short_name'] ?? '';
            _innCtrl.text = profile['inn'] ?? '';
            _ogrnCtrl.text = profile['ogrn'] ?? '';
            _cityCtrl.text = profile['city'] ?? '';
            _addressCtrl.text = profile['address'] ?? '';
            _typeCtrl.text = profile['university_type'] ?? '';
            _licenseCtrl.text = profile['license_number'] ?? '';
            _contactEmailCtrl.text = profile['contact_email'] ?? '';
            _phoneCtrl.text = profile['phone'] ?? '';
            _websiteCtrl.text = profile['website'] ?? '';
            _responsibleCtrl.text = profile['responsible_person'] ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Logo & name ──
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              child: Icon(Icons.school,
                                  size: 48,
                                  color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              profile['name'] ?? 'Не указано',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            if ((profile['short_name'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  profile['short_name'],
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Moderation status ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? Colors.green.withValues(alpha: 0.08)
                              : Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isVerified
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isVerified
                                  ? Icons.verified
                                  : Icons.hourglass_top,
                              color:
                                  isVerified ? Colors.green : Colors.orange,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isVerified
                                    ? 'Статус: Подтверждён администратором'
                                    : 'Статус: Ожидает подтверждения',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isVerified
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // ── Details ──
                      Text('Сведения об учреждении',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _field('Полное название *', _nameCtrl,
                          required: true),
                      _field('Сокращение', _shortNameCtrl),
                      _field('ИНН *', _innCtrl, required: true),
                      _field('ОГРН *', _ogrnCtrl, required: true),
                      _field('Город', _cityCtrl),
                      _field('Адрес', _addressCtrl),
                      _field('Тип учреждения', _typeCtrl),
                      _field('Номер лицензии', _licenseCtrl),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // ── Contact ──
                      Text('Контактная информация',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _field('Контактный Email', _contactEmailCtrl),
                      _field('Телефон', _phoneCtrl),
                      _field('Веб-сайт', _websiteCtrl),
                      _field('Ответственное лицо', _responsibleCtrl),

                      const SizedBox(height: 32),

                      if (!_editing)
                        FilledButton.icon(
                          onPressed: () =>
                              setState(() => _editing = true),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Редактировать профиль'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () =>
                                        setState(() => _editing = false),
                                child: const Text('Отмена'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Сохранить'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _editing
          ? TextFormField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              validator: required
                  ? (v) => (v == null || v.trim().isEmpty)
                      ? 'Обязательное поле'
                      : null
                  : null,
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(label.replaceAll(' *', ''),
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                ),
                Expanded(
                  child: Text(
                    ctrl.text.isEmpty ? '—' : ctrl.text,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
    );
  }
}
