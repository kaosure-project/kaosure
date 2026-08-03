import 'package:flutter/material.dart';

import '../../domain/entities/verification.dart';
import '../../domain/enums/verification_status.dart';
import '../routes/verification_history_route.dart';

final class VerificationInformationCard extends StatelessWidget {
  const VerificationInformationCard({
    super.key,
    required this.verification,
  });

  final Verification verification;

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'ข้อมูลการตรวจสอบ',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 16),
            _Row(
              title: 'สถานะ',
              value: verification.status.label,
            ),
            const SizedBox(height: 12),
            _Row(
              title: 'วันที่ส่งตรวจ',
              value: _formatDate(
                verification.submittedAt,
              ),
            ),
            const SizedBox(height: 12),
            _Row(
              title: 'วันที่ตรวจเสร็จ',
              value: _formatDate(
                verification.reviewedAt,
              ),
            ),
            const SizedBox(height: 12),
            _Row(
              title: 'ผู้ตรวจ',
              value:
                  verification.reviewedBy ?? '-',
            ),
            if (verification.rejectionReason !=
                null) ...[
              const SizedBox(height: 12),
              _Row(
                title: 'เหตุผล',
                value:
                    verification.rejectionReason!,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  VerificationHistoryRoute.push(
                    context,
                    verification:
                        verification,
                  );
                },
                icon: const Icon(
                  Icons.history,
                ),
                label: const Text(
                  'ดูประวัติการตรวจสอบ',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(value),
        ),
      ],
    );
  }
}