import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/admin_bloc.dart';
import '../../bloc/admin_event.dart';
import '../../bloc/admin_state.dart';
import '../../data/models/admin_models.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/crypto/ecp_service.dart';

class AdminModerationScreen extends StatelessWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd.MM.yyyy');

    return DashboardScaffold(
      title: 'Модерация вузов',
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminFailure) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<AdminBloc>().add(AdminLoadRequested()),
            );
          }
          if (state is! AdminLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final pending = state.universities
              .where((u) => u.status == ModerationStatus.pending)
              .toList();
          final processed = state.universities
              .where((u) => u.status != ModerationStatus.pending)
              .toList();

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
              vertical: Responsive.isMobile(context) ? 16 : 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Responsive.isMobile(context) ? double.infinity : 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Pending ──
                    Text(
                        'Ожидают модерации (${pending.length})',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (pending.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade300),
                              const SizedBox(width: 8),
                              const Text('Нет заявок на модерации'),
                            ],
                          ),
                        ),
                      )
                    else
                      ...pending.map((uni) => _PendingCard(
                            uni: uni,
                            dateFmt: dateFmt,
                          )),

                    const SizedBox(height: 32),

                    // ── Processed ──
                    Text('Обработанные (${processed.length})',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...processed.map((uni) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _statusColor(uni.status)
                                      .withValues(alpha: 0.12),
                              child: Icon(
                                uni.status == ModerationStatus.approved
                                    ? Icons.verified
                                    : Icons.cancel,
                                color: _statusColor(uni.status),
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Flexible(child: Text(uni.name)),
                                if (uni.ecpVerified) ...[
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: 'Подтверждено электронной подписью',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: Colors.green.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified_user,
                                              size: 14,
                                              color: Colors.green.shade700),
                                          const SizedBox(width: 3),
                                          Text('ЭП',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      Colors.green.shade700)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              '${uni.city} · ${uni.contactEmail}'
                              '${uni.moderatorComment != null ? '\n${uni.moderatorComment}' : ''}',
                            ),
                            trailing: Text(uni.status.label,
                                style: TextStyle(
                                    color: _statusColor(uni.status),
                                    fontWeight: FontWeight.w600)),
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

  static Color _statusColor(ModerationStatus status) {
    switch (status) {
      case ModerationStatus.approved:
        return Colors.green;
      case ModerationStatus.rejected:
        return Colors.red;
      case ModerationStatus.pending:
        return Colors.orange;
    }
  }
}

class _PendingCard extends StatelessWidget {
  final ModerationUniversity uni;
  final DateFormat dateFmt;
  const _PendingCard({required this.uni, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance,
                    color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(uni.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${uni.city} · ${uni.contactEmail}',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Заявка подана: ${dateFmt.format(uni.appliedAt)}',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context),
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                  label: const Text('Отклонить',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red)),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _showEcpApprovalDialog(context),
                  icon: const Icon(Icons.verified_user, size: 18),
                  label: const Text('Подтвердить с ЭП'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Отклонить: ${uni.name}'),
        content: TextField(
          controller: commentCtrl,
          decoration: const InputDecoration(
            labelText: 'Причина отклонения',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              context.read<AdminBloc>().add(
                    AdminRejectUniversity(
                      uni.id,
                      commentCtrl.text.isNotEmpty
                          ? commentCtrl.text
                          : 'Без комментария',
                    ),
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${uni.name} отклонён'),
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }

  void _showEcpApprovalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _EcpApprovalDialog(uni: uni),
    );
  }
}

class _EcpApprovalDialog extends StatefulWidget {
  final ModerationUniversity uni;
  const _EcpApprovalDialog({required this.uni});

  @override
  State<_EcpApprovalDialog> createState() => _EcpApprovalDialogState();
}

class _EcpApprovalDialogState extends State<_EcpApprovalDialog> {
  String? _fileName;
  String? _privateKeyPem;
  String? _errorMessage;
  bool _keyValid = false;
  bool _signing = false;
  String? _keyInfo;

  Future<void> _pickKeyFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pem', 'key', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      setState(() {
        _errorMessage = 'Не удалось прочитать файл';
        _keyValid = false;
      });
      return;
    }

    final pem = utf8.decode(file.bytes!);
    setState(() {
      _fileName = file.name;
      _privateKeyPem = pem;
      _errorMessage = null;
    });

    _validateKey(pem);
  }

  void _validateKey(String pem) {
    try {
      final ecpService = EcpService();
      final privateKey = ecpService.parsePrivateKeyPem(pem);
      final bits = privateKey.modulus!.bitLength;
      setState(() {
        _keyValid = true;
        _keyInfo = 'RSA-$bits';
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _keyValid = false;
        _keyInfo = null;
        _errorMessage = 'Неверный формат ключа: $e';
      });
    }
  }

  void _generateAndUseKey() {
    setState(() => _signing = true);
    try {
      final ecpService = EcpService();
      final pair = ecpService.generateKeyPair();
      final pem = ecpService.privateKeyToPem(pair.privateKey);
      setState(() {
        _privateKeyPem = pem;
        _fileName = 'Сгенерированный ключ RSA-2048';
        _keyValid = true;
        _keyInfo = 'RSA-2048 (новый)';
        _errorMessage = null;
        _signing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка генерации ключа: $e';
        _signing = false;
      });
    }
  }

  void _signAndApprove() {
    if (_privateKeyPem == null || !_keyValid) return;
    setState(() => _signing = true);

    context.read<AdminBloc>().add(
          AdminApproveUniversityWithEcp(widget.uni.id, _privateKeyPem!),
        );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('${widget.uni.name} подтверждён с ЭП'),
        ],
      ),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.verified_user, color: Colors.green.shade700),
          const SizedBox(width: 8),
          const Expanded(child: Text('Подтверждение с ЭП')),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.uni.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Электронная подпись',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Загрузите PEM-файл приватного ключа RSA или сгенерируйте новый.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _signing ? null : _pickKeyFile,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Загрузить ключ'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _signing ? null : _generateAndUseKey,
                    icon: const Icon(Icons.key, size: 18),
                    label: const Text('Сгенерировать'),
                  ),
                ),
              ],
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _keyValid
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _keyValid
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _keyValid ? Icons.check_circle : Icons.error,
                      color: _keyValid ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_fileName!,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          if (_keyInfo != null)
                            Text('Алгоритм: $_keyInfo',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Подпись подтверждает решение администратора '
                      'и сохраняется в системе как доказательство.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton.icon(
          onPressed: _keyValid && !_signing ? _signAndApprove : null,
          icon: _signing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.draw, size: 18),
          label: const Text('Подписать и подтвердить'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade700,
          ),
        ),
      ],
    );
  }
}
