import 'package:flutter/material.dart';

import '../../domain/entities/document_file.dart';

final class DocumentPreviewScreen extends StatelessWidget {
  const DocumentPreviewScreen({
    super.key,
    required this.file,
  });

  final DocumentFile file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.fileName),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: file.isImage
                  ? const Icon(
                      Icons.image,
                      size: 120,
                    )
                  : const Icon(
                      Icons.picture_as_pdf,
                      size: 120,
                    ),
            ),
          ),
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    title: 'ชื่อไฟล์',
                    value: file.fileName,
                  ),
                  const Divider(),
                  _InfoRow(
                    title: 'ประเภท',
                    value: file.mimeType,
                  ),
                  const Divider(),
                  _InfoRow(
                    title: 'ขนาด',
                    value: '${file.fileSize} Bytes',
                  ),
                  const Divider(),
                  _InfoRow(
                    title: 'อัปโหลด',
                    value:
                        '${file.uploadedAt.day.toString().padLeft(2, '0')}/'
                        '${file.uploadedAt.month.toString().padLeft(2, '0')}/'
                        '${file.uploadedAt.year}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(value),
        ),
      ],
    );
  }
}