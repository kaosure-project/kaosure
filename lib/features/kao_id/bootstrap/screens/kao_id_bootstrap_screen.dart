import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/presentation/pages/complete_profile_page.dart';
import '../../auth/presentation/pages/landing_page.dart';
import '../../dashboard/presentation/screens/dashboard_screen.dart';
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
            _replaceWith(const LandingPage());
            break;

          case BootstrapStatus.completeProfile:
            _replaceWith(const CompleteProfilePage());
            break;

          case BootstrapStatus.dashboard:
            _replaceWith(const DashboardScreen());
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

  void _replaceWith(Widget page) {
    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }
}