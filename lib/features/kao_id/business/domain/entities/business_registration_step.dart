enum BusinessRegistrationStep {
  details,
  document,
  bankAccount,
  review;

  int get number => index + 1;

  BusinessRegistrationStep? get previous =>
      index == 0 ? null : BusinessRegistrationStep.values[index - 1];
}
