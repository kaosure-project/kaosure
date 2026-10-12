import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/account/data/repositories/supabase_account_access_repository.dart';
import 'package:kaosure/features/wallet/domain/repositories/linked_wallet_repository.dart';
import 'package:kaosure/features/wallet/data/repositories/supabase_linked_wallet_repository.dart';
import 'package:kaosure/features/wallet/presentation/pages/linked_wallets_page.dart';
import 'package:kaosure/features/wallet/presentation/pages/partner_page.dart';
import 'package:kaosure/features/wallet/data/repositories/supabase_partner_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'closure_r10d_test.dart' show AccessFixture;
import 'partners_r12b_test.dart' show PartnerFixture;
class LinksFixture implements LinkedWalletRepository {
  bool fail=false;
  List<Map<String,dynamic>> rows=[];
  @override
  Future<List<Map<String,dynamic>>> load(String user,String? profile) async {if(fail) {throw StateError('sensitive details');}return rows;}
}
Future<void> mountLinks(WidgetTester t,AccessFixture a,LinksFixture r,{Locale locale=const Locale('en')}) async {
 await t.pumpWidget(ProviderScope(overrides:[accountAccessRepositoryProvider.overrideWithValue(a),linkedWalletRepositoryProvider.overrideWithValue(r)],child:MaterialApp(locale:locale,supportedLocales:AppLocalizations.supportedLocales,localizationsDelegates:AppLocalizations.localizationsDelegates,home:const LinkedWalletsPage())));await t.pumpAndSettle();
}
void main(){
 for(final locale in AppLocalizations.supportedLocales){testWidgets('Missing provider report is not zero: $locale',(t)async{
  final a=AccessFixture(),r=LinksFixture()..rows=[{'partner':'Fixture','environment':'live','currency':'THB','reference':'ref','connected':false,'snapshot':null,'updates':[]}];
  await mountLinks(t,a,r,locale:locale);final l=AppLocalizations.of(t.element(find.byType(LinkedWalletsPage)));
  expect(find.text(l.linkedNoSnapshot),findsOneWidget);expect(find.text('0 THB'),findsNothing);
  await t.pumpWidget(const SizedBox.shrink());await a.events.close();
 });}
 testWidgets('Provider balance reports remain separate and disappear on account switch',(t)async{
  final a=AccessFixture(),r=LinksFixture()..rows=[{'partner':'Fixture','environment':'live','currency':'THB','reference':'ref','connected':false,'snapshot':{'available':'123.45','held':'10.00','pending':'5.00','stale':true,'observed_at':'2026-01-01T00:00:00Z'},'updates':[]}];
  await mountLinks(t,a,r);final l=AppLocalizations.of(t.element(find.byType(LinkedWalletsPage)));
  expect(find.text('${l.linkedAvailable}: 123.45 THB'),findsOneWidget);expect(find.text(l.linkedStale),findsOneWidget);expect(find.text(l.linkedUnreconciled),findsOneWidget);
  a.userId='other';a.events.add(null);await t.pumpAndSettle();expect(find.text('Fixture'),findsNothing);
  await t.pumpWidget(const SizedBox.shrink());await a.events.close();
 });
 testWidgets('Access failure is not an empty wallet list',(t)async{
  final a=AccessFixture(),r=LinksFixture()..fail=true;await mountLinks(t,a,r);final l=AppLocalizations.of(t.element(find.byType(LinkedWalletsPage)));
  expect(find.text(l.walletLoadFailed),findsOneWidget);expect(find.text(l.linkedWalletEmpty),findsNothing);expect(find.text('sensitive details'),findsNothing);
  await t.pumpWidget(const SizedBox.shrink());await a.events.close();
 });
 testWidgets('Carrier registration offers only shipping capabilities',(t)async{
  final a=AccessFixture(),r=PartnerFixture()..rows=[];
  await t.pumpWidget(ProviderScope(overrides:[accountAccessRepositoryProvider.overrideWithValue(a),shippingPartnerRepositoryProvider.overrideWithValue(r)],child:MaterialApp(locale:const Locale('en'),supportedLocales:AppLocalizations.supportedLocales,localizationsDelegates:AppLocalizations.localizationsDelegates,home:const PartnerPage(shipping:true))));await t.pumpAndSettle();
  final l=AppLocalizations.of(t.element(find.byType(PartnerPage)));
  expect(find.text(l.carrierTitle),findsOneWidget);
  await t.tap(find.text(l.partnerAdd));await t.pumpAndSettle();
  expect(find.byType(CheckboxListTile),findsNWidgets(4));expect(find.text(l.partnerPayment),findsNothing);expect(find.text(l.partnerTopup),findsNothing);
  await t.pumpWidget(const SizedBox.shrink());await a.events.close();
 });
}
