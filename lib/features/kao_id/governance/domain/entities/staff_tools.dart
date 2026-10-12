/// Admin Hub tools the signed-in staff member may open, from `staff_tools_r24`.
/// Company owners and Admin / Super Admin roles with the permission get them.
class StaffTools {
  const StaffTools({
    this.withdrawals = false,
    this.contents = false,
    this.reviews = false,
    this.orderIssues = false,
    this.pendingWithdrawals = 0,
    this.pendingReviewReports = 0,
    this.openOrderIssues = 0,
  });

  factory StaffTools.fromJson(Map<String, dynamic> json) => StaffTools(
    withdrawals: json['withdrawals'] == true,
    contents: json['contents'] == true,
    reviews: json['reviews'] == true,
    orderIssues: json['order_issues'] == true,
    pendingWithdrawals: (json['pending_withdrawals'] as num?)?.toInt() ?? 0,
    pendingReviewReports: (json['pending_review_reports'] as num?)?.toInt() ?? 0,
    openOrderIssues: (json['open_order_issues'] as num?)?.toInt() ?? 0,
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
  final int pendingWithdrawals;

  /// Reviews with at least one waiting report.
  final int pendingReviewReports;

  /// Secondhand order problems waiting for a decision.
  final int openOrderIssues;

  bool get marketplace => reviews || orderIssues;

  bool get any => withdrawals || contents || marketplace;
}
