import 'package:flutter/material.dart';

import 'about_tile.dart';
import 'general_settings_tile.dart';
import 'notifications_tile.dart';
import 'privacy_tile.dart';

final class DashboardSettingsSection extends StatelessWidget {
  const DashboardSettingsSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: Text(
              'การตั้งค่า',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
          ),

          const GeneralSettingsTile(),

          const NotificationsTile(),

          const PrivacyTile(),

          const AboutTile(),
        ],
      ),
    );
  }
}