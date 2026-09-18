enum VerificationStatus {
  notStarted('not_started'),
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  expired('expired');

  const VerificationStatus(
    this.value,
  );

  final String value;

  static VerificationStatus fromValue(
    String value,
  ) {
    return VerificationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => VerificationStatus.notStarted,
    );
  }
}