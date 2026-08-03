import 'package:flutter/material.dart';

final class IdentitySupportCard extends StatelessWidget {
  const IdentitySupportCard({
    super.key,
    this.title = 'ต้องการความช่วยเหลือ?',
    this.message =
        'หากพบปัญหาในการยืนยันตัวตน สามารถติดต่อฝ่ายสนับสนุนเพื่อขอความช่วยเหลือได้',
    this.buttonText = 'ติดต่อฝ่ายสนับสนุน',
    this.icon = Icons.support_agent,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.chat_outlined),
                label: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}