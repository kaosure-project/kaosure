import 'package:flutter/material.dart';

import '../../domain/entities/identity_document.dart';
import 'document_status_chip.dart';

final class DocumentListItem extends StatelessWidget {
  const DocumentListItem({
    super.key,
    required this.document,
    this.onTap,
  });

  final IdentityDocument document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.description_outlined),
        title: Text(document.documentType.name),
        subtitle: Text(document.documentNumber.value),
        trailing: DocumentStatusChip(
          status: document.status,
        ),
      ),
    );
  }
}