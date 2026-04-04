import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

/// Compares a paper diploma image (left) with OCR-recognized digital fields (right).
class DiplomaComparisonScreen extends StatefulWidget {
  const DiplomaComparisonScreen({super.key});

  @override
  State<DiplomaComparisonScreen> createState() =>
      _DiplomaComparisonScreenState();
}

class _DiplomaComparisonScreenState extends State<DiplomaComparisonScreen> {
  String? _imagePath;
  bool _processing = false;
  _OcrResult? _ocrResult;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _imagePath = file.path;
      _processing = true;
      _ocrResult = null;
    });

    try {
      final dio = getIt<DioClient>().dio;
      // 1. Upload file
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final uploadResp = await dio.post(
        '${AppConstants.filesPath}/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final fileId = uploadResp.data['id']?.toString() ?? '';

      // 2. Trigger AI extraction
      await dio.post(AppConstants.aiExtractPath, data: {
        'file_id': fileId,
        'diploma_id': fileId,
      });

      // 3. Wait briefly for result
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      setState(() {
        _processing = false;
        _ocrResult = _OcrResult(
          fullName: uploadResp.data['full_name']?.toString() ?? 'Распознавание...',
          university: uploadResp.data['university']?.toString() ?? '',
          speciality: uploadResp.data['specialization']?.toString() ?? '',
          diplomaNumber: uploadResp.data['diploma_number']?.toString() ?? '',
          issueDate: uploadResp.data['issue_date']?.toString() ?? '',
          educationLevel: uploadResp.data['degree']?.toString() ?? '',
          confidence: (uploadResp.data['confidence'] as num?)?.toDouble() ?? 0.0,
          mismatches: const [],
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _ocrResult = _OcrResult(
          fullName: 'Ошибка распознавания',
          university: '',
          speciality: '',
          diplomaNumber: '',
          issueDate: '',
          educationLevel: '',
          confidence: 0.0,
          mismatches: [e.toString()],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return DashboardScaffold(
      title: 'Сравнение диплома',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Card(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.compare_arrows,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Загрузите фото бумажного диплома. Система распознает текст и сравнит с цифровой записью.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (_imagePath == null) ...[
                  // Upload prompt
                  Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickImage,
                      child: Container(
                        width: 400,
                        height: 260,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                              width: 2),
                          borderRadius: BorderRadius.circular(16),
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 48,
                                color: theme.colorScheme.primary),
                            const SizedBox(height: 12),
                            Text('Загрузить фото диплома',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary)),
                            const SizedBox(height: 4),
                            Text('JPG, PNG, PDF',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Two-column comparison
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _ImagePanel(onReplace: _pickImage)),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _OcrPanel(
                            processing: _processing,
                            result: _ocrResult,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _ImagePanel(onReplace: _pickImage),
                    const SizedBox(height: 20),
                    _OcrPanel(
                      processing: _processing,
                      result: _ocrResult,
                    ),
                  ],
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Image panel (left) ───
class _ImagePanel extends StatelessWidget {
  final VoidCallback onReplace;
  const _ImagePanel({required this.onReplace});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Бумажный диплом',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: onReplace,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Заменить'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('(превью загруженного изображения)',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── OCR result panel (right) ───
class _OcrPanel extends StatelessWidget {
  final bool processing;
  final _OcrResult? result;
  const _OcrPanel({required this.processing, this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.document_scanner,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Распознанные поля',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            if (processing) ...[
              const SizedBox(height: 40),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Center(
                child: Text('Распознавание...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(height: 40),
            ] else if (result != null) ...[
              // Confidence bar
              _ConfidenceBar(confidence: result!.confidence),
              const SizedBox(height: 16),

              _FieldRow(label: 'ФИО', value: result!.fullName),
              _FieldRow(label: 'Университет', value: result!.university),
              _FieldRow(label: 'Специальность', value: result!.speciality),
              _FieldRow(
                  label: 'Номер диплома', value: result!.diplomaNumber),
              _FieldRow(label: 'Дата выдачи', value: result!.issueDate),
              _FieldRow(
                  label: 'Уровень', value: result!.educationLevel),

              if (result!.mismatches.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Text('Предупреждения',
                              style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...result!.mismatches.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $m',
                                style: theme.textTheme.bodySmall),
                          )),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 40),
              Center(
                child: Text('Ожидание обработки...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double confidence;
  const _ConfidenceBar({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).toInt();
    final color = confidence >= 0.85
        ? Colors.green
        : confidence >= 0.6
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Точность распознавания: $pct%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: confidence,
                  backgroundColor: color.withValues(alpha: 0.15),
                  color: color,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  const _FieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _OcrResult {
  final String fullName;
  final String university;
  final String speciality;
  final String diplomaNumber;
  final String issueDate;
  final String educationLevel;
  final double confidence;
  final List<String> mismatches;

  const _OcrResult({
    required this.fullName,
    required this.university,
    required this.speciality,
    required this.diplomaNumber,
    required this.issueDate,
    required this.educationLevel,
    required this.confidence,
    required this.mismatches,
  });
}
