import 'package:flutter/material.dart';

import '../../domain/entities/identity_document.dart';
import 'document_summary_card.dart';

final class IdentityOverviewCard extends StatelessWidget {
  const IdentityOverviewCard({
    super.key,
    required this.documents,
  });

  final List<IdentityDocument> documents;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DocumentSummaryCard(
          documents: documents,
        ),
      ],
    );
  }
}