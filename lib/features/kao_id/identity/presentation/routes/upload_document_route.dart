import 'package:flutter/material.dart';

import '../../domain/entities/document_type.dart';
import '../screens/upload_document_screen.dart';

final class UploadDocumentRoute {
  const UploadDocumentRoute._();

  static Future<T?> push<T>(
    BuildContext context, {
    required DocumentType documentType,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => UploadDocumentScreen(
          documentType: documentType,
        ),
      ),
    );
  }

  static Future<T?> pushReplacement<T>(
    BuildContext context, {
    required DocumentType documentType,
  }) {
    return Navigator.of(context).pushReplacement<T, void>(
      MaterialPageRoute<T>(
        builder: (_) => UploadDocumentScreen(
          documentType: documentType,
        ),
      ),
    );
  }

  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context, {
    required DocumentType documentType,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      MaterialPageRoute<T>(
        builder: (_) => UploadDocumentScreen(
          documentType: documentType,
        ),
      ),
      (_) => false,
    );
  }

  static void pop<T>(
    BuildContext context, [
    T? result,
  ]) {
    Navigator.of(context).pop<T>(result);
  }
}