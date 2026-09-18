import 'package:flutter/material.dart';

import '../../domain/entities/document_type.dart';
import '../../domain/entities/identity_document.dart';
import '../../domain/enums/verification_status.dart';
import 'document_page_body.dart';
import 'identity_verification_content.dart';
import 'identity_verification_state_builder.dart';

final class IdentityVerificationScreenContent
    extends StatelessWidget {
  const IdentityVerificationScreenContent({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.documents,
    required this.documentTypes,
    required this.status,
    required this.child,
    this.reason,
    this.errorMessage = 'เกิดข้อผิดพลาด',
    this.onRetry,
    this.onPrimaryAction,
    this.onSupport,
  });

  final bool isLoading;
  final bool hasError;

  final List<IdentityDocument> documents;
  final List<DocumentType> documentTypes;

  final VerificationStatus status;
  final String? reason;

  final Widget child;

  final String errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSupport;

  @override
  Widget build(BuildContext context) {
    return IdentityVerificationStateBuilder(
      isLoading: isLoading,
      hasError: hasError,
      isEmpty: documents.isEmpty,
      errorMessage: errorMessage,
      onRetry: onRetry,
      child: DocumentPageBody(
        children: [
          IdentityVerificationContent(
            documents: documents,
            documentTypes: documentTypes,
            status: status,
            reason: reason,
            onPrimaryAction: onPrimaryAction,
            onSupport: onSupport,
          ),
          child,
        ],
      ),
    );
  }
}