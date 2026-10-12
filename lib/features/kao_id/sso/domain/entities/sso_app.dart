/// Claim sections a registered app may read through `kao_id_claims_r18`.
enum SsoClaim {
  profile,
  verification,
  business,
  roles;

  static SsoClaim? tryParse(Object? value) {
    for (final claim in values) {
      if (claim.name == value) return claim;
    }
    return null;
  }
}

/// A sub-app registered with Kao ID, as members see it.
class SsoApp {
  const SsoApp({
    required this.appCode,
    required this.clientId,
    required this.displayName,
    required this.active,
    required this.firstParty,
    required this.claims,
    this.lastSeenAt,
  });

  final String appCode;
  final String clientId;
  final String displayName;
  final bool active;
  final bool firstParty;
  final Set<SsoClaim> claims;

  /// Last time this member's token for the app read claims; null if never.
  final DateTime? lastSeenAt;
}
