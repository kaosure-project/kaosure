import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/screens/landing_screen.dart';
import '../../account/presentation/screens/complete_profile_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';

import '../providers/bootstrap_provider.dart';
import '../states/bootstrap_state.dart';

final class KaoIdBootstrapScreen extends ConsumerStatefulWidget {
  const KaoIdBootstrapScreen({super.key});

  @override
  ConsumerState<KaoIdBootstrapScreen> createState() =>
      _KaoIdBootstrapScreenState();
}

final class _KaoIdBootstrapScreenState
    extends ConsumerState<KaoIdBootstrapScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bootstrapControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BootstrapStatus>(
      bootstrapControllerProvider,
      (_, status) {
        switch (status) {
          case BootstrapStatus.landing:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const LandingScreen(),
              ),
            );
            break;

          case BootstrapStatus.completeProfile:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const CompleteProfileScreen(),
              ),
            );
            break;

          case BootstrapStatus.dashboard:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DashboardScreen(),
              ),
            );
            break;

          case BootstrapStatus.loading:
          case BootstrapStatus.error:
            break;
        }
      },
    );

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}