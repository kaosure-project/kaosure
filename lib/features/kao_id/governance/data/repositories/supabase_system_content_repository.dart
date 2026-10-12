import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/system_content_item.dart';
import '../../domain/repositories/system_content_repository.dart';

/// `content_list_r24` / `content_save_r24` / `content_delete_r24`, allowed
/// with `content.system.manage`. Every save and delete keeps a revision and
/// an activity log entry on the server.
class SupabaseSystemContentRepository implements SystemContentRepository {
  SupabaseSystemContentRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SystemContentItem>> list({String? app}) async {
    final rows = await _client.rpc<dynamic>('content_list_r24', params: {'p_app': app});
    return [
      if (rows is List)
        for (final row in rows)
          if (row is Map) SystemContentItem.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  @override
  Future<SystemContentItem> save(SystemContentItem item) async {
    final row = await _client.rpc<dynamic>(
      'content_save_r24',
      params: {
        'p_id': item.id,
        'p_key': item.key,
        'p_app': item.app,
        'p_category': item.category,
        'p_title': item.title,
        'p_body': item.body,
        'p_meta': item.meta,
        'p_sort': item.sortOrder,
        'p_active': item.isActive,
        'p_version': item.version,
      },
    );
    return SystemContentItem.fromJson(row is Map ? Map<String, dynamic>.from(row) : const {});
  }

  @override
  Future<void> delete(String id, int version) =>
      _client.rpc<dynamic>('content_delete_r24', params: {'p_id': id, 'p_version': version});
}
