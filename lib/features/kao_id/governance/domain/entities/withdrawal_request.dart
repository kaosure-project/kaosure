enum WithdrawalStatus {
  pending,
  paid,
  rejected,
  cancelled;

  static WithdrawalStatus? fromCode(Object? code) => values.where((status) => status.name == code).firstOrNull;
}

/// A member's request to move wallet money to their verified bank account.
/// Staff transfer it outside the system and record the bank reference.
class WithdrawalRequest {
  const WithdrawalRequest({
    required this.id,
    required this.profileId,
    required this.amount,
    required this.status,
    required this.bankName,
    required this.accountName,
    required this.last4,
    this.displayName,
    this.accountCode,
    this.sourceApp,
    this.createdAt,
    this.reviewedAt,
    this.reviewerName,
    this.rejectReason,
    this.transferReference,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) => WithdrawalRequest(
    id: json['id'] as String? ?? '',
    profileId: json['profile_id'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    status: WithdrawalStatus.fromCode(json['status']) ?? WithdrawalStatus.pending,
    bankName: json['bank_name'] as String? ?? '',
    accountName: json['account_name'] as String? ?? '',
    last4: json['last4'] as String? ?? '',
    displayName: json['display_name'] as String?,
    accountCode: json['account_code'] as String?,
    sourceApp: json['source_app'] as String?,
    createdAt: _date(json['created_at']),
    reviewedAt: _date(json['reviewed_at']),
    reviewerName: json['reviewer_name'] as String?,
    rejectReason: json['reject_reason'] as String?,
    transferReference: json['transfer_reference'] as String?,
  );

  final String id;
  final String profileId;
  final double amount;
  final WithdrawalStatus status;
  final String bankName;
  final String accountName;
  final String last4;
  final String? displayName;
  final String? accountCode;
  final String? sourceApp;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewerName;
  final String? rejectReason;
  final String? transferReference;
}

/// What staff need to make the transfer. Reading it is written to the
/// activity log, because it holds the full account number.
class WithdrawalTransfer {
  const WithdrawalTransfer({
    required this.request,
    required this.accountNumber,
    required this.bankStillVerified,
    this.branchName,
    this.walletBalance = 0,
    this.walletHold = 0,
  });

  factory WithdrawalTransfer.fromJson(Map<String, dynamic> json) => WithdrawalTransfer(
    request: WithdrawalRequest.fromJson(json),
    accountNumber: json['account_number'] as String? ?? '',
    bankStillVerified: json['bank_still_verified'] == true,
    branchName: json['branch_name'] as String?,
    walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0,
    walletHold: (json['wallet_hold'] as num?)?.toDouble() ?? 0,
  );

  final WithdrawalRequest request;
  final String accountNumber;

  /// `false` once the member changed or lost the verified account; the
  /// request can then only be rejected.
  final bool bankStillVerified;
  final String? branchName;
  final double walletBalance;
  final double walletHold;
}

DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value) : null;
