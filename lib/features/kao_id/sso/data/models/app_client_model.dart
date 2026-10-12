import '../../domain/entities/app_client.dart';
import 'sso_app_model.dart';

final class AppClientModel extends AppClient {
  const AppClientModel({
    required super.appCode,
    required super.clientId,
    required super.displayName,
    required super.active,
    required super.firstParty,
    required super.claims,
    required super.rpcs,
    required super.tables,
    required super.oauthRegistered,
    required super.redirectUris,
    required super.members,
    super.oauthName,
    super.clientType,
    super.updatedAt,
  });

  /// Item shape of `app_clients_list_r18`.
  factory AppClientModel.fromJson(Map<String, dynamic> json) {
    List<String> names(Object? raw) => [
          for (final value in raw is List ? raw : const [])
            if (value is String && value.isNotEmpty) value,
        ];
    String? text(String key) {
      final value = json[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    return AppClientModel(
      appCode: json['app_code'].toString(),
      clientId: json['client_id'].toString().toLowerCase(),
      displayName: text('display_name') ?? '',
      active: json['status'] == 'active',
      firstParty: json['first_party'] == true,
      claims: SsoAppModel.parseClaims(json['claims']),
      rpcs: names(json['rpcs']),
      tables: names(json['tables']),
      oauthRegistered: json['oauth_registered'] == true,
      redirectUris: json['redirect_uris'] is List
          ? names(json['redirect_uris'])
          : [
              for (final uri in (text('redirect_uris') ?? '').split(','))
                if (uri.trim().isNotEmpty) uri.trim(),
            ],
      members: (json['members'] as num?)?.toInt() ?? 0,
      oauthName: text('oauth_name'),
      clientType: text('client_type'),
      updatedAt: DateTime.tryParse(text('updated_at') ?? '')?.toLocal(),
    );
  }
}
