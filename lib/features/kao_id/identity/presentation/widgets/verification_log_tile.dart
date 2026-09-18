import 'package:flutter/material.dart';

import '../../domain/entities/verification_log.dart';
import '../../domain/enums/verification_status.dart';

final class VerificationLogTile extends StatelessWidget {
  const VerificationLogTile({
    super.key,
    required this.log,
  });

  final VerificationLog log;

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            _icon(log.status),
          ),
        ),
        title: Text(log.status.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log.action),
            if (log.comment != null)
              Text(
                log.comment!,
              ),
            if (log.reviewedBy != null)
              Text(
                'ผู้ตรวจ: ${log.reviewedBy}',
              ),
          ],
        ),
        trailing: Text(
          _formatDate(log.createdAt),
        ),
      ),
    );
  }

  IconData _icon(VerificationStatus status) {
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