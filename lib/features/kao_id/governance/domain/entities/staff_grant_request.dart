/// How a role request becomes active.
enum StaffGrantMode {
  /// Another Owner or a Legal & security admin has to approve it.
  twoPerson,

  /// Nobody else can approve yet, so it starts 24 hours after the request.
  coolingOff,
}

enum StaffGrantStatus { pending, activated, rejected, cancelled, expired }

/// An Owner's request to give a member an admin role, from `staff_snapshot_r9b().grants`
/// or `staff_grant_queue_r47()`.
class StaffGrantRequest {
  const StaffGrantRequest({
    required this.id,
    required this.targetProfileId,
    required this.roleCode,
    required this.mode,
    required this.status,
    this.targetName,
    this.targetCode,
    this.roleName,
    this.expiresAt,
    this.activateAt,
    this.createdAt,
    this.decidedAt,
    this.decideBefore,
    this.decisionReason,
    this.canDecide = false,
  });

  factory StaffGrantRequest.fromJson(Map<dynamic, dynamic> json) => StaffGrantRequest(
    id: json['id'] as String,
    targetProfileId: json['target_profile_id'] as String,
    roleCode: json['code'] as String,
    mode: json['mode'] == 'cooling_off' ? StaffGrantMode.coolingOff : StaffGrantMode.twoPerson,
    status: StaffGrantStatus.values.firstWhere(
      (status) => status.name == json['status'],
      orElse: () => StaffGrantStatus.pending,
    ),
    targetName: json['target_name'] as String?,
    targetCode: json['target_code'] as String?,
    roleName: json['role_name'] as String?,
    expiresAt: _date(json['expires_at']),
    activateAt: _date(json['activate_at']),
    createdAt: _date(json['created_at']),
    decidedAt: _date(json['decided_at']),
    decideBefore: _date(json['decide_before']),
    decisionReason: json['decision_reason'] as String?,
    canDecide: json['can_decide'] == true,
  );

  final String id;
  final String targetProfileId;
  final String roleCode;
  final StaffGrantMode mode;
  final StaffGrantStatus status;
  final String? targetName;
  final String? targetCode;
  final String? roleName;
  final DateTime? expiresAt;
  final DateTime? activateAt;
  final DateTime? createdAt;
  final DateTime? decidedAt;
  final DateTime? decideBefore;
  final String? decisionReason;

  /// The signed-in person may approve or reject: they are neither the requester nor the member.
  final bool canDecide;

  bool get pending => status == StaffGrantStatus.pending;
}

List<StaffGrantRequest> staffGrantsFrom(List? rows) => [
  for (final row in rows ?? const []) StaffGrantRequest.fromJson(row as Map),
];

DateTime? _date(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());
