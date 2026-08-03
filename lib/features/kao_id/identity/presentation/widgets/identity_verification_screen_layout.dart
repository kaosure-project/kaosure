import 'package:flutter/material.dart';

import 'document_page_body.dart';
import 'document_page_scaffold.dart';

final class IdentityVerificationScreenLayout
    extends StatelessWidget {
  const IdentityVerificationScreenLayout({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final List<Widget> children;

  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return DocumentPageScaffold(
      title: title,
      actions: actions,
      floatingActionButton: floatingActionButton,
      body: DocumentPageBody(
        children: children,
      ),
    );
  }
}