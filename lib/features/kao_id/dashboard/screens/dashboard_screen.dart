import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/presentation/screens/account_screen.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_profile_card.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_security_section.dart';
import '../widgets/dashboard_services_section.dart';
import '../widgets/dashboard_settings_section.dart';

final class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    super.key,
  });

  @override
  ConsumerState<DashboardScreen> createState() =>
      _DashboardScreenState();
}

final class _DashboardScreenState
    extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dashboardControllerProvider.notifier)
          .loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      dashboardControllerProvider,
    );

    final controller = ref.read(
      dashboardControllerProvider.notifier,
    );

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.hasError) {
      return Scaffold(
        appBar: const DashboardAppBar(),
        body: Center(
          child: Text(state.errorMessage!),
        ),
      );
    }

    if (!state.hasProfile) {
      return Scaffold(
        appBar: const DashboardAppBar(),
        body: const Center(
          child: Text('ไม่พบข้อมูลบัญชี'),
        ),
      );
    }

    final profile = state.profile!;

    return Scaffold(
      appBar: const DashboardAppBar(),
      body: RefreshIndicator(
        onRefresh: controller.loadDashboard,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop =
                constraints.maxWidth >= 900;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1200,
                ),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                    vertical: 24,
                  ),
                  children: [
                    DashboardProfileCard(
                      profile: profile,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AccountScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    DashboardQuickActions(
                      profile: profile,
                    ),

                    const SizedBox(height: 24),

                    if (isDesktop)
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: const [
                          Expanded(
                            child:
                                DashboardSecuritySection(),
                          ),
                          SizedBox(width: 24),
                          Expanded(
                            child:
                                DashboardServicesSection(),
                          ),
                        ],
                      )
                    else ...[
                      const DashboardSecuritySection(),
                      const SizedBox(height: 24),
                      const DashboardServicesSection(),
                    ],

                    const SizedBox(height: 24),

                    const DashboardSettingsSection(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}