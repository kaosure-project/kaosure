import 'package:flutter/material.dart';

import '../../domain/entities/verification.dart';
import '../../domain/enums/verification_status.dart';

final class VerificationHistoryScreen extends StatelessWidget {
  const VerificationHistoryScreen({
    super.key,
    required this.verification,
  });

  final Verification verification;

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการตรวจสอบ'),
      ),
      body: verification.logs.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีประวัติการตรวจสอบ',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: verification.logs.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = verification.logs[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(log.status.label),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('การดำเนินการ: ${log.action}'),
                        if (log.comment != null)
                          Text('หมายเหตุ: ${log.comment}'),
                        if (log.reviewedBy != null)
                          Text('ผู้ตรวจ: ${log.reviewedBy}'),
                      ],
                    ),
                    trailing: Text(
                      _formatDate(log.createdAt),
                    ),
                  ),
                );
              },
            ),
    );
  }
}