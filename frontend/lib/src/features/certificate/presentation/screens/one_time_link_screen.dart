import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../certificate/data/certificate_repository.dart';
import '../../../student/bloc/diploma_bloc.dart';
import '../../../student/bloc/diploma_state.dart';
import '../../../student/data/models/diploma_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class OneTimeLinkScreen extends StatefulWidget {
  final String diplomaId;
  const OneTimeLinkScreen({super.key, required this.diplomaId});

  @override
  State<OneTimeLinkScreen> createState() => _OneTimeLinkScreenState();
}

class _OneTimeLinkScreenState extends State<OneTimeLinkScreen> {
  String? _generatedToken;
  DateTime? _expiresAt;
  int _expirationHours = 24;
  bool _loading = false;
  bool _copied = false;

  String get _link => _generatedToken != null
      ? '${AppConstants.publicBaseUrl}/share/$_generatedToken'
      : '';

  void _generate() {
    setState(() => _loading = true);

    // Retrieve diploma data for the certificate generation request
    final diplomaState = context.read<DiplomaBloc>().state;
    Diploma? diploma;
    if (diplomaState is DiplomaLoaded) {
      diploma = diplomaState.allDiplomas
          .where((d) => d.id == widget.diplomaId)
          .firstOrNull;
    }

    getIt<CertificateRepository>()
        .generate(
      widget.diplomaId,
      diplomaData: {
        'full_name': diploma?.title ?? '',
        'degree': diploma?.title ?? '',
        'specialization': diploma?.speciality ?? '',
        'issue_date': diploma?.issueDate.toIso8601String().split('T').first ?? '',
        'university_name': diploma?.university ?? '',
      },
    )
        .then((data) {
      if (!mounted) return;
      setState(() {
        _generatedToken = (data['qr_token'] ?? data['token'] ?? '').toString();
        _expiresAt = DateTime.tryParse(data['expires_at'] ?? '') ??
            DateTime.now().add(Duration(hours: _expirationHours));
        _loading = false;
        _copied = false;
      });
    }).catchError((e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    });
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _link));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ссылка скопирована'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Одноразовая ссылка',
      body: BlocBuilder<DiplomaBloc, DiplomaState>(
        builder: (context, state) {
          Diploma? diploma;
          if (state is DiplomaLoaded) {
            diploma = state.allDiplomas
                .where((d) => d.id == widget.diplomaId)
                .firstOrNull;
          }
          if (diploma == null) {
            return const Center(child: Text('Диплом не найден'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Diploma info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.description,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(diploma.title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${diploma.university} · ${diploma.diplomaNumber}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Expiration selector
                    Text('Срок действия ссылки',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1 час')),
                        ButtonSegment(value: 24, label: Text('24 часа')),
                        ButtonSegment(value: 72, label: Text('3 дня')),
                        ButtonSegment(value: 168, label: Text('7 дней')),
                      ],
                      selected: {_expirationHours},
                      onSelectionChanged: (val) {
                        setState(() {
                          _expirationHours = val.first;
                          _generatedToken = null; // reset on change
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Generate button
                    FilledButton.icon(
                      onPressed: _loading ? null : _generate,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.link),
                      label: Text(_generatedToken != null
                          ? 'Сгенерировать заново'
                          : 'Сгенерировать ссылку'),
                    ),

                    // Generated link
                    if (_generatedToken != null) ...[
                      const SizedBox(height: 24),
                      Card(
                        color: Colors.green.withValues(alpha: 0.06),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Ссылка создана',
                                      style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          theme.colorScheme.outlineVariant),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        _link,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                fontFamily: 'monospace'),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                          _copied
                                              ? Icons.check
                                              : Icons.copy,
                                          size: 18),
                                      onPressed: _copy,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Действует до: ${_expiresAt!.day.toString().padLeft(2, '0')}.${_expiresAt!.month.toString().padLeft(2, '0')}.${_expiresAt!.year} ${_expiresAt!.hour.toString().padLeft(2, '0')}:${_expiresAt!.minute.toString().padLeft(2, '0')}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Одноразовая — после первого просмотра ссылка станет недействительной.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _copy,
                                      icon: const Icon(Icons.copy, size: 16),
                                      label: const Text('Копировать'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Share.share(
                                          'Проверьте мой диплом по одноразовой ссылке:\n$_link',
                                        );
                                      },
                                      icon:
                                          const Icon(Icons.share, size: 16),
                                      label: const Text('Поделиться'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
