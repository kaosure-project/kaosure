import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../auth/application/kao_id_sso_handoff.dart';
import '../../router/kao_id_routes.dart';
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
  bool _dashboardHandoffStarted = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(bootstrapControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(bootstrapControllerProvider);
    ref.listen<BootstrapStatus>(
      bootstrapControllerProvider,
      (_, status) {
        switch (status) {
          case BootstrapStatus.landing:
            _replaceWith(KaoIdRoutes.kaoIdLanding);
            break;

          case BootstrapStatus.completeProfile:
            _replaceWith(KaoIdRoutes.completeProfile);
            break;

          case BootstrapStatus.dashboard:
            if (!_dashboardHandoffStarted) {
              _dashboardHandoffStarted = true;
              unawaited(_finishDashboardBootstrap());
            }
            break;

          case BootstrapStatus.loading:
          case BootstrapStatus.error:
            break;
        }
      },
    );

    if (status == BootstrapStatus.error) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.authBootstrapFailed, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref.read(bootstrapControllerProvider.notifier).bootstrap();
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<void> _finishDashboardBootstrap() async {
    if (await KaoIdSsoHandoff.tryReturnToService()) return;
    _replaceWith(KaoIdRoutes.dashboard);
  }

  void _replaceWith(String route) {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(route);
  }
}
