import 'package:flutter/material.dart';

import '../../domain/entities/identity_document.dart';
import 'document_list_item.dart';

final class DocumentListView extends StatelessWidget {
  const DocumentListView({
    super.key,
    required this.documents,
    this.onTap,
  });

  final List<IdentityDocument> documents;
  final void Function(IdentityDocument document)? onTap;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(
        child: Text(
          'ยังไม่มีเอกสาร',
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];

        return DocumentListItem(
          document: document,
          onTap: onTap == null
              ? null
              : () => onTap!(document),
        );
      },
    );
  }
}