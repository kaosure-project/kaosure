import 'sso_app.dart';

/// Registry entry as the company owner manages it.
class AppClient {
  const AppClient({
    required this.appCode,
    required this.clientId,
    required this.displayName,
    required this.active,
    required this.firstParty,
    required this.claims,
    required this.rpcs,
    required this.tables,
    required this.oauthRegistered,
    required this.redirectUris,
    required this.members,
    this.oauthName,
    this.clientType,
    this.updatedAt,
  });

  final String appCode;
  final String clientId;
  final String displayName;
  final bool active;
  final bool firstParty;
  final Set<SsoClaim> claims;
  final List<String> rpcs;
  final List<String> tables;

  /// Whether the client still exists in Supabase Auth's OAuth server.
  final bool oauthRegistered;
  final List<String> redirectUris;
  final int members;
  final String? oauthName;
  final String? clientType;
  final DateTime? updatedAt;

  AppClientDraft toDraft() => AppClientDraft(
        appCode: appCode,
        clientId: clientId,
        displayName: displayName,
        firstParty: firstParty,
        claims: claims,
        rpcs: rpcs,
        tables: tables,
      );
}

enum AppClientField { appCode, clientId, displayName, rpcs, tables }

/// Input for registering or updating an app. Mirrors the server checks in
/// `app_client_save_r18` so the form can explain problems before saving.
///
/// Allow-list entries are `schema.name`; a bare name means `public`. Tables are
/// read-only unless the entry ends with [writeSuffix].
final class AppClientDraft {
  const AppClientDraft({
    required this.appCode,
    required this.clientId,
    required this.displayName,
    required this.firstParty,
    required this.claims,
    required this.rpcs,
    required this.tables,
  });

  static final RegExp _appCode = RegExp(r'^[a-z][a-z0-9_]{2,39}$');
  static final RegExp _uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
  static final RegExp _rpc = RegExp(r'^[a-z_][a-z0-9_]{0,62}\.[a-z_][a-z0-9_]{0,62}$');
  static final RegExp _table = RegExp(r'^[a-z_][a-z0-9_]{0,62}\.[a-z_][a-z0-9_]{0,62}(:write)?$');
  static const String writeSuffix = ':write';
  static const Set<String> _reservedSchemas = {
    'auth', 'storage', 'kaoid_private', 'extensions', 'vault', 'pgsodium', 'realtime', 'graphql',
    'graphql_public', 'supabase_functions', 'supabase_migrations', 'net', 'cron', 'pg_catalog',
    'information_schema',
  };
  static final RegExp _never = RegExp(
      r'^(app_client|admin|governance|kyc_|business_review|security_|enable_security|revoke_session|sessions_|lifecycle_|prepare_recovery|submit_recovery|reveal_|issue_|enable_mfa|mfa_)');
  static const Set<String> _neverTables = {
    'admin_assignments', 'admin_roles', 'company_owners', 'owner_delegations', 'activity_logs',
    'identity_documents', 'document_files', 'verification_requests', 'verifications',
    'financial_verifications', 'kao_id_identities', 'approval_requests', 'approval_histories',
  };
  static const int maxNames = 100;

  final String appCode;
  final String clientId;
  final String displayName;
  final bool firstParty;
  final Set<SsoClaim> claims;
  final List<String> rpcs;
  final List<String> tables;

  /// Splits comma, space or newline separated names into a clean list.
  static List<String> parseNames(String raw) => {
        for (final part in raw.split(RegExp(r'[\s,]+')))
          if (part.trim().isNotEmpty) part.trim().toLowerCase(),
      }.toList();

  /// Kao ID functions and tables an app may never reach, whatever the schema.
  static bool isProtectedName(String name) {
    final bare = name.split(':').first.split('.').last;
    return _never.hasMatch(bare) || _neverTables.contains(bare) ||
        (name.contains('.') && _reservedSchemas.contains(name.split('.').first));
  }

  static List<String> _qualified(List<String> names) => {
        for (final name in parseNames(names.join(',')))
          if (name.contains('.')) name else 'public.$name',
      }.toList();

  AppClientDraft normalized() => AppClientDraft(
        appCode: appCode.trim().toLowerCase(),
        clientId: clientId.trim().toLowerCase(),
        displayName: displayName.trim(),
        firstParty: firstParty,
        claims: claims,
        rpcs: _qualified(rpcs),
        tables: _qualified(tables),
      );

  Set<AppClientField> get invalidFields {
    final draft = normalized();
    bool badNames(List<String> names, RegExp format) => names.length > maxNames ||
        names.any((name) => !format.hasMatch(name) || isProtectedName(name));
    return {
      if (!_appCode.hasMatch(draft.appCode)) AppClientField.appCode,
      if (!_uuid.hasMatch(draft.clientId)) AppClientField.clientId,
      if (draft.displayName.length < 2 || draft.displayName.length > 80) AppClientField.displayName,
      if (badNames(draft.rpcs, _rpc)) AppClientField.rpcs,
      if (badNames(draft.tables, _table)) AppClientField.tables,
    };
  }

  bool get isValid => invalidFields.isEmpty;
}
