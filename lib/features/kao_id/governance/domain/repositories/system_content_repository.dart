import '../entities/system_content_item.dart';

abstract class SystemContentRepository {
  /// Every item including hidden ones; `app: null` lists all apps.
  Future<List<SystemContentItem>> list({String? app});

  /// Creates when [SystemContentItem.id] is `null`, otherwise updates that
  /// version.
  Future<SystemContentItem> save(SystemContentItem item);

  Future<void> delete(String id, int version);
}
