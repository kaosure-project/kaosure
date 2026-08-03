import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/device_controller_provider.dart';
import '../widgets/device_card.dart';

class DeviceListPage extends ConsumerWidget {
  const DeviceListPage({
    super.key,
  });

  static const routeName = '/kao-id/devices';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
      ),
      body: Builder(
        builder: (_) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.devices.isEmpty) {
            return const Center(
              child: Text(
                'No registered devices',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.devices.length,
            itemBuilder: (context, index) {
              final device = state.devices[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DeviceCard(
                  device: device,
                ),
              );
            },
          );
        },
      ),
    );
  }
}