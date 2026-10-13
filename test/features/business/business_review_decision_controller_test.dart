import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/business/application/controllers/business_review_decision_controller.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_review_item.dart';
import 'package:kaosure/features/kao_id/business/domain/entities/business_review_outcome.dart';
import 'package:kaosure/features/kao_id/business/domain/failures/business_review_failure.dart';

import 'business_review_fakes.dart';

void main() {
  late FakeBusinessReviewRepository repository;
  late List<Uri> opened;
  late bool openSucceeds;

  setUp(() {
    repository = FakeBusinessReviewRepository();
    opened = [];
    openSucceeds = true;
  });

  BusinessReviewDecisionController controllerFor(BusinessReviewItem item) => BusinessReviewDecisionController(
    repository: repository,
    openLink: (link) async {
      opened.add(link);
      return openSucceeds;
    },
    item: item,
    reviewerId: reviewerId,
  );

  test('approval needs every document viewed, the checklist and the director check', () async {
    final item = reviewItem(paths: const ['a.png', 'b.png'], vatPaths: const ['vat.png']);
    final controller = controllerFor(item);
    expect(controller.canApprove, isFalse);

    controller.setChecked(true);
    await controller.loadImage('a.png');
    await controller.loadImage('b.png');
    expect(controller.canApprove, isFalse);

    await controller.loadImage('vat.png');
    expect(controller.state.viewedPaths, {'a.png', 'b.png', 'vat.png'});
    expect(controller.allDocumentsViewed, isTrue);
    expect(controller.canApprove, isFalse);

    controller.setDirectorConfirmed(true);
    expect(controller.canApprove, isTrue);

    expect(await controller.decide(approve: true), BusinessReviewOutcome.approved);
    expect(repository.decisions.single.approve, isTrue);
    expect(repository.decisions.single.directorConfirmed, isTrue);
    expect(controller.state.outcome, BusinessReviewOutcome.approved);
  });

  for (final (label, item) in [
    ('a stale certificate', reviewItem(certificateFresh: false)),
    ('an invalid number', reviewItem(numberValid: false)),
    ('a number held by another company', reviewItem(numberTaken: true)),
  ]) {
    test('$label blocks approval but still allows rejection', () async {
      final controller = controllerFor(item);
      controller
        ..setChecked(true)
        ..setDirectorConfirmed(true);
      await controller.loadImage(item.documentPaths.single);
      expect(controller.approvable, isFalse);
      expect(controller.canApprove, isFalse);
      expect(controller.canReject, isTrue);
    });
  }

  test('approve is ignored while requirements are missing', () async {
    final controller = controllerFor(reviewItem());
    expect(await controller.decide(approve: true), isNull);
    expect(repository.decisions, isEmpty);
  });

  test('pdf opens through a signed link and counts as viewed', () async {
    final item = reviewItem(mime: 'application/pdf', paths: const ['doc.pdf']);
    final controller = controllerFor(item);
    await controller.openExternally('doc.pdf');
    expect(opened.single.path, endsWith('doc.pdf'));
    expect(controller.state.viewedPaths, {'doc.pdf'});
  });

  test('a link the browser refuses is reported and not marked viewed', () async {
    openSucceeds = false;
    final controller = controllerFor(reviewItem(mime: 'application/pdf', paths: const ['doc.pdf']));
    await controller.openExternally('doc.pdf');
    expect(controller.state.failure, BusinessReviewFailureCode.documentUnavailable);
    expect(controller.state.viewedPaths, isEmpty);
  });

  test('rejection requires a reason of at least 3 characters', () async {
    final controller = controllerFor(reviewItem());
    expect(await controller.decide(approve: false, reason: 'no'), isNull);
    expect(controller.state.failure, BusinessReviewFailureCode.reasonRequired);
    expect(repository.decisions, isEmpty);

    repository.outcome = BusinessReviewOutcome.rejected;
    expect(await controller.decide(approve: false, reason: 'Document is blurry'), BusinessReviewOutcome.rejected);
    expect(controller.state.failure, isNull);
    expect(repository.decisions.single.directorConfirmed, isFalse);
  });

  test('server failures surface as codes and release the busy state', () async {
    final controller = controllerFor(reviewItem());
    repository.failNext = BusinessReviewFailureCode.ownerKaoIdRequired;
    expect(await controller.decide(approve: false, reason: 'Wrong company'), isNull);
    expect(controller.state.failure, BusinessReviewFailureCode.ownerKaoIdRequired);
    expect(controller.state.busy, isFalse);

    controller.dismissFailure();
    expect(controller.state.failure, isNull);
  });

  test('the first reviewer cannot cast the second vote', () async {
    final item = reviewItem(dualReview: true, firstReviewerId: reviewerId, firstDecisionApprove: true);
    final controller = controllerFor(item);
    controller.setChecked(true);
    await controller.loadImage(item.documentPaths.single);
    expect(controller.isOwnVote, isTrue);
    expect(controller.canApprove, isFalse);
    expect(controller.canReject, isFalse);
    expect(await controller.decide(approve: false, reason: 'Changed my mind'), isNull);
    expect(repository.decisions, isEmpty);
  });
}
