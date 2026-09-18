import 'package:flutter/material.dart';

import '../../domain/enums/verification_status.dart';

final class VerificationStatusChip extends StatelessWidget {
  const VerificationStatusChip({
    super.key,
    required this.status,
  });

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        _icon(status),
        size: 18,
        color: _foregroundColor(status),
      ),
      label: Text(
        status.label,
        style: TextStyle(
          color: _foregroundColor(status),
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: _backgroundColor(status),
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

  Color _backgroundColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.notSubmitted:
        return Colors.grey.shade200;

      case VerificationStatus.submitted:
        return Colors.blue.shade100;

      case VerificationStatus.underReview:
        return Colors.orange.shade100;

      case VerificationStatus.additionalInformationRequired:
        return Colors.amber.shade100;

      case VerificationStatus.approved:
        return Colors.green.shade100;

      case VerificationStatus.rejected:
        return Colors.red.shade100;

      case VerificationStatus.cancelled:
        return Colors.blueGrey.shade100;
    }
  }

  Color _foregroundColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.notSubmitted:
        return Colors.grey.shade800;

      case VerificationStatus.submitted:
        return Colors.blue.shade800;

      case VerificationStatus.underReview:
        return Colors.orange.shade800;

      case VerificationStatus.additionalInformationRequired:
        return Colors.amber.shade900;

      case VerificationStatus.approved:
        return Colors.green.shade800;

      case VerificationStatus.rejected:
        return Colors.red.shade800;

      case VerificationStatus.cancelled:
        return Colors.blueGrey.shade800;
    }
  }
}