import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_bar/app_app_bar.dart';
import '../widgets/dashboard_grid.dart';
import '../widgets/profile_header.dart';

class ProfileDashboardPage extends StatelessWidget {
  static const routeName = '/kao-id/profile';

  const ProfileDashboardPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppAppBar(
        title: 'Kao ID',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ProfileHeader(),
              DashboardGrid(),
            ],
          ),
        ),
      ),
    );
  }
}
