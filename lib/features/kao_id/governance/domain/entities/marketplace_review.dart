/// Which reviews the moderation queue lists.
enum ReviewQueueFilter {
  /// Reviews with waiting reports, latest report first.
  reported,

  /// Hidden reviews, latest hidden first.
  hidden,

  /// Every review, newest first.
  recent,
}

enum ReviewReportStatus {
  pending,
  upheld,
  dismissed;

  static ReviewReportStatus fromCode(Object? code) =>
      values.where((status) => status.name == code).firstOrNull ?? ReviewReportStatus.pending;
}

/// A member on either side of a review.
class ReviewParty {
  const ReviewParty({required this.id, this.displayName, this.accountCode});

  factory ReviewParty.fromJson(Object? json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : const <String, dynamic>{};
    return ReviewParty(
      id: map['id'] as String? ?? '',
      displayName: map['display_name'] as String?,
      accountCode: map['account_code'] as String?,
    );
  }

  final String id;
  final String? displayName;
  final String? accountCode;
}

class ReviewReportEntry {
  const ReviewReportEntry({
    required this.id,
    required this.reason,
    required this.status,
    required this.reporter,
    this.detail,
    this.createdAt,
    this.resolvedAt,
  });

  factory ReviewReportEntry.fromJson(Map<String, dynamic> json) => ReviewReportEntry(
    id: json['id'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
    detail: json['detail'] as String?,
    status: ReviewReportStatus.fromCode(json['status']),
    createdAt: _date(json['created_at']),
    resolvedAt: _date(json['resolved_at']),
    reporter: ReviewParty.fromJson(json['reporter']),
  );

  /// abusive, personal_info, false_info, spam or other.
  final String reason;
  final String id;
  final String? detail;
  final ReviewReportStatus status;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final ReviewParty reporter;
}

/// A Secondhand review as staff see it, with its reports. Reviews are never
/// edited or deleted; staff can only hide one from members or show it again.
class MarketplaceReview {
  const MarketplaceReview({
    required this.id,
    required this.orderId,
    required this.good,
    required this.isVisible,
    required this.reviewer,
    required this.reviewee,
    this.orderNumber,
    this.comment,
    this.presetText = const {},
    this.reviewerRole,
    this.createdAt,
    this.hiddenAt,
    this.hiddenReason,
    this.hiddenByName,
    this.pendingReports = 0,
    this.totalReports = 0,
    this.lastReportedAt,
    this.reasons = const {},
    this.sortAt,
    this.reports = const [],
  });

  factory MarketplaceReview.fromJson(Map<String, dynamic> json) => MarketplaceReview(
    id: json['id'] as String? ?? '',
    orderId: json['order_id'] as String? ?? '',
    orderNumber: json['order_number'] as String?,
    good: json['verdict'] == 'good',
    comment: json['comment'] as String?,
    presetText: {
      if (json['preset_text'] case final Map texts)
        for (final entry in texts.entries)
          if (entry.value is String) entry.key.toString(): entry.value as String,
    },
    reviewerRole: json['reviewer_role'] as String?,
    createdAt: _date(json['created_at']),
    isVisible: json['is_visible'] != false,
    hiddenAt: _date(json['hidden_at']),
    hiddenReason: json['hidden_reason'] as String?,
    hiddenByName: json['hidden_by_name'] as String?,
    reviewer: ReviewParty.fromJson(json['reviewer']),
    reviewee: ReviewParty.fromJson(json['reviewee']),
    pendingReports: (json['pending_reports'] as num?)?.toInt() ?? 0,
    totalReports: (json['total_reports'] as num?)?.toInt() ?? 0,
    lastReportedAt: _date(json['last_reported_at']),
    reasons: {
      if (json['reasons'] case final Map reasons)
        for (final entry in reasons.entries)
          if (entry.value is num) entry.key.toString(): (entry.value as num).toInt(),
    },
    sortAt: _date(json['sort_at']),
    reports: [
      if (json['reports'] case final List rows)
        for (final row in rows)
          if (row is Map) ReviewReportEntry.fromJson(Map<String, dynamic>.from(row)),
    ],
  );

  final String id;
  final String orderId;
  final String? orderNumber;

  /// "ดี"; otherwise "ไม่ดี".
  final bool good;
  final String? comment;

  /// The preset as sent, by language code; empty without one.
  final Map<String, String> presetText;

  /// buyer or seller: who wrote it.
  final String? reviewerRole;
  final DateTime? createdAt;
  final bool isVisible;
  final DateTime? hiddenAt;
  final String? hiddenReason;
  final String? hiddenByName;
  final ReviewParty reviewer;
  final ReviewParty reviewee;
  final int pendingReports;
  final int totalReports;
  final DateTime? lastReportedAt;

  /// Waiting reports by reason.
  final Map<String, int> reasons;

  /// The queue's paging date.
  final DateTime? sortAt;

  /// Only filled by the detail.
  final List<ReviewReportEntry> reports;

  String? presetIn(String languageCode) {
    final text = presetText[languageCode];
    if (text != null && text.isNotEmpty) return text;
    return presetText['th'];
  }
}

DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value) : null;
