/// Admin Hub tools the signed-in staff member may open, from `staff_tools_r24`.
/// Company owners and Admin / Super Admin roles with the permission get them.
class StaffTools {
  const StaffTools({this.withdrawals = false, this.contents = false, this.pendingWithdrawals = 0});

  factory StaffTools.fromJson(Map<String, dynamic> json) => StaffTools(
    withdrawals: json['withdrawals'] == true,
    contents: json['contents'] == true,
    pendingWithdrawals: (json['pending_withdrawals'] as num?)?.toInt() ?? 0,
  );

  static const none = StaffTools();

  /// `wallet.withdraw.approve`.
  final bool withdrawals;

  /// `content.system.manage`.
  final bool contents;
  final int pendingWithdrawals;

  bool get any => withdrawals || contents;
}
