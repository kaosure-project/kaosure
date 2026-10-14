import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String realValue(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? '—' : text;
}
String adminDate(BuildContext context, dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) { return '—'; }
  final d = parsed.toLocal();
  final m = MaterialLocalizations.of(context);
  final offset = d.timeZoneOffset.inMinutes;
  final zone = '${offset < 0 ? '-' : '+'}${(offset.abs() ~/ 60).toString().padLeft(2, '0')}:${(offset.abs() % 60).toString().padLeft(2, '0')}';
  return '${m.formatFullDate(d)} · ${m.formatTimeOfDay(TimeOfDay.fromDateTime(d), alwaysUse24HourFormat: true)} (UTC$zone)';
}
class AdminValue extends StatelessWidget {
  const AdminValue({super.key, required this.label, required this.value, this.copyable = false});
  final String label;
  final dynamic value;
  final bool copyable;
  @override
  Widget build(BuildContext context) {
    final text = realValue(value);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(
      crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4), SelectableText(text),
        ])), if (copyable && text != '—') IconButton(
          tooltip: AppLocalizations.of(context).adminCopy,
          onPressed: () => Clipboard.setData(ClipboardData(text: text)),
          icon: const Icon(Icons.copy_outlined, size: 18)),
      ]));
  }
}
class AdminSection extends StatelessWidget {
  const AdminSection({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12), ...children,
      ])));
}

/// Label for an admin role code. Custom roles fall back to the name the Owner gave them.
String staffRoleLabel(AppLocalizations l, String code, [String? name]) => switch (code) {
  'catalog_admin' => l.staffRoleCatalogAdmin,
  'listing_audit_admin' => l.staffRoleListingAuditAdmin,
  'kaoid_admin' => l.staffRoleKaoidAdmin,
  'dispute_admin' => l.staffRoleDisputeAdmin,
  'finance_admin' => l.staffRoleFinanceAdmin,
  'logistics_admin' => l.staffRoleLogisticsAdmin,
  'cs_operator' => l.staffRoleCsOperator,
  'marketing_admin' => l.staffRoleMarketingAdmin,
  'i18n_admin' => l.staffRoleI18nAdmin,
  'legal_security_admin' => l.staffRoleLegalSecurityAdmin,
  'tech_support_admin' => l.staffRoleTechSupportAdmin,
  'admin' => l.staffAdmin, 'super_admin' => l.staffSuperAdmin,
  'support' => l.staffSupport, 'kyc_officer' => l.staffReviewer,
  _ => (name?.trim().isNotEmpty ?? false) ? name!.trim() : l.kycUnknownStatus,
};

String staffActionLabel(AppLocalizations l, String? action) => switch (action) {
  'governance.role.assign' || 'governance.role.migrate' => l.staffAssign,
  'governance.role.revoke' => l.staffRevoke,
  'governance.role.retire' => l.staffRetiredRole,
  'governance.role.create' => l.staffRoleCreate,
  'governance.role.update' => l.staffRoleSave,
  'governance.role.permission' => l.staffRolesTitle,
  'governance.grant.request' => l.staffGrantWaitingSecond,
  'governance.grant.schedule' => l.staffGrantCoolingOff,
  'governance.grant.activate' => l.staffGrantActivated,
  'governance.grant.cancel' => l.staffGrantCancelled,
  'governance.grant.reject' => l.staffGrantRejected,
  _ => l.kycUnknownStatus,
};

/// Message for an error from the staff and role RPCs.
String staffErrorText(AppLocalizations l, Object? error) {
  final code = error is PostgrestException ? error.message : error is StateError ? error.message : '';
  return switch (code) {
    'mfa_required' => l.mfaSessionRequired,
    'session_changed' || 'session' => l.contactSessionChanged,
    'owner_required' || 'approver_required' => l.adminAccessDenied,
    'invalid_decision' => l.reviewReasonRequired,
    'target_kyc_required' => l.staffKycRequired,
    'target_unavailable' || 'owner_role_protected' => l.staffTargetInvalid,
    'grant_pending' => l.staffGrantPendingError,
    'role_already_assigned' => l.staffRoleAlreadyAssigned,
    'second_person_required' => l.staffSecondPersonRequired,
    'role_in_use_dangerous' => l.staffRoleInUseDangerous,
    'role_code_invalid' => l.staffRoleCodeInvalid,
    'role_name_invalid' => l.staffRoleNameInvalid,
    'role_name_taken' => l.staffRoleNameTaken,
    'role_protected' || 'role_unavailable' => l.staffRoleProtected,
    'permission_owner_only' => l.staffPermissionOwnerOnly,
    _ => l.reviewActionFailed,
  };
}

String adminRoles(AppLocalizations l, dynamic roles) {
  if (roles is! List || roles.isEmpty) { return '—'; }
  return roles.map((r) => r == 'owner' ? l.adminOwner : staffRoleLabel(l, r.toString())).join(', ');
}
