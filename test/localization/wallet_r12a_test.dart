import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/wallet/wallet_page.dart';
import 'package:kaosure/features/kao_id/account/lifecycle/account_access_gate.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'closure_r10d_test.dart' show AccessFixture;

class WalletFixture implements WalletRepository {
  bool fail = false;
  Map<String,dynamic> data = {'wallet':null,'transactions':[],'has_more':false};
  Completer<Map<String,dynamic>>? pending;
  @override
  Future<Map<String,dynamic>> load(String user,{String? time,String? id}) async {
    if(fail) {throw StateError('private backend details');}
    return pending == null ? data : await pending!.future;
  }
}
Future<void> mountWallet(WidgetTester t,AccessFixture a,WalletFixture r,{Locale locale=const Locale('en')}) async {
  await t.pumpWidget(ProviderScope(overrides:[
    accountAccessRepositoryProvider.overrideWithValue(a),walletRepositoryProvider.overrideWithValue(r),
  ],child:MaterialApp(locale:locale,supportedLocales:AppLocalizations.supportedLocales,
    localizationsDelegates:AppLocalizations.localizationsDelegates,home:const WalletPage())));
  await t.pumpAndSettle();
}
void main(){
  for(final locale in AppLocalizations.supportedLocales){
    testWidgets('Missing wallet is not a zero balance: $locale',(t) async {
      final a=AccessFixture(),r=WalletFixture();
      await mountWallet(t,a,r,locale:locale);
      final l=AppLocalizations.of(t.element(find.byType(WalletPage)));
      expect(find.text(l.walletMissing),findsOneWidget);
      expect(find.text(l.walletRecorded),findsNothing);
      expect(find.text(l.walletNoTransactions),findsNothing);
      await t.pumpWidget(const SizedBox.shrink());await a.events.close();
    });
  }
  testWidgets('Exact recorded amount cleared after account switch',(t) async {
    final a=AccessFixture(),r=WalletFixture();
    r.data={'wallet':{'balance':'123.4500','hold_balance':'20','currency':'THB','status':'active'},'transactions':[],'has_more':false};
    await mountWallet(t,a,r);
    expect(find.byWidgetPredicate((w)=>w is SelectableText && w.data=='123.4500 THB'),findsOneWidget);
    a.userId='other';a.events.add(null);await t.pumpAndSettle();
    expect(find.byWidgetPredicate((w)=>w is SelectableText && w.data=='123.4500 THB'),findsNothing);
    await t.pumpWidget(const SizedBox.shrink());await a.events.close();
  });
  testWidgets('Failure is distinct from missing wallet and can retry',(t) async {
    final a=AccessFixture(),r=WalletFixture()..fail=true;
    await mountWallet(t,a,r);
    final l=AppLocalizations.of(t.element(find.byType(WalletPage)));
    expect(find.text(l.walletLoadFailed),findsOneWidget);expect(find.text(l.walletMissing),findsNothing);
    expect(find.text('private backend details'),findsNothing);
    r.fail=false;await t.tap(find.widgetWithText(OutlinedButton,l.retry));await t.pumpAndSettle();
    expect(find.text(l.walletMissing),findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());await a.events.close();
  });
  testWidgets('Late response cannot restore previous account data',(t) async {
    final a=AccessFixture(),r=WalletFixture();await mountWallet(t,a,r);
    r.pending=Completer<Map<String,dynamic>>();
    final l=AppLocalizations.of(t.element(find.byType(WalletPage)));
    await t.tap(find.widgetWithText(TextButton,l.authCheckAgain));await t.pump();
    a.userId='other';a.events.add(null);await t.pump();
    r.pending!.complete({'wallet':{'balance':'999','currency':'THB'},'transactions':[],'has_more':false});
    await t.pumpAndSettle();
    expect(find.byWidgetPredicate((w)=>w is SelectableText && w.data=='999 THB'),findsNothing);
    expect(find.text(l.contactSessionChanged),findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());await a.events.close();
  });
}
