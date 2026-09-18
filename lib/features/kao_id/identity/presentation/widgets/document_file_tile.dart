import 'package:flutter/material.dart';

import '../../domain/entities/document_file.dart';
import '../routes/document_preview_route.dart';

final class DocumentFileTile extends StatelessWidget {
  const DocumentFileTile({
    super.key,
    required this.file,
    this.onDelete,
  });

  final DocumentFile file;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          file.isImage
              ? Icons.image_outlined
              : Icons.picture_as_pdf_outlined,
        ),
        title: Text(file.fileName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(file.mimeType),
            Text('${file.fileSize} Bytes'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () {
                DocumentPreviewRoute.push(
                  context,
                  file: file,
                );
              },
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}