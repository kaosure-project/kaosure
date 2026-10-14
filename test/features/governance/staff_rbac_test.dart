import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/member_access_provider.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/staff_tools_providers.dart';
import 'package:kaosure/features/kao_id/governance/data/repositories/supabase_staff_repository.dart';
import 'package:kaosure/features/kao_id/governance/domain/entities/staff_grant_request.dart';
import 'package:kaosure/features/kao_id/governance/domain/entities/staff_role.dart';
import 'package:kaosure/features/kao_id/governance/domain/entities/staff_tools.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/staff_repository.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/admin_hub_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/grant_approvals_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/role_editor_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/staff_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/widgets/admin_display.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/kyc_review_providers.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../localization/auth_localization_r2_test.dart' show TestAuthNotifier;

final l = lookupAppLocalizations(const Locale('th'));

const _lineRoles = [
  'catalog_admin', 'listing_audit_admin', 'kaoid_admin', 'dispute_admin', 'finance_admin', 'logistics_admin',
  'cs_operator', 'marketing_admin', 'i18n_admin', 'legal_security_admin', 'tech_support_admin',
];

Map<String, dynamic> _snapshot() => {
  'roles': [
    {'id': 'r1', 'code': 'kaoid_admin', 'name': 'Kao ID admin', 'is_system': true, 'is_active': true,
      'legacy': false, 'holders': 1, 'permissions': ['admin.dashboard.view', 'kaoid.kyc.review']},
    {'id': 'r2', 'code': 'custom_promo', 'name': 'ทีมโปรโมชัน', 'description': 'ดูแลแบนเนอร์', 'is_system': false,
      'is_active': true, 'legacy': false, 'holders': 0, 'permissions': ['admin.dashboard.view']},
    {'id': 'r3', 'code': 'kyc_officer', 'name': 'KYC officer', 'is_system': true, 'is_active': false,
      'legacy': true, 'holders': 0, 'permissions': []},
  ],
  'catalogue': [
    {'code': 'admin.dashboard.view', 'category': 'admin', 'name': 'View dashboard', 'dangerous': false, 'owner_only': false},
    {'code': 'admin.roles.update', 'category': 'admin', 'name': 'Edit roles', 'dangerous': true, 'owner_only': true},
    {'code': 'marketing.banners.manage', 'category': 'marketing', 'name': 'Manage banners', 'dangerous': false,
      'owner_only': false},
    {'code': 'marketing.coupons.manage', 'category': 'marketing', 'name': 'Manage coupons', 'dangerous': true,
      'owner_only': false},
  ],
  'assignments': [
    {'id': 'a1', 'profile_id': 'p-staff', 'display_name': 'สมหญิง', 'account_code': 'KAO-0002', 'code': 'kaoid_admin',
      'role_name': 'Kao ID admin', 'is_active': true, 'currently_assigned': false, 'scheduled': true,
      'needs_mfa': true, 'starts_at': '2026-10-15T03:00:00Z', 'expires_at': null},
  ],
  'grants': [
    {'id': 'g1', 'target_profile_id': 'p-new', 'target_name': 'สมชาย', 'target_code': 'KAO-0003',
      'code': 'finance_admin', 'role_name': 'Finance admin', 'mode': 'two_person', 'status': 'pending',
      'created_at': '2026-10-14T03:00:00Z', 'decide_before': '2026-10-17T03:00:00Z', 'can_decide': true},
    {'id': 'g2', 'target_profile_id': 'p-old', 'target_name': 'สมปอง', 'target_code': 'KAO-0004',
      'code': 'cs_operator', 'role_name': 'CS operator', 'mode': 'cooling_off', 'status': 'rejected',
      'decision_reason': 'ยังไม่ผ่านการอบรม', 'can_decide': false},
  ],
  'approver_ready': true,
  'history': [
    {'id': 'h1', 'action': 'governance.grant.request', 'description': '{"role":"finance_admin","target_profile_id":"p-new"}',
      'target_name': 'สมชาย', 'target_code': 'KAO-0003', 'created_at': '2026-10-14T03:00:00Z'},
  ],
};

final class _FakeStaff implements StaffRepository {
  final calls = <String>[];
  Object? failure;

  Future<void> _record(String call) async {
    calls.add(call);
    if (failure case final error?) throw error;
  }

  @override
  Future<Map<String, dynamic>> load() async => _snapshot();

  @override
  Future<void> assign(String target, String role) => _record('assign:$target:$role');

  @override
  Future<void> revoke(String id) => _record('revoke:$id');

  @override
  Future<void> createRole(String code, String name, String? description) =>
      _record('create:$code:$name:${description ?? ''}');

