import 'package:flutter/material.dart';

import '../../domain/entities/device.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
  });

  final Device device;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.deviceName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Platform: ${device.platform}'),
            Text('OS Version: ${device.osVersion}'),
            Text('App Version: ${device.appVersion}'),
            const SizedBox(height: 12),
            Chip(
              label: Text(
                device.isTrusted
                    ? 'Trusted Device'
                    : 'Untrusted Device',
              ),
            ),
          ],
        ),
      ),
    );
  }
}