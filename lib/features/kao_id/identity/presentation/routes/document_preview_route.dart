import 'package:flutter/material.dart';

import '../../domain/entities/document_file.dart';
import '../screens/document_preview_screen.dart';

final class DocumentPreviewRoute {
  const DocumentPreviewRoute._();

  static Future<T?> push<T>(
    BuildContext context, {
    required DocumentFile file,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => DocumentPreviewScreen(
          file: file,
        ),
      ),
    );
  }

  static Future<T?> pushReplacement<T>(
    BuildContext context, {
    required DocumentFile file,
  }) {
    return Navigator.of(context).pushReplacement<T, void>(
      MaterialPageRoute<T>(
        builder: (_) => DocumentPreviewScreen(
          file: file,
        ),
      ),
    );
  }

  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context, {
    required DocumentFile file,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      MaterialPageRoute<T>(
        builder: (_) => DocumentPreviewScreen(
          file: file,
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