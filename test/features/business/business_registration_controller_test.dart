import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/business/application/controllers/business_registration_controller.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_document_kind.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_registration.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_registration_step.dart';
import 'package:kaosure/features/kao_id/business/domain/failures/business_registration_failure.dart';
import 'package:kaosure/features/kao_id/business/domain/usecases/business_registration_use_cases.dart';

import 'business_registration_fakes.dart';

void main() {
  late FakeBusinessRegistrationRepository repository;
  late bool kaoIdActive;

  BusinessRegistrationController build() => BusinessRegistrationController(
    useCases: BusinessRegistrationUseCases(repository),
    readKaoId: () async => kaoIdActive,
  );

  Future<void> saveDetails(BusinessRegistrationController controller) => controller.saveDetails(
    businessType: 'registered_business',
    businessName: '  Kao Shop ',
    registrationNumber: validJuristicNumber,
    businessCategory: 'retail',
    certificateIssuedOn: DateTime(2026, 9, 1, 15, 30),
    legalNameEn: ' KAO SHOP CO., LTD. ',
    businessDescription: '   ',
  );

  setUp(() {
    repository = FakeBusinessRegistrationRepository();
    kaoIdActive = true;
  });

  test('walks all four steps and only submits after the director declaration', () async {
    final controller = build();
    await controller.load();
    expect(controller.state.needsKaoId, isFalse);
    expect(controller.state.step, BusinessRegistrationStep.details);
    expect(controller.state.registration, isNull);

    await saveDetails(controller);
    expect(repository.calls, contains('createDraft'));
    final saved = controller.state.registration!;
    expect(saved.businessName, 'Kao Shop');
    expect(saved.legalNameEn, 'KAO SHOP CO., LTD.');
    expect(saved.certificateIssuedOn, DateTime(2026, 9, 1));
    expect(saved.businessDescription, isNull);
    expect(controller.state.step, BusinessRegistrationStep.document);

    controller.next();
    expect(controller.state.step, BusinessRegistrationStep.document);
    expect(controller.state.failure, BusinessRegistrationFailureCode.documentRequired);

    expect(await controller.uploadDocument(pdfFile(), kind: BusinessDocumentKind.certificate), isTrue);
    expect(controller.state.documentComplete, isTrue);
    expect(controller.state.documentName, 'certificate.pdf');
    controller.next();
    expect(controller.state.step, BusinessRegistrationStep.authority);

    controller.next();
    expect(controller.state.step, BusinessRegistrationStep.authority);
    expect(controller.state.failure, BusinessRegistrationFailureCode.declarationRequired);
    expect(await controller.submit(), isFalse);
    expect(repository.calls.where((c) => c.startsWith('submit')), isEmpty);

    controller.setDirectorDeclared(true);
    controller.next();
    expect(controller.state.step, BusinessRegistrationStep.review);

    expect(await controller.submit(), isTrue);
    expect(repository.calls, contains('submit:true'));
    expect(controller.state.showsStatus, isTrue);
    expect(controller.state.registration!.status, BusinessRegistrationStatus.submitted);
  });

  test('the optional VAT document can be attached and removed', () async {
    repository.current = draft(documentId: 'doc-1');
    final controller = build();
    await controller.load();

    expect(await controller.uploadDocument(pdfFile('vat.pdf'), kind: BusinessDocumentKind.vat), isTrue);
    expect(repository.calls, contains('attachDocument:vat:vat.pdf'));
    expect(controller.state.registration!.hasVatDocument, isTrue);
    expect(controller.state.vatDocumentName, 'vat.pdf');
    expect(controller.state.registration!.documentId, 'doc-1');

    expect(await controller.removeVatDocument(), isTrue);
    expect(controller.state.registration!.hasVatDocument, isFalse);
    expect(controller.state.vatDocumentName, isNull);
  });

  test('a person without an active Kao ID sees the gate until verified', () async {
    kaoIdActive = false;
    final controller = build();
    await controller.load();
    expect(controller.state.needsKaoId, isTrue);

    kaoIdActive = true;
    await controller.refreshKaoId();
    expect(controller.state.needsKaoId, isFalse);
  });

  test('a KAO_ID_REQUIRED failure from the server turns the gate back on', () async {
    final controller = build();
    await controller.load();
    repository.failNext = BusinessRegistrationFailureCode.kaoIdRequired;
    await saveDetails(controller);
    expect(controller.state.failure, BusinessRegistrationFailureCode.kaoIdRequired);
    expect(controller.state.needsKaoId, isTrue);
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
    repository.current = draft(withCertificateDate: false);
    final noDate = build();
    await noDate.load();
    expect(noDate.state.step, BusinessRegistrationStep.details);

    repository.current = draft();
    final noDocument = build();
    await noDocument.load();
    expect(noDocument.state.step, BusinessRegistrationStep.document);

    repository.current = draft(documentId: 'doc-1');
    final ready = build();
    await ready.load();
    expect(ready.state.step, BusinessRegistrationStep.authority);
    expect(ready.state.canOpen(BusinessRegistrationStep.review), isFalse);
  });

  test('a cancelled draft is not shown as a rejected application', () async {
    repository.current = draft(status: BusinessRegistrationStatus.rejected);
    final controller = build();
    await controller.load();
    expect(controller.state.registration, isNull);
    expect(controller.state.showsStatus, isFalse);

    repository.current = draft(status: BusinessRegistrationStatus.rejected, submittedAt: DateTime(2026, 10, 1));
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
    repository.failNext = BusinessRegistrationFailureCode.certificateTooOld;
    await saveDetails(controller);
    expect(controller.state.failure, BusinessRegistrationFailureCode.certificateTooOld);
    expect(controller.state.step, BusinessRegistrationStep.details);
    expect(controller.state.isSaving, isFalse);

    controller.dismissFailure();
    expect(controller.state.failure, isNull);
  });

  test('saving without a session reports the session failure', () async {
    repository.userId = null;
    final controller = build();
    await controller.load();
    expect(
      await controller.saveDetails(
        businessType: 'organization',
        businessName: 'Kao Foundation',
        registrationNumber: validJuristicNumber,
        businessCategory: 'other',
        certificateIssuedOn: issuedOn,
      ),
      isFalse,
    );
    expect(controller.state.failure, BusinessRegistrationFailureCode.session);
    expect(repository.calls, isNot(contains('createDraft')));
  });

  test('cancel clears the draft but keeps the Kao ID result', () async {
    repository.current = draft(documentId: 'doc-1');
    final controller = build();
    await controller.load();
    expect(await controller.cancel(), isTrue);
    expect(controller.state.registration, isNull);
    expect(controller.state.step, BusinessRegistrationStep.details);
    expect(controller.state.kaoIdActive, isTrue);
  });
}
