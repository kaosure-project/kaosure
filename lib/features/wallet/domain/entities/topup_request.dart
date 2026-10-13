enum TopupStatus {
  awaitingSlip('awaiting_slip'),
  pendingReview('pending_review'),
  awaitingSecond('awaiting_second'),
  approved('approved'),
  rejected('rejected'),
  cancelled('cancelled'),
  expired('expired');

  const TopupStatus(this.code);

  final String code;

  static TopupStatus? fromCode(Object? code) => values.where((status) => status.code == code).firstOrNull;

  /// Still counts as the member's one open request.
  bool get open => this == awaitingSlip || this == pendingReview || this == awaitingSecond;
}

/// A wallet top-up by PromptPay transfer. The QR payload is only sent while
/// the request still waits for its slip.
class TopupRequest {
  const TopupRequest({
    required this.id,
    required this.code,
    required this.amount,
    required this.status,
    this.sourceApp,
    this.receiverName,
    this.promptPayType,
    this.promptPayMasked,
    this.qrPayload,
    this.expiresAt,
    this.slipUploadedAt,
    this.reviewedAt,
    this.rejectReason,
    this.createdAt,
  });

  factory TopupRequest.fromJson(Map<String, dynamic> json) => TopupRequest(
    id: json['id'] as String? ?? '',
    code: json['code'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    status: TopupStatus.fromCode(json['status']) ?? TopupStatus.pendingReview,
    sourceApp: json['source_app'] as String?,
    receiverName: json['receiver_name'] as String?,
    promptPayType: json['promptpay_type'] as String?,
    promptPayMasked: json['promptpay_masked'] as String?,
    qrPayload: json['qr_payload'] as String?,
    expiresAt: topupDate(json['expires_at']),
    slipUploadedAt: topupDate(json['slip_uploaded_at']),
    reviewedAt: topupDate(json['reviewed_at']),
    rejectReason: json['reject_reason'] as String?,
    createdAt: topupDate(json['created_at']),
  );

  final String id;

  /// "TU" and 8 characters, shown to the member and staff.
  final String code;
  final double amount;
  final TopupStatus status;
  final String? sourceApp;
  final String? receiverName;
  final String? promptPayType;
  final String? promptPayMasked;
  final String? qrPayload;
  final DateTime? expiresAt;
  final DateTime? slipUploadedAt;
  final DateTime? reviewedAt;
  final String? rejectReason;
  final DateTime? createdAt;
}

/// Why the member can't start a top-up right now, from `topup_info_r28`.
enum TopupBlock {
  unavailable('topup_unavailable'),
  kaoIdRequired('kao_id_required'),
  walletUnavailable('wallet_unavailable'),
  requestOpen('request_open'),
  dailyLimitReached('daily_limit_reached');

  const TopupBlock(this.code);

  final String code;

  static TopupBlock? fromCode(Object? code) => values.where((block) => block.code == code).firstOrNull;
}

class TopupInfo {
  const TopupInfo({
    required this.canTopUp,
    required this.balance,
    required this.minAmount,
    required this.maxAmount,
    required this.dailyMax,
    required this.todayTotal,
    required this.slipHours,
    this.currency = 'THB',
    this.block,
    this.receiverName,
    this.open,
  });

  factory TopupInfo.fromJson(Map<String, dynamic> json) => TopupInfo(
    canTopUp: json['can_top_up'] == true,
    balance: (json['balance'] as num?)?.toDouble() ?? 0,
    currency: json['currency'] as String? ?? 'THB',
    minAmount: (json['min_amount'] as num?)?.toDouble() ?? 0,
    maxAmount: (json['max_amount'] as num?)?.toDouble() ?? 0,
    dailyMax: (json['daily_max'] as num?)?.toDouble() ?? 0,
    todayTotal: (json['today_total'] as num?)?.toDouble() ?? 0,
    slipHours: (json['slip_hours'] as num?)?.toInt() ?? 24,
    block: TopupBlock.fromCode(json['reason']),
    receiverName: json['receiver_name'] as String?,
    open: json['open'] is Map ? TopupRequest.fromJson(Map<String, dynamic>.from(json['open'] as Map)) : null,
  );

  final bool canTopUp;
  final double balance;
  final String currency;
  final double minAmount;

  /// Already lowered to what is left of today's limit.
  final double maxAmount;
  final double dailyMax;
  final double todayTotal;
  final int slipHours;
  final TopupBlock? block;
  final String? receiverName;
  final TopupRequest? open;
}

DateTime? topupDate(Object? value) => value is String ? DateTime.tryParse(value) : null;
