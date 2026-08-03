import 'package:flutter/material.dart';

final class IdentityNoticeCard extends StatelessWidget {
  const IdentityNoticeCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.campaign_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(message),
      ),
    );
  }
}