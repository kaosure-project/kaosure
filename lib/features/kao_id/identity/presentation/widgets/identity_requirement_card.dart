import 'package:flutter/material.dart';

import '../../domain/entities/document_type.dart';
import '../../domain/entities/identity_document.dart';

final class IdentityRequirementCard extends StatelessWidget {
  const IdentityRequirementCard({
    super.key,
    required this.documentTypes,
    required this.documents,
  });

  final List<DocumentType> documentTypes;
  final List<IdentityDocument> documents;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เอกสารที่ต้องใช้',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...documentTypes.map(
              (type) {
                final uploaded = documents.any(
                  (document) =>
                      document.documentType == type.type,
                );

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    uploaded
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: uploaded
                        ? Colors.green
                        : Colors.grey,
                  ),
                  title: Text(type.name),
                  subtitle: Text(type.description),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}