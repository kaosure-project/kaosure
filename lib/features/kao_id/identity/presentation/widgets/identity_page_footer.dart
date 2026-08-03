import 'package:flutter/material.dart';

final class IdentityPageFooter extends StatelessWidget {
  const IdentityPageFooter({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.only(
      top: 24,
      bottom: 16,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: DefaultTextStyle(
        style: Theme.of(context)
                .textTheme
                .bodySmall ??
            const TextStyle(),
        child: child,
      ),
    );
  }
}