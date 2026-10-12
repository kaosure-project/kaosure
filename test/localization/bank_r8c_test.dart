import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/providers/auth_provider.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/bank_account.dart';
import 'package:kaosure/features/kao_id/kyc/domain/repositories/bank_repository.dart';
import 'package:kaosure/features/kao_id/kyc/data/repositories/supabase_bank_repository.dart';
import 'package:kaosure/features/kao_id/kyc/data/models/bank_verification_model.dart';
import 'package:kaosure/features/kao_id/kyc/domain/failures/national_id_failure.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/id_image.dart';
import 'package:kaosure/features/kao_id/kyc/application/providers/id_image_picker_provider.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/bank/bank_verification_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'auth_localization_r2_test.dart' show TestAuthNotifier;
import 'national_id_r7a_test.dart' show imageBytes;
import 'residence_r8b_test.dart' show tap, enter;

class BankAuthFixture extends TestAuthNotifier {
  BankAuthFixture(super.ref);
  void clearSession() { state = const AsyncValue.data(null); }
}
class BankFixture implements BankRepository {
  List<BankRecord> records = [];
  bool failLoad = false, loseResponse = false;
  int previews = 0;
  final submitted = <BankDraft>[];
  @override
  Future<String> owner() async => 'test-user';
  @override
  Future<List<BankRecord>> list(String owner) async {
    if (failLoad) { throw const NationalIdFailure('load'); }
    return records;
  }
  @override
  Future<BankRecord> submit(BankDraft draft) async {
    submitted.add(draft);
    final record = BankRecord({'id': draft.id, 'status': 'pending',
      'bank_name': draft.bank, 'account_name': draft.name,
      'account_number': '•••• ${draft.number.substring(draft.number.length - 4)}',
      'evidence_path': 'test-user/bank-account/${draft.id}/evidence.jpg'});
    records = [record];
    if (loseResponse) { loseResponse = false; throw const NationalIdFailure('save'); }
    return record;
  }
  @override
  Future<Uint8List> preview(String owner, String path) async { previews++; return imageBytes(); }
}
Widget bankApp(BankFixture repo, String language) => ProviderScope(overrides: [
  authProvider.overrideWith((ref) => BankAuthFixture(ref)),
  bankRepositoryProvider.overrideWithValue(repo),
  nationalIdImagePickerProvider.overrideWithValue(() async => IdImage('test.jpg', imageBytes())),
], child: MaterialApp(locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: const BankVerificationPage()));
Future<void> fillBank(WidgetTester tester, {String number = '0012345678'}) async {
  await tap(tester, 'bank-add');
  await enter(tester, 'bank-name', 'Test Bank');
  await enter(tester, 'bank-holder', 'Élodie');
  await enter(tester, 'bank-number', number);
}
void main() {
  for (final language in ['th', 'en']) {
    testWidgets('Bank load failure does not offer submission: $language', (tester) async {
      await tester.pumpWidget(bankApp(BankFixture()..failLoad = true, language));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(BankVerificationPage)));
      expect(find.text(l.contactLoadFailed), findsOneWidget);
      expect(find.byKey(const ValueKey('bank-add')), findsNothing);
    });
    testWidgets('Bank evidence required; lost response retry and reopen: $language', (tester) async {
      final repo = BankFixture()..loseResponse = true;
      await tester.pumpWidget(bankApp(repo, language));
      await tester.pumpAndSettle();
      await fillBank(tester);
      await tap(tester, 'bank-submit');
      expect(repo.submitted, isEmpty);
      final l = AppLocalizations.of(tester.element(find.byType(BankVerificationPage)));
      expect(find.text(l.bankCompleteForm), findsOneWidget);
      await tap(tester, 'bank-pick', delta: -180);
      await tap(tester, 'bank-submit');
      expect(repo.submitted.length, 1);
      expect(find.text(l.idSaveFailed), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tap(tester, 'bank-submit');
      expect(repo.submitted.length, 2);
      expect(repo.submitted.first.id, repo.submitted.last.id);
      expect(repo.submitted.last.number, '0012345678');
      expect(repo.submitted.last.name, 'Élodie');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(bankApp(repo, language));
      await tester.pumpAndSettle();
      expect(find.text('•••• 5678'), findsOneWidget);
      expect(find.text('0012345678'), findsNothing);
      expect(find.text(l.kycPendingStatus), findsOneWidget);
      expect(find.byKey(const ValueKey('bank-add')), findsNothing);
      await tap(tester, 'bank-view-${repo.records.single.id}');
      expect(repo.previews, 1);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(LinearProgressIndicator, skipOffstage: false), findsNothing);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(l.back)));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.widget<OutlinedButton>(find.byKey(const ValueKey('bank-refresh'))).onPressed, isNotNull);

    });
    testWidgets('Sign-out hides open bank evidence and account data: $language', (tester) async {
      final repo = BankFixture()..records = [BankRecord({'id': 'pending', 'status': 'pending',
        'bank_name': 'Test Bank', 'account_name': 'Example', 'account_number': '•••• 5678',
        'evidence_path': 'test-user/bank-account/pending/evidence.jpg'})];
      await tester.pumpWidget(bankApp(repo, language));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(tester.element(find.byType(BankVerificationPage)));
      await tap(tester, 'bank-view-pending');
      expect(find.byType(Image), findsOneWidget);
      (container.read(authProvider.notifier) as BankAuthFixture).clearSession();
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.text('•••• 5678'), findsNothing);
    });
    testWidgets('Invalid bank number cannot submit: $language', (tester) async {
      final repo = BankFixture();
      await tester.pumpWidget(bankApp(repo, language));
      await tester.pumpAndSettle();
      await fillBank(tester, number: '123');
      await tap(tester, 'bank-pick');
      await tap(tester, 'bank-submit');
      expect(repo.submitted, isEmpty);
    });
    testWidgets('Rejected bank permits corrected submission on narrow screen: $language', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 740);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final repo = BankFixture()..records = [BankRecord({'id': 'old', 'bank_name': 'Test Bank',
        'account_name': 'Example', 'account_number': '0012345678', 'status': 'rejected'})];
      await tester.pumpWidget(bankApp(repo, language));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(BankVerificationPage)));
      expect(find.text(l.kycRejectedStatus), findsOneWidget);
      await tap(tester, 'bank-add');
      for (var i = 0; i < 5; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
  test('Bank model preserves rejected, expired and unknown status', () {
    for (final status in ['rejected', 'expired', 'unknown', 'pending']) {
      final model = BankVerificationModel.fromJson({'id': 'id', 'profile_id': 'owner',
        'bank_name': 'Test', 'account_name': 'Example', 'account_number': '•••• 5678',
        'status': status, 'is_verified': false, 'name_match_status': 'pending',
        'created_at': '2026-01-01T00:00:00Z', 'updated_at': '2026-01-01T00:00:00Z'});
      expect(model.toEntity().status, status);
      expect(model.toEntity().isTrusted, isFalse);
    }
  });
}
