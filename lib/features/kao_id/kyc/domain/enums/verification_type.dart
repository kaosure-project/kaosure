enum VerificationType {
  email('email'),
  phone('phone'),
  identityCard('identity_card'),
  passport('passport'),
  residencePermit('residence_permit'),
  bank('bank');

  const VerificationType(this.value);

  final String value;

  static VerificationType fromValue(
    String value,
  ) {
    return VerificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => VerificationType.identityCard,
    );
  }
}