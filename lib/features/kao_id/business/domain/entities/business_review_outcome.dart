enum BusinessReviewOutcome {
  approved,
  rejected,

  /// Two-person review is on and the decision waits for another reviewer.
  awaitingSecond,
}
