enum BusinessRegistrationStep {
  details,
  document,
  authority,
  review;

  int get number => index + 1;

  BusinessRegistrationStep? get previous => index == 0 ? null : BusinessRegistrationStep.values[index - 1];
}
