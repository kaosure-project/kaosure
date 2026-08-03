import 'package:flutter/material.dart';

import '../../domain/enums/document_status.dart';

final class DocumentStatusChip extends StatelessWidget {
  const DocumentStatusChip({
    super.key,
    required this.status,
  });

  final DocumentStatus status;

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

  IconData _icon(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.draft:
        return Icons.edit_document;

      case DocumentStatus.uploaded:
        return Icons.upload_file;

      case DocumentStatus.pendingReview:
        return Icons.hourglass_top;

      case DocumentStatus.approved:
        return Icons.verified;

      case DocumentStatus.rejected:
        return Icons.cancel;

      case DocumentStatus.expired:
        return Icons.event_busy;

      case DocumentStatus.suspended:
        return Icons.block;

      case DocumentStatus.archived:
        return Icons.archive;
    }
  }

  Color _backgroundColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.draft:
        return Colors.grey.shade200;

      case DocumentStatus.uploaded:
        return Colors.blue.shade100;

      case DocumentStatus.pendingReview:
        return Colors.orange.shade100;

      case DocumentStatus.approved:
        return Colors.green.shade100;

      case DocumentStatus.rejected:
        return Colors.red.shade100;

      case DocumentStatus.expired:
        return Colors.amber.shade100;

      case DocumentStatus.suspended:
        return Colors.deepOrange.shade100;

      case DocumentStatus.archived:
        return Colors.blueGrey.shade100;
    }
  }

  Color _foregroundColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.draft:
        return Colors.grey.shade800;

      case DocumentStatus.uploaded:
        return Colors.blue.shade800;

      case DocumentStatus.pendingReview:
        return Colors.orange.shade800;

      case DocumentStatus.approved:
        return Colors.green.shade800;

      case DocumentStatus.rejected:
        return Colors.red.shade800;

      case DocumentStatus.expired:
        return Colors.amber.shade900;

      case DocumentStatus.suspended:
        return Colors.deepOrange.shade800;

      case DocumentStatus.archived:
        return Colors.blueGrey.shade800;
    }
  }
}