import 'package:flutter/material.dart';

import '../../domain/entities/identity_document.dart';

final class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.document,
    this.onTap,
  });

  final IdentityDocument document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(
            Icons.badge_outlined,
          ),
        ),
        title: Text(
          document.documentType.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          document.status.name,
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}