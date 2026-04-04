import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/logging/app_logger.dart';
import '../../bloc/university_bloc.dart';
import '../../bloc/university_event.dart';
import '../../bloc/university_state.dart';
import '../../data/models/certificate_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

const _tag = 'UniversityCertificatesScreen';

class UniversityCertificatesScreen extends StatelessWidget {
  const UniversityCertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd.MM.yyyy');

    return DashboardScaffold(
      title: 'Сертификаты',
      body: BlocBuilder<UniversityBloc, UniversityState>(
        builder: (context, state) {
          if (state is! UniversityLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.certificates.isEmpty) {
            return const Center(child: Text('Сертификаты не найдены'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Summary ──
                    Row(
                      children: [
                        _SummaryChip(
                          label: 'Всего',
                          count: state.certificates.length,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _SummaryChip(
                          label: 'Активных',
                          count: state.certificates
                              .where(
                                  (c) => c.status == CertificateStatus.active)
                              .length,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _SummaryChip(
                          label: 'Истёкших',
                          count: state.certificates
                              .where(
                                  (c) => c.status == CertificateStatus.expired)
                              .length,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── List ──
                    ...state.certificates.map((cert) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.card_membership,
                                      color: _statusColor(cert.status),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(cert.id,
                                              style: theme.textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                          Text(cert.holderFullName,
                                              style: theme
                                                  .textTheme.bodyMedium),
                                        ],
                                      ),
                                    ),
                                    _CertStatusBadge(status: cert.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _MetaItem(
                                        icon: Icons.numbers,
                                        text: cert.diplomaNumber),
                                    const SizedBox(width: 16),
                                    _MetaItem(
                                        icon: Icons.calendar_today,
                                        text: dateFmt
                                            .format(cert.issuedAt)),
                                    if (cert.expiresAt != null) ...[
                                      const SizedBox(width: 16),
                                      _MetaItem(
                                          icon: Icons.event_busy,
                                          text:
                                              'до ${dateFmt.format(cert.expiresAt!)}'),
                                    ],
                                    const SizedBox(width: 16),
                                    _MetaItem(
                                        icon: Icons.visibility,
                                        text:
                                            '${cert.checksCount} проверок'),
                                  ],
                                ),
                                if (cert.canReissue) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.tonal(
                                      onPressed: () {
                                        AppLogger.instance.info(_tag, 'BTN: Перевыпустить сертификат ${cert.id}');
                                        context
                                            .read<UniversityBloc>()
                                            .add(UniversityReissueCertificate(
                                                cert.id));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Сертификат ${cert.id} перевыпущен'),
                                          behavior:
                                              SnackBarBehavior.floating,
                                        ));
                                      },
                                      child:
                                          const Text('Перевыпустить'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Color _statusColor(CertificateStatus status) {
    switch (status) {
      case CertificateStatus.active:
        return Colors.green;
      case CertificateStatus.expired:
        return Colors.orange;
      case CertificateStatus.revoked:
        return Colors.red;
      case CertificateStatus.reissued:
        return Colors.blue;
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $count',
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
    );
  }
}

class _CertStatusBadge extends StatelessWidget {
  final CertificateStatus status;
  const _CertStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = UniversityCertificatesScreen._statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
