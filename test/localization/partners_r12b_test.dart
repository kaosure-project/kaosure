import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/account/data/repositories/supabase_account_access_repository.dart';
import 'package:kaosure/features/wallet/partners/partner_page.dart';
import 'package:kaosure/features/wallet/partners/partner_repository.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'closure_r10d_test.dart' show AccessFixture;
class PartnerFixture implements PartnerRepository {
  bool fail=false;int calls=0;
  List<Map<String,dynamic>> rows=[{'id':'partner','code':'fixture','name':'Fixture Partner','environment':'sandbox','approval':'pending','enabled':false,'ready':false,'connected':false,'capabilities':['balance'],'revision':1,'history':[]}];
  @override
  Future<List<Map<String,dynamic>>> list(String user) async {if(fail) {throw StateError('secret server response');}return rows;}
  @override
  Future<void> create(String user,String code,String name,String environment,List<String> capabilities) async {calls++;}
  @override
  Future<void> decide(String user,String id,int revision,String action,String reason) async {
    calls++;rows=[{...rows.first,'approval':action=='approve'?'approved':'disabled','revision':revision+1}];
  }
}
Future<void> mountPartner(WidgetTester t,AccessFixture a,PartnerFixture r,{Locale locale=const Locale('en')}) async {
 await t.pumpWidget(ProviderScope(overrides:[accountAccessRepositoryProvider.overrideWithValue(a),partnerRepositoryProvider.overrideWithValue(r)],child:MaterialApp(locale:locale,supportedLocales:AppLocalizations.supportedLocales,localizationsDelegates:AppLocalizations.localizationsDelegates,home:const PartnerPage())));
 await t.pumpAndSettle();
}
void main(){
 for(final locale in AppLocalizations.supportedLocales){
  testWidgets('Approved is not connected without server readiness: $locale',(t)async{
    final a=AccessFixture(),r=PartnerFixture();r.rows.first['approval']='approved';
    await mountPartner(t,a,r,locale:locale);
    final l=AppLocalizations.of(t.element(find.byType(PartnerPage)));
    expect(find.text(l.partnerNotConnected),findsOneWidget);
    expect(find.text(l.partnerNotReady),findsOneWidget);
    final enable=find.widgetWithText(FilledButton,l.partnerEnable);
    expect(t.widget<FilledButton>(enable).onPressed,isNull);
    await t.pumpWidget(const SizedBox.shrink());await a.events.close();
  });
 }
 testWidgets('Owner action requires reason and cancel changes nothing',(t)async{
  final a=AccessFixture(),r=PartnerFixture();await mountPartner(t,a,r);
  final l=AppLocalizations.of(t.element(find.byType(PartnerPage)));
  final approve=find.widgetWithText(FilledButton,l.partnerApprove);
  await t.ensureVisible(approve);await t.tap(approve);await t.pumpAndSettle();
  expect(t.widget<FilledButton>(find.widgetWithText(FilledButton,l.continueLabel)).onPressed,isNull);
  await t.tap(find.widgetWithText(TextButton,l.cancel));await t.pumpAndSettle();expect(r.calls,0);
  await t.ensureVisible(approve);await t.tap(approve);await t.pumpAndSettle();
  await t.enterText(find.byType(TextField),'Reviewed partner scope');await t.pumpAndSettle();
  await t.tap(find.widgetWithText(FilledButton,l.continueLabel));await t.pumpAndSettle();
  expect(r.calls,1);expect(r.rows.first['approval'],'approved');expect(r.rows.first['connected'],false);
  a.userId='changed';a.events.add(null);await t.pumpAndSettle();
  expect(find.text('Fixture Partner'),findsNothing);expect(find.text(l.contactSessionChanged),findsOneWidget);
  await t.pumpWidget(const SizedBox.shrink());await a.events.close();
 });
 testWidgets('Denied or failed load offers no registration action',(t)async{
  final a=AccessFixture(),r=PartnerFixture()..fail=true;await mountPartner(t,a,r);
  final l=AppLocalizations.of(t.element(find.byType(PartnerPage)));
  expect(find.text(l.partnerFailed),findsOneWidget);expect(find.text(l.partnerAdd),findsNothing);
  expect(find.text('secret server response'),findsNothing);
  await t.pumpWidget(const SizedBox.shrink());await a.events.close();
 });
 testWidgets('Changing accounts with dialog open cannot submit an old action',(t)async{
  final a=AccessFixture(),r=PartnerFixture();await mountPartner(t,a,r);
  final l=AppLocalizations.of(t.element(find.byType(PartnerPage)));
  final approve=find.widgetWithText(FilledButton,l.partnerApprove);await t.ensureVisible(approve);await t.tap(approve);await t.pumpAndSettle();
  await t.enterText(find.byType(TextField),'Old account operation');await t.pumpAndSettle();
  a.userId='changed';a.events.add(null);await t.pumpAndSettle();
  await t.tap(find.widgetWithText(FilledButton,l.continueLabel));await t.pumpAndSettle();expect(r.calls,0);
  await t.pumpWidget(const SizedBox.shrink());await a.events.close();
 });
}
