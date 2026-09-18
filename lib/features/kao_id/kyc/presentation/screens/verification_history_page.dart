import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/kyc_provider.dart';
import '../../domain/entities/verification_history.dart';

final class VerificationHistoryPage
    extends ConsumerWidget {
  const VerificationHistoryPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final state = ref.watch(
      kycControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ประวัติการยืนยันตัวตน',
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(
                kycControllerProvider.notifier,
              )
              .load(),
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.all(20),
            children: [
              const _HistoryHeader(),
              const SizedBox(height: 20),
              if (state.isLoading &&
                  state.verificationHistory.isEmpty)
                const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.all(32),
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              else if (state
                  .verificationHistory.isEmpty)
                const _EmptyHistory()
              else
                ...state.verificationHistory
                    .map(
                  (item) => Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child:
                        _HistoryCard(
                      item: item,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _HistoryHeader
    extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.history,
              size: 38,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audit Trail ของ KYC',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'แสดงการส่งตรวจ การตรวจสอบ การอนุมัติ และการปฏิเสธตามข้อมูลจริงจาก verification_logs',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _HistoryCard
    extends StatelessWidget {
  const _HistoryCard({
    required this.item,
  });

  final VerificationHistory item;

  @override
  Widget build(BuildContext context) {
    final status =
        item.newStatus ?? item.oldStatus ?? '-';

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(
            Icons.verified_user_outlined,
          ),
        ),
        title: Text(
          _actionLabel(item.action),
        ),
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('สถานะ: $status'),
            if (item.notes != null &&
                item.notes!.isNotEmpty)
              Text(item.notes!),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(
                item.createdAt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'approve':
        return 'อนุมัติการยืนยันตัวตน';
      case 'reject':
        return 'ปฏิเสธการยืนยันตัวตน';
      case 'review':
        return 'เริ่มตรวจสอบ';
      case 'submit':
        return 'ส่งคำขอตรวจสอบ';
      case 'cancel':
        return 'ยกเลิกคำขอ';
      default:
        return action;
    }
  }

  String _formatDateTime(
    DateTime value,
  ) {
    final local = value.toLocal();

    return [
      local.day.toString().padLeft(2, '0'),
      local.month.toString().padLeft(2, '0'),
      local.year.toString(),
    ].join('/') +
        ' ' +
        local.hour.toString().padLeft(2, '0') +
        ':' +
        local.minute.toString().padLeft(2, '0');
  }
}

final class _EmptyHistory
    extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding:
            EdgeInsets.symmetric(
          vertical: 36,
          horizontal: 20,
        ),
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 48,
            ),
            SizedBox(height: 12),
            Text('ยังไม่มีประวัติ KYC'),
          ],
        ),
      ),
    );
  }
}
