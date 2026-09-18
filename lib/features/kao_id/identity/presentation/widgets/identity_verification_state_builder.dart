import 'package:flutter/material.dart';

import 'empty_document_state.dart';
import 'error_document_state.dart';
import 'loading_document_state.dart';

final class IdentityVerificationStateBuilder
    extends StatelessWidget {
  const IdentityVerificationStateBuilder({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.isEmpty,
    required this.child,
    this.errorMessage = 'เกิดข้อผิดพลาด',
    this.onRetry,
    this.emptyTitle = 'ยังไม่มีข้อมูล',
    this.emptyMessage = 'ยังไม่มีข้อมูลที่จะแสดง',
    this.emptyButtonText,
    this.onEmptyPressed,
  });

  final bool isLoading;
  final bool hasError;
  final bool isEmpty;

  final Widget child;

  final String errorMessage;
  final VoidCallback? onRetry;

  final String emptyTitle;
  final String emptyMessage;
  final String? emptyButtonText;
  final VoidCallback? onEmptyPressed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingDocumentState();
    }

    if (hasError) {
      return ErrorDocumentState(
        message: errorMessage,
        onRetry: onRetry,
      );
    }

    if (isEmpty) {
      return EmptyDocumentState(
        title: emptyTitle,
        message: emptyMessage,
        buttonText: emptyButtonText,
        onPressed: onEmptyPressed,
      );
    }

    return child;
  }
}