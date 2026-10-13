import 'package:kaosure/features/wallet/domain/entities/topup_request.dart';

/// A top-up as staff see it in the queue, from `topup_staff_json_r28`.
class TopupReviewItem {
  const TopupReviewItem({
    required this.request,
    required this.profileId,
    required this.dualReview,
    this.displayName,
    this.accountCode,
    this.firstReviewer,
    this.firstReviewerName,
    this.firstReviewedAt,
    this.bankReference,
    this.reviewerName,
  });

  factory TopupReviewItem.fromJson(Map<String, dynamic> json) => TopupReviewItem(
    request: TopupRequest.fromJson(json),
    profileId: json['profile_id'] as String? ?? '',
    dualReview: json['dual_review'] == true,
    displayName: json['display_name'] as String?,
    accountCode: json['account_code'] as String?,
    firstReviewer: json['first_reviewer'] as String?,
    firstReviewerName: json['first_reviewer_name'] as String?,
    firstReviewedAt: topupDate(json['first_reviewed_at']),
    bankReference: json['bank_reference'] as String?,
    reviewerName: json['reviewer_name'] as String?,
  );

  final TopupRequest request;
  final String profileId;

  /// From the two-person amount: one approval moves it to awaiting_second.
  final bool dualReview;
  final String? displayName;
  final String? accountCode;
  final String? firstReviewer;
  final String? firstReviewerName;
  final DateTime? firstReviewedAt;
  final String? bankReference;
  final String? reviewerName;
}

class TopupDuplicateSlip {
  const TopupDuplicateSlip({required this.code, required this.status, required this.amount, this.createdAt});

  factory TopupDuplicateSlip.fromJson(Map<String, dynamic> json) => TopupDuplicateSlip(
    code: json['code'] as String? ?? '',
    status: TopupStatus.fromCode(json['status']) ?? TopupStatus.pendingReview,
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    createdAt: topupDate(json['created_at']),
  );

  final String code;
  final TopupStatus status;
  final double amount;
  final DateTime? createdAt;
}

/// What staff check before crediting. Opening it is written to the activity log.
class TopupReviewDetail {
  const TopupReviewDetail({
    required this.item,
    required this.kaoIdActive,
    required this.ownRequest,
    this.slipPath,
    this.memberName,
    this.kaoId,
    this.walletBalance = 0,
    this.walletStatus,
    this.todayTotal = 0,
    this.duplicates = const [],
  });

  factory TopupReviewDetail.fromJson(Map<String, dynamic> json) => TopupReviewDetail(
    item: TopupReviewItem.fromJson(json),
    kaoIdActive: json['kao_id_active'] == true,
    ownRequest: json['own_request'] == true,
    slipPath: json['slip_path'] as String?,
    memberName: json['member_name'] as String?,
    kaoId: json['kao_id'] as String?,
    walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0,
    walletStatus: json['wallet_status'] as String?,
    todayTotal: (json['today_total'] as num?)?.toDouble() ?? 0,
    duplicates: [
      if (json['duplicate_slips'] is List)
        for (final row in json['duplicate_slips'] as List)
          if (row is Map) TopupDuplicateSlip.fromJson(Map<String, dynamic>.from(row)),
    ],
  );

  final TopupReviewItem item;
  final bool kaoIdActive;
  final bool ownRequest;
  final String? slipPath;

  /// Name on the member's approved identity document; the payer on the slip must match it.
  final String? memberName;
  final String? kaoId;
  final double walletBalance;
  final String? walletStatus;
  final double todayTotal;

  /// Other requests that used the same slip file.
  final List<TopupDuplicateSlip> duplicates;
}

enum PromptPayType {
  phone,
  nationalId('national_id'),
  ewallet;

  const PromptPayType([this._code]);

  final String? _code;

  String get code => _code ?? name;

  static PromptPayType? fromCode(Object? code) => values.where((type) => type.code == code).firstOrNull;

  /// The server's format check, so the form can explain it before saving.
  bool accepts(String id) => RegExp(switch (this) {
    PromptPayType.phone => r'^0[0-9]{9}$',
    PromptPayType.nationalId => r'^[0-9]{13}$',
    PromptPayType.ewallet => r'^[0-9]{15}$',
  }).hasMatch(id);
}

/// The PromptPay receiving account and limits, from `topup_settings_r28`.
class TopupSettings {
  const TopupSettings({
    required this.enabled,
    required this.minAmount,
    required this.maxAmount,
    required this.dailyMax,
    required this.dualReviewFrom,
    required this.slipHours,
    required this.version,
    this.promptPayType,
    this.promptPayId,
    this.receiverName,
    this.updatedAt,
    this.updatedByName,
  });

  factory TopupSettings.fromJson(Map<String, dynamic> json) => TopupSettings(
    enabled: json['enabled'] == true,
    promptPayType: PromptPayType.fromCode(json['promptpay_type']),
    promptPayId: json['promptpay_id'] as String?,
    receiverName: json['receiver_name'] as String?,
    minAmount: (json['min_amount'] as num?)?.toDouble() ?? 0,
    maxAmount: (json['max_amount'] as num?)?.toDouble() ?? 0,
    dailyMax: (json['daily_max'] as num?)?.toDouble() ?? 0,
    dualReviewFrom: (json['dual_review_from'] as num?)?.toDouble() ?? 0,
    slipHours: (json['slip_hours'] as num?)?.toInt() ?? 24,
    version: (json['version'] as num?)?.toInt() ?? 0,
    updatedAt: topupDate(json['updated_at']),
    updatedByName: json['updated_by_name'] as String?,
  );

  final bool enabled;
  final PromptPayType? promptPayType;
  final String? promptPayId;
  final String? receiverName;
  final double minAmount;
  final double maxAmount;
  final double dailyMax;
  final double dualReviewFrom;
  final int slipHours;

  /// Sent back on save; the server refuses a stale copy.
  final int version;
  final DateTime? updatedAt;
  final String? updatedByName;
}
