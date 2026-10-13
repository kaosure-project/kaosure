/// Admin Hub tools the signed-in staff member may open, from `staff_tools_r24`.
/// Company owners and Admin / Super Admin roles with the permission get them.
class StaffTools {
  const StaffTools({
    this.withdrawals = false,
    this.contents = false,
    this.reviews = false,
    this.orderIssues = false,
    this.topups = false,
    this.topupSettings = false,
    this.pendingWithdrawals = 0,
    this.pendingReviewReports = 0,
    this.openOrderIssues = 0,
    this.pendingTopups = 0,
  });

  factory StaffTools.fromJson(Map<String, dynamic> json) => StaffTools(
    withdrawals: json['withdrawals'] == true,
    contents: json['contents'] == true,
    reviews: json['reviews'] == true,
    orderIssues: json['order_issues'] == true,
    topups: json['topups'] == true,
    topupSettings: json['topup_settings'] == true,
    pendingWithdrawals: (json['pending_withdrawals'] as num?)?.toInt() ?? 0,
    pendingReviewReports: (json['pending_review_reports'] as num?)?.toInt() ?? 0,
    openOrderIssues: (json['open_order_issues'] as num?)?.toInt() ?? 0,
    pendingTopups: (json['pending_topups'] as num?)?.toInt() ?? 0,
  );

  static const none = StaffTools();

  /// `wallet.withdraw.approve`.
  final bool withdrawals;

  /// `content.system.manage`.
  final bool contents;

  /// `marketplace.reviews.moderate`.
  final bool reviews;

  /// `marketplace.orders.resolve`.
  final bool orderIssues;

  /// `wallet.deposit.approve`.
  final bool topups;

  /// `wallet.deposit.settings`.
  final bool topupSettings;
  final int pendingWithdrawals;

  /// Reviews with at least one waiting report.
  final int pendingReviewReports;

  /// Secondhand order problems waiting for a decision.
  final int openOrderIssues;

  /// Top-ups with a slip waiting for the first or second reviewer.
  final int pendingTopups;

  bool get marketplace => reviews || orderIssues;

  bool get finance => withdrawals || contents || topups || topupSettings;

  bool get any => finance || marketplace;
}
