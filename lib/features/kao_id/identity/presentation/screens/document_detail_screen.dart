import 'package:flutter/material.dart';
import '../../domain/enums/document_status.dart';
import '../../domain/enums/document_type_enum.dart';
import '../../domain/entities/document_file.dart';
import '../../domain/entities/identity_document.dart';

final class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({
    super.key,
    required this.document,
  });

  final IdentityDocument document;

  String _formatDate(DateTime? value) {
  if (value == null) return '-';

  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดเอกสาร'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.documentType.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                     const Divider(height: 32),
                  _InfoTile(
                    title: 'สถานะเอกสาร',
                    value: document.status.label,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoTile(
                    title: 'หมายเลขเอกสาร',
                    value: document.documentNumber.value,
                  ),
                  const Divider(),
                  _InfoTile(
                    title: 'วันที่ออกเอกสาร',
                    value: _formatDate(
                      document.issuedDate?.value,
                    ),
                  ),
                  const Divider(),
                  _InfoTile(
                    title: 'วันหมดอายุ',
                    value: _formatDate(
                      document.expiryDate?.value,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
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
                  if (document.files.isEmpty)
                    const Text('ไม่มีไฟล์เอกสาร')
                  else
                    ...document.files.map(
                      (file) => _DocumentFileTile(
                        file: file,
                      ),
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

final class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
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

final class _DocumentFileTile
extends StatelessWidget {
  const _DocumentFileTile({
    required this.file,
  });

  final DocumentFile file;

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
            Text(
  '${file.uploadedAt.day.toString().padLeft(2, '0')}/'
  '${file.uploadedAt.month.toString().padLeft(2, '0')}/'
  '${file.uploadedAt.year} '
  '${file.uploadedAt.hour.toString().padLeft(2, '0')}:'
  '${file.uploadedAt.minute.toString().padLeft(2, '0')}',
),
          ],
        ),
      ),
    );
  }
}