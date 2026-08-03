import 'package:flutter/material.dart';

import '../../domain/entities/document_type.dart';
import '../../domain/entities/identity_document.dart';
import '../../domain/enums/verification_status.dart';
import 'document_page_scaffold.dart';
import 'identity_verification_screen_content.dart';

final class IdentityVerificationScreenBody
    extends StatelessWidget {
  const IdentityVerificationScreenBody({
    super.key,
    required this.title,
    required this.isLoading,
    required this.hasError,
    required this.documents,
    required this.documentTypes,
    required this.status,
    required this.child,
    this.reason,
    this.errorMessage = 'เกิดข้อผิดพลาด',
    this.actions,
    this.floatingActionButton,
    this.onRetry,
    this.onPrimaryAction,
    this.onSupport,
  });

  final String title;

  final bool isLoading;
  final bool hasError;

  final List<IdentityDocument> documents;
  final List<DocumentType> documentTypes;

  final VerificationStatus status;
  final String? reason;

  final Widget child;

  final String errorMessage;

  final List<Widget>? actions;
  final Widget? floatingActionButton;

  final VoidCallback? onRetry;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSupport;

  @override
  Widget build(BuildContext context) {
    return DocumentPageScaffold(
      title: title,
      actions: actions,
      floatingActionButton: floatingActionButton,
      body: IdentityVerificationScreenContent(
        isLoading: isLoading,
        hasError: hasError,
        documents: documents,
        documentTypes: documentTypes,
        status: status,
        reason: reason,
        errorMessage: errorMessage,
        onRetry: onRetry,
        onPrimaryAction: onPrimaryAction,
        onSupport: onSupport,
        child: child,
      ),
    );
  }
}