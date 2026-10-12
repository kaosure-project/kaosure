import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

class IdentityVerificationScreen extends StatelessWidget {
  const IdentityVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).identityVerification)),
      body: Center(child: Text(AppLocalizations.of(context).serviceUnavailable)),
    );
  }
}
