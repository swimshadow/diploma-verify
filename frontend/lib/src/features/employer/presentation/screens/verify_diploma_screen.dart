import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/verify_bloc.dart';
import '../../bloc/verify_event.dart';
import '../../bloc/verify_state.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

class VerifyDiplomaScreen extends StatefulWidget {
  const VerifyDiplomaScreen({super.key});

  @override
  State<VerifyDiplomaScreen> createState() => _VerifyDiplomaScreenState();
}

class _VerifyDiplomaScreenState extends State<VerifyDiplomaScreen> {
  final _certIdController = TextEditingController();
  String? _selectedFileName;
  String? _certIdError;

  @override
  void dispose() {
    _certIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<VerifyBloc, VerifyState>(
      listener: (context, state) {
        if (state is VerifySuccess) {
          context.push('/employer/verify-result/${state.result.id}');
        } else if (state is VerifyFailure) {
          AppSnackBar.error(context, state.message);
        }
      },
      child: DashboardScaffold(
        title: 'Проверка диплома',
        body: BlocBuilder<VerifyBloc, VerifyState>(
          builder: (context, state) {
            final isLoading = state is VerifyLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Выберите способ проверки',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Проверьте подлинность диплома одним из трёх способов',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 28),

                      // ── Method 1: Certificate ID ──
                      _MethodCard(
                        icon: Icons.fingerprint,
                        title: 'По ID сертификата',
                        description:
                            'Введите уникальный Certificate ID для мгновенной проверки',
                        child: Column(
                          children: [
                            TextField(
                              controller: _certIdController,
                              decoration: InputDecoration(
                                hintText: 'Введите Certificate ID',
                                prefixIcon: const Icon(Icons.tag),
                                errorText: _certIdError,
                              ),
                              enabled: !isLoading,
                              onChanged: (_) {
                                if (_certIdError != null) {
                                  setState(() => _certIdError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        final id =
                                            _certIdController.text.trim();
                                        if (id.isEmpty) {
                                          setState(() => _certIdError = 'Введите ID сертификата');
                                          return;
                                        }
                                        context
                                            .read<VerifyBloc>()
                                            .add(VerifyByCertificateId(id));
                                      },
                                icon: const Icon(Icons.search),
                                label: const Text('Проверить'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Method 2: QR Code ──
                      _MethodCard(
                        icon: Icons.qr_code_scanner,
                        title: 'По QR-коду',
                        description:
                            'Отсканируйте QR-код с сертификата диплома',
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Наведите камеру на QR-код сертификата')),
                                    );
                                  },
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Сканировать QR-код'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Method 3: File upload ──
                      _MethodCard(
                        icon: Icons.upload_file,
                        title: 'Загрузить файл',
                        description:
                            'Загрузите скан или фото диплома для AI-анализа',
                        child: Column(
                          children: [
                            InkWell(
                              onTap: isLoading ? null : _pickFile,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 28),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.4),
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.cloud_upload_outlined,
                                        size: 40,
                                        color: theme
                                            .colorScheme.onSurfaceVariant),
                                    const SizedBox(height: 8),
                                    Text(
                                      _selectedFileName ??
                                          'Нажмите для выбора файла',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: _selectedFileName != null
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('PDF, PNG, JPG до 10 МБ',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                            if (_selectedFileName != null) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          context.read<VerifyBloc>().add(
                                                VerifyByFileUpload(
                                                  filePath:
                                                      _selectedFileName!,
                                                  fileName:
                                                      _selectedFileName!,
                                                ),
                                              );
                                        },
                                  icon: const Icon(Icons.verified_outlined),
                                  label: const Text('Анализировать'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (isLoading) ...[
                        const SizedBox(height: 32),
                        const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Проверяем диплом...'),
                            ],
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
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFileName = result.files.first.name;
      });
    }
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  child:
                      Icon(icon, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(description,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
