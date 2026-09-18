import 'package:flutter/material.dart';

final class IdentityActionBar extends StatelessWidget {
  const IdentityActionBar({
    super.key,
    this.primaryLabel,
    this.secondaryLabel,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.primaryIcon,
    this.secondaryIcon,
  });

  final String? primaryLabel;
  final String? secondaryLabel;

  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;

  final IconData? primaryIcon;
  final IconData? secondaryIcon;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (secondaryLabel != null) {
      children.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSecondaryPressed,
            icon: Icon(
              secondaryIcon ?? Icons.arrow_back,
            ),
            label: Text(secondaryLabel!),
          ),
        ),
      );
    }

    if (secondaryLabel != null && primaryLabel != null) {
      children.add(const SizedBox(width: 12));
    }

    if (primaryLabel != null) {
      children.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: onPrimaryPressed,
            icon: Icon(
              primaryIcon ?? Icons.check,
            ),
            label: Text(primaryLabel!),
          ),
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: children,
    );
  }
}