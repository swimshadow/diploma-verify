import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/verify_bloc.dart';
import '../../bloc/verify_state.dart';
import '../../data/models/verification_model.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

class VerifyResultScreen extends StatelessWidget {
  final String resultId;
  const VerifyResultScreen({super.key, required this.resultId});

  @override
  Widget build(BuildContext context) {
    final verifyState = context.read<VerifyBloc>().state;
    final VerificationResult? result;
    if (verifyState is VerifySuccess && verifyState.result.id == resultId) {
      result = verifyState.result;
    } else {
      result = null;
    }

    if (result == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Результат не найден')),
      );
    }

    return _ResultView(result: result);
  }
}

class _ResultView extends StatelessWidget {
  final VerificationResult result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return DashboardScaffold(
      title: 'Результат проверки',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Verdict Banner ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (result.isAuthentic ? Colors.green : Colors.red)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (result.isAuthentic ? Colors.green : Colors.red)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        result.isAuthentic
                            ? Icons.verified
                            : Icons.dangerous,
                        color:
                            result.isAuthentic ? Colors.green : Colors.red,
                        size: 48,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.isAuthentic
                                  ? 'Диплом подлинный'
                                  : 'Подозрение на подделку',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: result.isAuthentic
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Проверено: ${dateFormat.format(result.verifiedAt)} · ${result.method.label}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Diploma Data ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Данные диплома',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _InfoRow(
                            label: 'Диплом', value: result.diplomaTitle),
                        _InfoRow(
                            label: 'Владелец', value: result.holderName),
                        _InfoRow(
                            label: 'Университет',
                            value: result.university),
                        _InfoRow(
                            label: 'Специальность',
                            value: result.speciality),
                        _InfoRow(
                            label: 'Номер',
                            value: result.diplomaNumber),
                        _InfoRow(
                            label: 'Дата выдачи',
                            value: dateFormat.format(result.issueDate)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Verification Checks ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Проверки',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _CheckRow(
                          label: 'Цифровая подпись',
                          passed: result.signatureVerified,
                        ),
                        _CheckRow(
                          label: 'Блокчейн',
                          passed: result.blockchainVerified,
                          subtitle: result.blockchainBlock != null
                              ? 'Блок #${result.blockchainBlock}'
                              : null,
                        ),
                        _CheckRow(
                          label: 'Целостность цепочки',
                          passed: result.chainIntact,
                        ),
                        if (result.timestampProof != null)
                          _InfoRow(
                              label: 'Метка времени',
                              value: result.timestampProof!),
                      ],
                    ),
                  ),
                ),

                // ── Reason (if invalid) ──
                if (result.reason != null && result.reason!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Card(
                    color: Colors.orange.withValues(alpha: 0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.orange, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Причина',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(result.reason!,
                                    style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Actions ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Новая проверка'),
                      ),
                    ),
                  ],
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

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

class _CheckRow extends StatelessWidget {
  final String label;
  final bool passed;
  final String? subtitle;

  const _CheckRow({
    required this.label,
    required this.passed,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: passed ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            passed ? 'Пройдена' : 'Не пройдена',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: passed ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
