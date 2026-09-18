import 'package:flutter/material.dart';

final class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.permissions,
  });

  final List<PermissionItem> permissions;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สิทธิ์การใช้งาน',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 16),

            ...permissions.map(
              (permission) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  permission.enabled
                      ? Icons.check_circle
                      : Icons.cancel_outlined,
                  color: permission.enabled
                      ? Colors.green
                      : Colors.grey,
                ),
                title: Text(permission.title),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class PermissionItem {
  const PermissionItem({
    required this.title,
    required this.enabled,
  });

  final String title;

  final bool enabled;
}