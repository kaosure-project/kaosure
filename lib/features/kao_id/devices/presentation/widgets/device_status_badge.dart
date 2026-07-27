import 'package:flutter/material.dart';

class DeviceStatusBadge extends StatelessWidget {
  const DeviceStatusBadge({
    super.key,
    required this.isCurrent,
  });

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        isCurrent ? Icons.check_circle : Icons.devices,
        size: 18,
      ),
      label: Text(
        isCurrent ? 'Current Device' : 'Registered Device',
      ),
    );
  }
}