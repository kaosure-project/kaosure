import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/business/application/controllers/business_registration_controller.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_registration.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_registration_step.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/payout_bank_account.dart';
import 'package:kaosure/features/kao_id/business/domain/failures/business_registration_failure.dart';
import 'package:kaosure/features/kao_id/business/domain/usecases/business_registration_use_cases.dart';

import 'business_registration_fakes.dart';

void main() {
  late FakeBusinessRegistrationRepository repository;
  late PayoutBankAccount bank;

  BusinessRegistrationController build() => BusinessRegistrationController(
        useCases: BusinessRegistrationUseCases(repository),
        readPayoutBank: () async => bank,
      );

  Future<void> saveDetails(BusinessRegistrationController controller) =>
      controller.saveDetails(
        businessType: 'registered_business',
        businessName: '  Kao Shop ',
        registrationNumber: '0105561234567',
        businessCategory: 'retail',
        businessDescription: '   ',
      );

  setUp(() {
    repository = FakeBusinessRegistrationRepository();
    bank = pendingBank;
  });

  test('walks all four steps and only submits once the bank is approved', () async {
    final controller = build();
    await controller.load();
    expect(controller.state.step, BusinessRegistrationStep.details);
    expect(controller.state.registration, isNull);

    await saveDetails(controller);
    expect(repository.calls, contains('createDraft'));
    expect(controller.state.registration!.businessName, 'Kao Shop');
    expect(controller.state.registration!.businessDescription, isNull);
    expect(controller.state.step, BusinessRegistrationStep.document);

    controller.next();
    expect(controller.state.step, BusinessRegistrationStep.document);
    expect(controller.state.failure, BusinessRegistrationFailureCode.documentRequired);

    expect(await controller.uploadDocument(pdfFile()), isTrue);
    expect(controller.state.documentComplete, isTrue);
    expect(controller.state.documentName, 'certificate.pdf');
    controller.next();
    expect(controller.state.step, BusinessRegistrationStep.bankAccount);

    controller.next();
    expect(controller.state.step, BusinessRegistrationStep.bankAccount);
    expect(controller.state.failure, BusinessRegistrationFailureCode.bankRequired);
    expect(await controller.submit(), isFalse);
    expect(repository.calls, isNot(contains('submit')));

    bank = approvedBank;
    await controller.refreshBank();
    controller.next();
    expect(controller.state.step, BusinessRegistrationStep.review);

    expect(await controller.submit(), isTrue);
    expect(controller.state.showsStatus, isTrue);
    expect(controller.state.registration!.status, BusinessRegistrationStatus.submitted);
  });

  test('second save updates the existing draft instead of creating another', () async {
    final controller = build();
    await controller.load();
    await saveDetails(controller);
    controller.back();
    await saveDetails(controller);
    expect(repository.calls.where((c) => c == 'createDraft'), hasLength(1));
    expect(repository.calls, contains('updateDraft'));
  });

  test('resumes a draft at the first incomplete step', () async {
    repository.current = draft();
    final noDocument = build();
    await noDocument.load();
    expect(noDocument.state.step, BusinessRegistrationStep.document);

    repository.current = draft(documentId: 'doc-1');
    final noBank = build();
    await noBank.load();
    expect(noBank.state.step, BusinessRegistrationStep.bankAccount);

    bank = approvedBank;
    final ready = build();
    await ready.load();
    expect(ready.state.step, BusinessRegistrationStep.review);
  });

  test('a cancelled draft is not shown as a rejected application', () async {
    repository.current = draft(status: BusinessRegistrationStatus.rejected);
    final controller = build();
    await controller.load();
    expect(controller.state.registration, isNull);
    expect(controller.state.showsStatus, isFalse);

    repository.current = draft(
      status: BusinessRegistrationStatus.rejected,
      submittedAt: DateTime(2026, 10, 1),
    );
    final reviewed = build();
    await reviewed.load();
    expect(reviewed.state.showsStatus, isTrue);
  });

  test('steps that are not unlocked cannot be opened', () async {
    final controller = build();
    await controller.load();
    controller.goTo(BusinessRegistrationStep.review);
    expect(controller.state.step, BusinessRegistrationStep.details);
  });

  test('server failures surface as codes and leave the step unchanged', () async {
    final controller = build();
    await controller.load();
    repository.failNext = BusinessRegistrationFailureCode.duplicateRegistration;
    await saveDetails(controller);
    expect(controller.state.failure, BusinessRegistrationFailureCode.duplicateRegistration);
    expect(controller.state.step, BusinessRegistrationStep.details);
    expect(controller.state.isSaving, isFalse);

    controller.dismissFailure();
    expect(controller.state.failure, isNull);
  });

  test('saving without a session reports the session failure', () async {
    repository.userId = null;
    final controller = build();
    await controller.load();
    expect(await controller.saveDetails(
      businessType: 'organization',
      businessName: 'Kao Foundation',
      registrationNumber: 'ORG-1',
      businessCategory: 'other',
    ), isFalse);
    expect(controller.state.failure, BusinessRegistrationFailureCode.session);
    expect(repository.calls, isNot(contains('createDraft')));
  });

  test('cancel clears the draft but keeps the bank result', () async {
    repository.current = draft(documentId: 'doc-1');
    bank = approvedBank;
    final controller = build();
    await controller.load();
    expect(await controller.cancel(), isTrue);
    expect(controller.state.registration, isNull);
    expect(controller.state.step, BusinessRegistrationStep.details);
    expect(controller.state.bank, approvedBank);
  });
}
