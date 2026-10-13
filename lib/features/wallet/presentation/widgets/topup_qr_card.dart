import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../kao_id/governance/presentation/widgets/admin_display.dart';
import '../../domain/entities/topup_request.dart';
import '../utils/topup_texts.dart';

/// The member's open request: the PromptPay QR while it waits for the slip,
/// otherwise its review state.
class TopupOpenCard extends StatelessWidget {
  const TopupOpenCard({
    super.key,
    required this.request,
    required this.busy,
    required this.onSendSlip,
    required this.onCancel,
  });

  final TopupRequest request;
  final bool busy;
  final VoidCallback onSendSlip;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final qr = request.qrPayload;
    final waiting = request.status == TopupStatus.awaitingSlip;
    return Card(
      key: const ValueKey('topup-open'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.topupOpenTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${request.code} · ${topupStatusText(l, request.status)}'),
            const SizedBox(height: 12),
            Text(topupBaht(request.amount), style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
            if (waiting && qr != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(key: const ValueKey('topup-qr'), data: qr, size: 240),
                ),
              ),
              const SizedBox(height: 12),
              Text(l.topupScanHelp, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('${l.topupReceiver}: ${realValue(request.receiverName)}'),
              Text('${l.topupSettingsId}: ${realValue(request.promptPayMasked)}'),
              Text('${l.topupUploadBefore}: ${adminDate(context, request.expiresAt?.toIso8601String())}'),
              const SizedBox(height: 8),
              Text(l.topupPayerNotice, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('topup-send-slip'),
                onPressed: busy ? null : onSendSlip,
                icon: const Icon(Icons.upload_file),
                label: Text(l.topupSendSlip),
              ),
              const SizedBox(height: 4),
              Text(l.topupSlipHelp, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('topup-cancel'),
                onPressed: busy ? null : onCancel,
                icon: const Icon(Icons.close),
                label: Text(l.topupCancel),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(l.topupCheckingHelp, key: const ValueKey('topup-checking')),
            ],
          ],
        ),
      ),
    );
  }
}

class TopupHistoryTile extends StatelessWidget {
  const TopupHistoryTile({super.key, required this.request});

  final TopupRequest request;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      key: ValueKey('topup-row-${request.id}'),
      child: ListTile(
        leading: const Icon(Icons.qr_code_2),
        title: Text('${topupBaht(request.amount)} · ${topupStatusText(l, request.status)}'),
        subtitle: Text(
          [
            request.code,
            adminDate(context, request.createdAt?.toIso8601String()),
            if (request.rejectReason case final reason? when reason.isNotEmpty) '${l.topupRejectReason}: $reason',
          ].join('\n'),
        ),
      ),
    );
  }
}
