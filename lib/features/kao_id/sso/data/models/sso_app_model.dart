import '../../domain/entities/sso_app.dart';

final class SsoAppModel extends SsoApp {
  const SsoAppModel({
    required super.appCode,
    required super.clientId,
    required super.displayName,
    required super.active,
    required super.firstParty,
    required super.claims,
    super.lastSeenAt,
  });

  /// Item shape of `app_directory_r18`.
  factory SsoAppModel.fromJson(Map<String, dynamic> json) => SsoAppModel(
        appCode: json['app_code'].toString(),
        clientId: json['client_id'].toString().toLowerCase(),
        displayName: json['display_name']?.toString() ?? '',
        active: json['status'] == 'active',
        firstParty: json['first_party'] == true,
        claims: parseClaims(json['claims']),
        lastSeenAt: DateTime.tryParse(json['last_seen_at']?.toString() ?? '')?.toLocal(),
      );

  static Set<SsoClaim> parseClaims(Object? raw) => {
        for (final value in raw is List ? raw : const []) ?SsoClaim.tryParse(value),
      };
}
