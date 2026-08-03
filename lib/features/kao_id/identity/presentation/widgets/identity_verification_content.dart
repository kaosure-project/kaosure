import 'package:flutter/material.dart';

import '../../domain/entities/document_type.dart';
import '../../domain/entities/identity_document.dart';
import '../../domain/enums/verification_status.dart';
import 'identity_guideline_card.dart';
import 'identity_overview_card.dart';
import 'identity_requirement_card.dart';
import 'identity_support_card.dart';
import 'identity_verification_result_card.dart';

final class IdentityVerificationContent
    extends StatelessWidget {
  const IdentityVerificationContent({
    super.key,
    required this.documents,
    required this.documentTypes,
    required this.status,
    this.reason,
    this.onPrimaryAction,
    this.onSupport,
  });

  final List<IdentityDocument> documents;
  final List<DocumentType> documentTypes;
  final VerificationStatus status;
  final String? reason;

  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSupport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        IdentityOverviewCard(
          documents: documents,
        ),
        const SizedBox(height: 16),
        IdentityVerificationResultCard(
          status: status,
          reason: reason,
          onPrimaryAction: onPrimaryAction,
        ),
        const SizedBox(height: 16),
        IdentityRequirementCard(
          documentTypes: documentTypes,
          documents: documents,
        ),
        const SizedBox(height: 16),
        const IdentityGuidelineCard(),
        const SizedBox(height: 16),
        IdentitySupportCard(
          onPressed: onSupport,
        ),
      ],
    );
  }
}