  @override
  Future<void> updateRole(String code, String name, String? description, bool active) =>
      _record('update:$code:$name:${description ?? ''}:$active');

  @override
  Future<void> setPermission(String role, String permission, bool enabled) =>
      _record('permission:$role:$permission:$enabled');

  @override
  Future<void> cancelGrant(String id) => _record('cancel:$id');

  @override
  Future<void> decideGrant(String id, bool approve, String? reason) =>
      _record('decide:$id:$approve:${reason ?? ''}');

  List<Map<String, dynamic>> queue = [
    {'id': 'g1', 'target_profile_id': 'p-new', 'target_name': 'สมชาย', 'target_code': 'KAO-0003',
      'code': 'finance_admin', 'role_name': 'Finance admin', 'requested_by': 'p-owner',
      'requester_name': 'เจ้าของ', 'requester_code': 'KAO-0001', 'created_at': '2026-10-14T03:00:00Z',
      'decide_before': '2026-10-17T03:00:00Z', 'can_decide': true,
      'permissions': [{'code': 'admin.dashboard.view', 'dangerous': false},
        {'code': 'wallet.withdraw.approve', 'dangerous': true}]},
  ];

  @override
  Future<List<Map<String, dynamic>>> grantQueue() async {
    calls.add('queue');
    return queue;
  }
}

