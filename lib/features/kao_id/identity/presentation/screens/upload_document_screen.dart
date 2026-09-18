import 'package:flutter/material.dart';

import '../../domain/entities/document_file.dart';
import '../../domain/entities/document_type.dart';

final class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({
    super.key,
    required this.documentType,
  });

  final DocumentType documentType;

  @override
  State<UploadDocumentScreen> createState() =>
      _UploadDocumentScreenState();
}

final class _UploadDocumentScreenState
    extends State<UploadDocumentScreen> {
  final List<DocumentFile> _files = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('อัปโหลดเอกสาร'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.documentType.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(widget.documentType.description),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              // TODO:
              // Pick image from gallery
            },
            icon: const Icon(Icons.photo),
            label: const Text('เลือกรูปจากแกลเลอรี'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              // TODO:
              // Open camera
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('ถ่ายรูป'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // TODO:
              // Pick PDF
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('เลือกไฟล์ PDF'),
          ),
          const SizedBox(height: 24),
          Text(
            'ไฟล์ที่เลือก',
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(height: 12),
          if (_files.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'ยังไม่มีไฟล์',
                  ),
                ),
              ),
            )
          else
            ..._files.map(
              (file) => Card(
                child: ListTile(
                  leading: Icon(
                    file.isImage
                        ? Icons.image
                        : Icons.picture_as_pdf,
                  ),
                  title: Text(file.fileName),
                  subtitle: Text(file.mimeType),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _files.remove(file);
                      });
                    },
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // TODO:
              // Save document
            },
            icon: const Icon(Icons.save),
            label: const Text('บันทึกเอกสาร'),
          ),
        ],
      ),
    );
  }
}