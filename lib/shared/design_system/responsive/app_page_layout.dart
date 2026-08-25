import 'package:flutter/material.dart';

import 'app_layout.dart';

/// Standard page layout used across Kao Ecosystem.
///
/// Mobile  : Full width
/// Tablet  : Centered
/// Desktop : Centered with max width
final class AppPageLayout extends StatelessWidget {
  const AppPageLayout({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.maxContentWidth,
    this.padding = const EdgeInsets.all(24),
    this.alignment = Alignment.topCenter,
  });

  final Widget child;

  /// Maximum width of the content.
  final double maxWidth;

  /// Page padding.
  final EdgeInsetsGeometry padding;

  /// Content alignment.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: alignment,
        child: SingleChildScrollView(
          child: Padding(
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}