void main() {
  late _FakeStaff staff;

  setUp(() => staff = _FakeStaff());

  Future<void> pump(WidgetTester tester, Widget home, {StaffTools tools = StaffTools.none}) async {
    tester.view.physicalSize = const Size(1280, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
        staffRepositoryProvider.overrideWithValue(staff),
        memberAccessProvider.overrideWith((ref) async => false),
        kycReviewerAccessProvider.overrideWith((ref) async => false),
        staffToolsProvider.overrideWith((ref) async => tools),
      ],
      child: MaterialApp(
        locale: const Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ));
    await tester.pumpAndSettle();
  }

  test('snapshot entities read roles, permissions and grants', () {
    final roles = staffRolesFrom(_snapshot());
    expect(roles.map((r) => r.code), ['kaoid_admin', 'custom_promo', 'kyc_officer']);
    expect(roles.first.permissions, {'admin.dashboard.view', 'kaoid.kyc.review'});
    expect(roles[1].custom, isTrue);
    expect(roles.last.editable, isFalse);

    final catalogue = staffCatalogueFrom(_snapshot());
    expect(catalogue[1].ownerOnly, isTrue);
    expect(catalogue[3].dangerous, isTrue);

    final grants = staffGrantsFrom(_snapshot()['grants'] as List);
    expect(grants.first.mode, StaffGrantMode.twoPerson);
    expect(grants.first.pending, isTrue);
    expect(grants.first.decideBefore, DateTime.utc(2026, 10, 17, 3));
    expect(grants.last.mode, StaffGrantMode.coolingOff);
    expect(grants.last.status, StaffGrantStatus.rejected);
  });

  test('every line role has its own label in every language, custom roles use their name', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final t = lookupAppLocalizations(locale);
      final labels = {for (final code in _lineRoles) staffRoleLabel(t, code)};
      expect(labels, hasLength(_lineRoles.length), reason: '$locale');
      expect(labels, isNot(contains(t.kycUnknownStatus)), reason: '$locale');
    }
    expect(staffRoleLabel(l, 'custom_promo', ' ทีมโปรโมชัน '), 'ทีมโปรโมชัน');
    expect(staffRoleLabel(l, 'custom_promo'), l.kycUnknownStatus);
    expect(staffErrorText(l, const PostgrestException(message: 'grant_pending')), l.staffGrantPendingError);
    expect(staffErrorText(l, const PostgrestException(message: 'permission_owner_only')), l.staffPermissionOwnerOnly);
  });

  testWidgets('staff page lists grant requests and the second approver decides with a reason', (tester) async {
    await pump(tester, const StaffPage());
    expect(find.text(l.staffGrantsTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('grant-g1')), findsOneWidget);
    expect(find.text(l.staffGrantWaitingSecond), findsWidgets);
    expect(find.text(l.staffRoleFinanceAdmin), findsWidgets);
    expect(find.text('ยังไม่ผ่านการอบรม'), findsOneWidget);
    expect(find.byKey(const ValueKey('grant-cancel-g2')), findsNothing);
    expect(find.text(l.staffNeedsMfa), findsOneWidget);
    expect(find.text(l.staffStartsAt), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('grant-reject-g1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('grant-reason')), ' ยังไม่ผ่านการตรวจประวัติ ');
    await tester.tap(find.widgetWithText(FilledButton, l.continueLabel));
    await tester.pumpAndSettle();
    expect(staff.calls, ['decide:g1:false:ยังไม่ผ่านการตรวจประวัติ']);

    await tester.tap(find.byKey(const ValueKey('grant-cancel-g1')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l.cancel));
    await tester.pumpAndSettle();
    expect(staff.calls, hasLength(1));

    staff.failure = const PostgrestException(message: 'second_person_required', code: '42501');
    await tester.tap(find.byKey(const ValueKey('grant-approve-g1')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l.continueLabel));
    await tester.pumpAndSettle();
    expect(staff.calls.last, 'decide:g1:true:');
    expect(find.text(l.staffSecondPersonRequired), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('role editor hides retired and owner-only entries and saves permission switches', (tester) async {
    await pump(tester, const RoleEditorPage());
    await tester.tap(find.byKey(const ValueKey('role-select')));
    await tester.pumpAndSettle();
    expect(find.textContaining(l.staffReviewer), findsNothing);
    await tester.tap(find.textContaining('ทีมโปรโมชัน').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('permission-admin.roles.update')), findsNothing);
    expect(find.byKey(const ValueKey('permission-marketing.coupons.manage')), findsOneWidget);
    expect(find.textContaining(l.staffPermissionDangerous), findsWidgets);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('role-edit-name'))).controller!.text, 'ทีมโปรโมชัน');

    await tester.tap(find.byKey(const ValueKey('permission-marketing.banners.manage')));
    await tester.pumpAndSettle();
    expect(staff.calls, ['permission:custom_promo:marketing.banners.manage:true']);

    staff.failure = const PostgrestException(message: 'role_in_use_dangerous');
    await tester.tap(find.byKey(const ValueKey('permission-marketing.coupons.manage')));
    await tester.pumpAndSettle();
    expect(find.text(l.staffRoleInUseDangerous), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('admin hub tools read the grant approval flag and count', () {
    final tools = StaffTools.fromJson({'grant_approvals': true, 'pending_grants': 2});
    expect(tools.grantApprovals, isTrue);
    expect(tools.pendingGrants, 2);
    expect(tools.any, isTrue);
    expect(tools.finance, isFalse);
  });

  testWidgets('a second approver without member access opens the queue from the hub', (tester) async {
    await pump(tester, const AdminHubPage(), tools: const StaffTools(grantApprovals: true, pendingGrants: 1));
    expect(find.text(l.adminAccessDenied), findsNothing);
    expect(find.text(l.grantApprovalsHubHelp), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text(l.grantApprovalsHubHelp));
    await tester.pumpAndSettle();
    expect(find.byType(GrantApprovalsPage), findsOneWidget);
    expect(find.byKey(const ValueKey('grant-g1')), findsOneWidget);
    expect(find.textContaining('เจ้าของ'), findsOneWidget);
    expect(find.text('wallet.withdraw.approve · ${l.staffPermissionDangerous}'), findsOneWidget);
    expect(find.text('admin.dashboard.view'), findsOneWidget);
    expect(find.byKey(const ValueKey('grant-cancel-g1')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('approving needs a two-factor session and a decided request leaves the queue', (tester) async {
    await pump(tester, const GrantApprovalsPage());
    staff.failure = const PostgrestException(message: 'mfa_required', code: '42501');
    await tester.tap(find.byKey(const ValueKey('grant-approve-g1')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l.continueLabel));
    await tester.pumpAndSettle();
    expect(staff.calls, ['queue', 'decide:g1:true:']);
    expect(find.text(l.mfaSessionRequired), findsOneWidget);
    expect(find.byKey(const ValueKey('grant-g1')), findsOneWidget);

    staff.failure = null;
    await tester.tap(find.byKey(const ValueKey('grant-approve-g1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('grant-reason')), 'ตรวจประวัติแล้ว');
    staff.queue = [];
    await tester.tap(find.widgetWithText(FilledButton, l.continueLabel));
    await tester.pumpAndSettle();
    expect(staff.calls.skip(2), ['decide:g1:true:ตรวจประวัติแล้ว', 'queue']);
    expect(find.byKey(const ValueKey('grant-g1')), findsNothing);
    expect(find.text(l.staffEmpty), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a new role needs a custom_ code and a name before it can be created', (tester) async {
    await pump(tester, const RoleEditorPage());
    final create = find.byKey(const ValueKey('role-create'));
    expect(tester.widget<ButtonStyleButton>(create).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('role-code')), 'promo');
    await tester.enterText(find.byKey(const ValueKey('role-name')), 'ทีมคูปอง');
    await tester.pump();
    expect(tester.widget<ButtonStyleButton>(create).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('role-code')), 'custom_coupon_team');
    await tester.pump();
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(staff.calls, ['create:custom_coupon_team:ทีมคูปอง:']);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('role-code'))).controller!.text, 'custom_');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
