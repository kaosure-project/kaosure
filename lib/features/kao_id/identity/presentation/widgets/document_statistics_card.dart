import 'package:flutter/material.dart';

import '../../domain/entities/identity_document.dart';
import '../../domain/enums/document_status.dart';

final class DocumentStatisticsCard extends StatelessWidget {
  const DocumentStatisticsCard({
    super.key,
    required this.documents,
  });

  final List<IdentityDocument> documents;

  @override
  Widget build(BuildContext context) {
    final statistics = {
      DocumentStatus.draft: 0,
      DocumentStatus.uploaded: 0,
      DocumentStatus.pendingReview: 0,
      DocumentStatus.approved: 0,
      DocumentStatus.rejected: 0,
      DocumentStatus.expired: 0,
      DocumentStatus.suspended: 0,
      DocumentStatus.archived: 0,
    };

    for (final document in documents) {
      statistics[document.status] =
          (statistics[document.status] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'สถิติเอกสาร',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 16),
            ...statistics.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key.label,
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}