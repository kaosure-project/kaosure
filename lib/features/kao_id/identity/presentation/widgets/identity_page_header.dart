import 'package:flutter/material.dart';

final class IdentityPageHeader extends StatelessWidget {
  const IdentityPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.spacing = 16,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if (trailing != null) ...[
          SizedBox(height: spacing),
          trailing!,
        ],
      ],
    );
  }
}