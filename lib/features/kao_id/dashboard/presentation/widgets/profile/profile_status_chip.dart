import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../account/domain/entities/profile.dart';

final class ProfileStatusChip extends StatelessWidget {
  const ProfileStatusChip({
    super.key,
    required this.profile,
  });

  final Profile profile;

  bool get _isVerified =>
      profile.accountLevel == 'verified' ||
      profile.accountLevel == 'business' ||
      profile.accountLevel == 'organization';

  String _verificationText(BuildContext context) {
    switch (profile.accountLevel) {
      case 'verified':
        return AppLocalizations.of(context).accountVerified;

      case 'business':
        return AppLocalizations.of(context).businessAccount;

      case 'organization':
        return AppLocalizations.of(context).organizationAccount;

      case 'registered':
        return AppLocalizations.of(context).accountRegistered;

      default:
        return AppLocalizations.of(context).accountStandard;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        _isVerified
            ? Icons.verified
            : Icons.info_outline,
        size: 18,
        color: _isVerified
            ? Colors.green
            : Colors.orange,
      ),
      label: Text(
        _verificationText(context),
      ),
    );
  }
}
