import 'package:flutter/material.dart';

import '../../domain/entities/document_file.dart';
import '../routes/document_preview_route.dart';

final class DocumentFilesCard extends StatelessWidget {
  const DocumentFilesCard({
    super.key,
    required this.files,
  });

  final List<DocumentFile> files;

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
              'ไฟล์เอกสาร',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 16),
            if (files.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 24,
                  ),
                  child: Text(
                    'ยังไม่มีไฟล์เอกสาร',
                  ),
                ),
              )
            else
              ...files.map(
                (file) => Card(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: ListTile(
                    leading: Icon(
                      file.isImage
                          ? Icons.image_outlined
                          : Icons.picture_as_pdf_outlined,
                    ),
                    title: Text(file.fileName),
                    subtitle: Text(
                      '${file.fileSize} Bytes',
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        DocumentPreviewRoute.push(
                          context,
                          file: file,
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}