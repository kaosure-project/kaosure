import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../domain/entities/sso_app.dart';
import '../../domain/failures/sso_failure.dart';

extension SsoTexts on AppLocalizations {
  String ssoFailureMessage(SsoFailureCode code) => switch (code) {
        SsoFailureCode.session => contactSessionChanged,
        SsoFailureCode.requestNotFound => ssoErrorRequestNotFound,
        SsoFailureCode.appNotAllowed => ssoAppBlocked,
        SsoFailureCode.invalidRedirect => ssoErrorInvalidRedirect,
        SsoFailureCode.ownerRequired => ssoErrorOwner,
        SsoFailureCode.mfaRequired => mfaSessionRequired,
        SsoFailureCode.invalidClient => ssoErrorInvalidClient,
        SsoFailureCode.oauthClientNotFound => ssoErrorOauthClientNotFound,
        SsoFailureCode.clientAlreadyRegistered => ssoErrorClientTaken,
        SsoFailureCode.unknown => ssoErrorUnknown,
      };

  /// Standard OIDC scopes; unknown scopes are shown as sent.
  String ssoScopeLabel(String scope) => switch (scope) {
        'openid' => ssoScopeOpenid,
        'profile' => ssoScopeProfile,
        'email' => ssoScopeEmail,
        'phone' => ssoScopePhone,
        'offline_access' => ssoScopeOffline,
        _ => scope,
      };

  String ssoClaimLabel(SsoClaim claim) => switch (claim) {
        SsoClaim.profile => ssoClaimProfile,
        SsoClaim.verification => ssoClaimVerification,
        SsoClaim.business => ssoClaimBusiness,
        SsoClaim.roles => ssoClaimRoles,
      };
}

SsoFailureCode ssoFailureCodeOf(Object error) =>
    error is SsoFailure ? error.code : SsoFailureCode.unknown;

String ssoDate(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatMediumDate(value.toLocal());

IconData ssoScopeIcon(String scope) => switch (scope) {
      'openid' => Icons.verified_user_outlined,
      'profile' => Icons.person_outline,
      'email' => Icons.mail_outline,
      'phone' => Icons.phone_outlined,
      'offline_access' => Icons.sync_lock_outlined,
      _ => Icons.key_outlined,
    };

IconData ssoClaimIcon(SsoClaim claim) => switch (claim) {
      SsoClaim.profile => Icons.badge_outlined,
      SsoClaim.verification => Icons.task_alt,
      SsoClaim.business => Icons.storefront_outlined,
      SsoClaim.roles => Icons.admin_panel_settings_outlined,
    };
