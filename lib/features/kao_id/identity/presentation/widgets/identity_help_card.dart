import 'package:flutter/material.dart';

final class IdentityHelpCard extends StatelessWidget {
  const IdentityHelpCard({
    super.key,
    required this.title,
    required this.message,
    required this.buttonText,
    this.icon = Icons.help_outline,
    this.onPressed,
  });

  final String title;
  final String message;
  final String buttonText;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.arrow_forward),
                label: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}