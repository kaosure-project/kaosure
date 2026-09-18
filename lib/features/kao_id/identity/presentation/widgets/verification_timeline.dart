import 'package:flutter/material.dart';

import '../../domain/entities/verification_log.dart';
import '../../domain/enums/verification_status.dart';

final class VerificationTimeline extends StatelessWidget {
  const VerificationTimeline({
    super.key,
    required this.logs,
  });

  final List<VerificationLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Text(
          'ยังไม่มีประวัติการตรวจสอบ',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = logs[index];

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Icon(
                    _icon(log.status),
                    size: 18,
                  ),
                ),
                if (index != logs.length - 1)
                  Container(
                    width: 2,
                    height: 56,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.status.label,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'การดำเนินการ: ${log.action}',
                      ),
                      if (log.comment != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 4,
                          ),
                          child: Text(
                            'หมายเหตุ: ${log.comment}',
                          ),
                        ),
                      if (log.reviewedBy != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 4,
                          ),
                          child: Text(
                            'ผู้ตรวจ: ${log.reviewedBy}',
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${log.createdAt.day.toString().padLeft(2, '0')}/'
                        '${log.createdAt.month.toString().padLeft(2, '0')}/'
                        '${log.createdAt.year}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _icon(
    VerificationStatus status,
  ) {
    switch (status) {
      case VerificationStatus.notSubmitted:
        return Icons.edit_document;

      case VerificationStatus.submitted:
        return Icons.upload;

      case VerificationStatus.underReview:
        return Icons.search;

      case VerificationStatus.additionalInformationRequired:
        return Icons.info;

      case VerificationStatus.approved:
        return Icons.verified;

      case VerificationStatus.rejected:
        return Icons.cancel;

      case VerificationStatus.cancelled:
        return Icons.block;
    }
  }
}