import 'package:flutter/material.dart';

import '../common/security_notice.dart';

/// Single centered column in the style of account sign-up flows:
/// brand header, one outlined card, and a security note underneath.
class RegistrationLayout extends StatelessWidget {
  const RegistrationLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  static const maxContentWidth = 560.0;

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 480;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/images/kaosure_logo.png', height: 40,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => const SizedBox(height: 40)),
                const SizedBox(height: 16),
                Text(title, textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(subtitle, textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                Material(
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 20 : 32),
                    child: child,
                  ),
                ),
                const SizedBox(height: 20),
                const SecurityNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
