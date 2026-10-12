import 'package:kaosure/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/verification.dart';

import 'permission_card.dart';

final class PermissionSection extends StatelessWidget {
  const PermissionSection({
    super.key,
    required this.verification,
  });

  final Verification? verification;

  @override
  Widget build(BuildContext context) {
    final emailVerified =
        verification?.emailVerified ?? false;

    final phoneVerified =
        verification?.phoneVerified ?? false;

    final identityVerified =
        verification?.identityCardStatus == 'verified';

    final bankVerified =
        verification?.bankStatus == 'verified';

    return PermissionCard(
      permissions: [
         PermissionItem(
          title: AppLocalizations.of(context).kycSignIn,
          enabled: true,
        ),
         PermissionItem(
          title: AppLocalizations.of(context).kycEditProfile,
          enabled: true,
        ),
        PermissionItem(
          title: AppLocalizations.of(context).kycVerifyEmail,
          enabled: emailVerified,
        ),
        PermissionItem(
          title: AppLocalizations.of(context).kycVerifyPhoneNumber,
          enabled: phoneVerified,
        ),
         PermissionItem(
          title: AppLocalizations.of(context).kycBuyItems,
          enabled: true,
        ),
        PermissionItem(
          title: AppLocalizations.of(context).kycSellItems,
          enabled: identityVerified,
        ),
        PermissionItem(
          title: AppLocalizations.of(context).kycWithdrawFunds,
          enabled: bankVerified,
        ),
        PermissionItem(
          title: 'KaoPay',
          enabled: identityVerified && bankVerified,
        ),
        PermissionItem(
          title: 'Marketplace',
          enabled: emailVerified && phoneVerified,
        ),
        PermissionItem(
          title: 'Auction',
          enabled: identityVerified && bankVerified,
        ),
      ],
    );
  }
}