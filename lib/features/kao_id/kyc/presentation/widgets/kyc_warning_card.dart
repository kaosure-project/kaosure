import 'package:flutter/material.dart';

final class KycWarningCard extends StatelessWidget {
  const KycWarningCard({
    super.key,
    required this.visible,
    required this.title,
    required this.message,
    required this.onTap,
  });

  final bool visible;
  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.orange.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(message),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}