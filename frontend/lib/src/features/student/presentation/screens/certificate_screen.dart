import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../bloc/diploma_bloc.dart';
import '../../bloc/diploma_state.dart';
import '../../data/models/diploma_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class CertificateScreen extends StatelessWidget {
  final String certificateId;
  const CertificateScreen({super.key, required this.certificateId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiplomaBloc, DiplomaState>(
      builder: (context, state) {
        Diploma? diploma;
        if (state is DiplomaLoaded) {
          diploma = state.allDiplomas
              .where((d) => d.certificateId == certificateId)
              .firstOrNull;
        }

        if (diploma == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Сертификат не найден')),
          );
        }

        return _CertView(diploma: diploma, certificateId: certificateId);
      },
    );
  }
}

class _CertView extends StatelessWidget {
  final Diploma diploma;
  final String certificateId;
  const _CertView({required this.diploma, required this.certificateId});

  String get _verifyUrl =>
      '${AppConstants.publicBaseUrl}/verify/$certificateId';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardScaffold(
      title: 'Сертификат',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // Certificate card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(Icons.verified,
                            size: 48, color: Colors.green),
                        const SizedBox(height: 12),
                        Text('Диплом подтверждён',
                            style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        const SizedBox(height: 24),

                        // QR
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                            data: _verifyUrl,
                            version: QrVersions.auto,
                            size: 200,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Отсканируйте QR-код для проверки',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        _CertRow(label: 'ID сертификата',
                            value: certificateId),
                        _CertRow(
                            label: 'Диплом', value: diploma.title),
                        _CertRow(
                            label: 'Университет',
                            value: diploma.university),
                        _CertRow(
                            label: 'Специальность',
                            value: diploma.speciality),
                        _CertRow(
                            label: 'Номер',
                            value: diploma.diplomaNumber),
                        _CertRow(
                            label: 'Trust Score',
                            value:
                                '${(diploma.trustScore * 100).toInt()}%'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Actions
                ElevatedButton.icon(
                  onPressed: () {
                    Share.share(
                        'Мой подтверждённый диплом — $certificateId\nПроверить: $_verifyUrl',
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Поделиться'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Скачивание будет доступно позже')),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Скачать PDF'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CertRow extends StatelessWidget {
  final String label;
  final String value;
  const _CertRow({required this.label, required this.value});

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
