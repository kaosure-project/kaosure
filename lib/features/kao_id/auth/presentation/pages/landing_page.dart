import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../router/kao_id_routes.dart';
import '../widgets/auth_logo.dart';

final class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthLogo(),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () {
                      Navigator.pushNamed(context, KaoIdRoutes.login);
                    },
                    child: Text(l10n.authLogin),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, KaoIdRoutes.register);
                    },
                    child: Text(l10n.authRegister),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
