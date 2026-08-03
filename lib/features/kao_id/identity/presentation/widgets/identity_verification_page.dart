import 'package:flutter/material.dart';

import '../../domain/entities/document_type.dart';
import '../../domain/entities/identity_document.dart';
import '../../domain/enums/verification_status.dart';
import 'identity_verification_screen_body.dart';

final class IdentityVerificationPage extends StatelessWidget {
  const IdentityVerificationPage({
    super.key,
    required this.title,
    required this.isLoading,
    required this.hasError,
    required this.documents,
    required this.documentTypes,
    required this.status,
    this.reason,
    this.errorMessage = 'เกิดข้อผิดพลาด',
    this.actions,
    this.floatingActionButton,
    this.onRetry,
    this.onPrimaryAction,
    this.onSupport,
    this.footer = const SizedBox.shrink(),
  });

  final String title;

  final bool isLoading;
  final bool hasError;

  final List<IdentityDocument> documents;
  final List<DocumentType> documentTypes;

  final VerificationStatus status;
  final String? reason;

  final String errorMessage;

  final List<Widget>? actions;
  final Widget? floatingActionButton;

  final VoidCallback? onRetry;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSupport;

  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return IdentityVerificationScreenBody(
      title: title,
      isLoading: isLoading,
      hasError: hasError,
      documents: documents,
      documentTypes: documentTypes,
      status: status,
      reason: reason,
      errorMessage: errorMessage,
      actions: actions,
      floatingActionButton: floatingActionButton,
      onRetry: onRetry,
      onPrimaryAction: onPrimaryAction,
      onSupport: onSupport,
      child: footer,
    );
  }
}