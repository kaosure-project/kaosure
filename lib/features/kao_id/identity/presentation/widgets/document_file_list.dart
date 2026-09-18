import 'package:flutter/material.dart';

import '../../domain/entities/document_file.dart';
import 'document_file_tile.dart';

final class DocumentFileList extends StatelessWidget {
  const DocumentFileList({
    super.key,
    required this.files,
    this.onDelete,
  });

  final List<DocumentFile> files;
  final void Function(DocumentFile file)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'ยังไม่มีไฟล์เอกสาร',
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];

        return DocumentFileTile(
          file: file,
          onDelete: onDelete == null
              ? null
              : () => onDelete!(file),
        );
      },
    );
  }
}