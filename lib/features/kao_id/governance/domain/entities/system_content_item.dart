/// One guidance, rule, warning, terms or help text in `public.system_contents`.
/// Apps read active items through `get_system_contents`; staff edit them here.
class SystemContentItem {
  const SystemContentItem({
    this.id,
    required this.key,
    required this.app,
    required this.category,
    required this.title,
    required this.body,
    this.meta = const {},
    this.sortOrder = 0,
    this.isActive = true,
    this.version,
    this.updatedAt,
    this.updatedByName,
  });

  factory SystemContentItem.fromJson(Map<String, dynamic> json) => SystemContentItem(
    id: json['id'] as String?,
    key: json['key'] as String? ?? '',
    app: json['app'] as String? ?? '',
    category: json['category'] as String? ?? '',
    title: _texts(json['title']),
    body: _texts(json['body']),
    meta: json['meta'] is Map ? Map<String, dynamic>.from(json['meta'] as Map) : const {},
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    isActive: json['is_active'] != false,
    version: (json['version'] as num?)?.toInt(),
    updatedAt: json['updated_at'] is String ? DateTime.tryParse(json['updated_at'] as String) : null,
    updatedByName: json['updated_by_name'] as String?,
  );

  static const categories = ['help', 'guide', 'rule', 'warning', 'terms', 'notice', 'preset'];

  /// Whose review form shows a preset (`meta.role`).
  static const presetRoles = ['buyer', 'seller', 'any'];

  /// Presets are Secondhand review comments; the server only accepts them there.
  static const presetApp = 'secondhand';

  /// Apps that read contents; `common` is shared by all of them.
  static const apps = ['secondhand', 'common'];

  /// `null` until saved.
  final String? id;

  /// For example `secondhand.help.buying`; fixed once saved.
  final String key;
  final String app;
  final String category;

  /// Language code to text; Thai is required.
  final Map<String, String> title;
  final Map<String, String> body;
  final Map<String, dynamic> meta;
  final int sortOrder;
  final bool isActive;

  /// Sent back on save and delete so a stale copy can't overwrite newer text.
  final int? version;
  final DateTime? updatedAt;
  final String? updatedByName;

  String get icon => meta['icon'] as String? ?? '';

  String? get presetRole => meta['role'] as String?;
}

Map<String, String> _texts(Object? value) => {
  if (value is Map)
    for (final entry in value.entries)
      if (entry.value is String) entry.key.toString(): entry.value as String,
};
