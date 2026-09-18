import 'package:flutter/material.dart';

import '../../domain/entities/identity_document.dart';
import '../screens/document_detail_screen.dart';

final class DocumentDetailRoute {
  const DocumentDetailRoute._();

  static Future<T?> push<T>(
    BuildContext context, {
    required IdentityDocument document,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => DocumentDetailScreen(
          document: document,
        ),
      ),
    );
  }

  static Future<T?> pushReplacement<T, TO>(
    BuildContext context, {
    required IdentityDocument document,
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      MaterialPageRoute<T>(
        builder: (_) => DocumentDetailScreen(
          document: document,
        ),
        
      ),
    );
  }

  static void pop<T>(
    BuildContext context, [
    T? result,
  ]) {
    Navigator.of(context).pop<T>(result);
  }

  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context, {
    required IdentityDocument document,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      MaterialPageRoute<T>(
        builder: (_) => DocumentDetailScreen(
          document: document,
        ),
      ),
      (_) => false,
    );
  }
}