import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/governance/domain/repositories/owner_requests_repository.dart';
import 'package:kaosure/features/kao_id/governance/data/repositories/supabase_owner_requests_repository.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/owner_requests_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/owner_request_detail_page.dart';
import 'package:kaosure/features/kao_id/governance/presentation/widgets/admin_display.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;

class RequestFixture implements OwnerRequestsRepository {
  bool denied = false;
  bool failed = false;
  int decisions = 0;
  String status = 'pending';
  static final row = <String,dynamic>{'id':'request-test','profile_id':'member-test',
    'display_name':null,'account_code':'ACC-TEST-ONLY','kao_id':null,
    'kind':'closure','status':'pending','created_at':'2026-09-29T00:00:00Z'};
  @override
  Future<List<Map<String,dynamic>>> list(String status, Map<String,dynamic>? cursor) async {
    if(denied) { throw const PostgrestException(message:'owner_required',code:'42501'); }
    return [row];
  }
  @override
  Future<Map<String,dynamic>> checks(String id) async {
    if(failed) { throw StateError('private backend detail'); }
    return {'request':{'id':id,'status':status,'reason':'Member request'},
      'orders_total':0,'disputes_total':0,'wallets':[],'kyc_pending':0,'staff_active':0,
      'close_ready':false,'history':[]};
  }
  @override
  Future<void> reject(String id,String reason) async {
    expect(id,'request-test');expect(reason,'Review reason');decisions++;status='rejected';
  }
}
Future<void> mount(WidgetTester tester,RequestFixture repo,Locale locale,Widget page) async {
  await tester.pumpWidget(ProviderScope(overrides:[
    authProvider.overrideWith((ref)=>TestAuthNotifier(ref)),
    ownerRequestsRepositoryProvider.overrideWithValue(repo),
  ],child:MaterialApp(locale:locale,supportedLocales:AppLocalizations.supportedLocales,
    localizationsDelegates:AppLocalizations.localizationsDelegates,home:page)));
  await tester.pumpAndSettle();
}
void main() {
  for(final locale in AppLocalizations.supportedLocales) {
    testWidgets('Owner queue denies unauthorized access: $locale',(tester) async {
      await mount(tester,RequestFixture()..denied=true,locale,const OwnerRequestsPage());
      final l=AppLocalizations.of(tester.element(find.byType(OwnerRequestsPage)));
      expect(find.text(l.adminAccessDenied),findsOneWidget);
      expect(find.textContaining('ACC-TEST'),findsNothing);
    });
  }
  for(final locale in [const Locale('th'),const Locale('en')]) {
    testWidgets('Decision needs reason and confirmation, without account closure: $locale',(tester) async {
      final repo=RequestFixture();
      await mount(tester,repo,locale,OwnerRequestDetail(row:RequestFixture.row));
      final l=AppLocalizations.of(tester.element(find.byType(OwnerRequestDetail)));
      await tester.scrollUntilVisible(find.byType(TextField),200,scrollable:find.byType(Scrollable).first);
      final reject=find.widgetWithText(FilledButton,l.lifeReject);
      expect(tester.widget<FilledButton>(reject).onPressed,isNull);
      await tester.enterText(find.byType(TextField),'Review reason');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(reject);
      await tester.tap(reject);
      await tester.pumpAndSettle();
      expect(repo.decisions,0);
      expect(find.byType(AlertDialog),findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton,l.continueLabel));
      await tester.pumpAndSettle();
      expect(repo.decisions,1);
      expect(repo.status,'rejected');
      expect(find.byType(TextField),findsNothing);
      expect(tester.takeException(),isNull);
    });
  }
  testWidgets('Failed preflight does not show empty balances or enable decisions',(tester) async {
    await mount(tester,RequestFixture()..failed=true,const Locale('en'),OwnerRequestDetail(row:RequestFixture.row));
    final l=AppLocalizations.of(tester.element(find.byType(OwnerRequestDetail)));
    expect(find.text(l.reviewActionFailed),findsOneWidget);
    expect(find.text(l.lifeNoWallet),findsNothing);
    expect(find.byType(TextField),findsNothing);
    expect(find.text('private backend detail'),findsNothing);
  });
  testWidgets('Missing values and historical roles are not invented',(tester) async {
    await mount(tester,RequestFixture(),const Locale('th'),const OwnerRequestsPage());
    final context=tester.element(find.byType(OwnerRequestsPage));
    final l=AppLocalizations.of(context);
    expect(realValue(null),'—');expect(realValue(''),'—');
    expect(adminRoles(l,null),'—');
    final stamp=adminDate(context,'2026-09-28T06:47:00Z');
    expect(stamp,contains('UTC'));expect(stamp, isNot(contains('PM')));
    expect(adminDate(context,null),'—');
  });
}
