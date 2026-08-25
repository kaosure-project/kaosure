enum AccountRole {
  user('user'),
  admin('admin'),
  developer('developer'),
  support('support'),
  kycOfficer('kyc_officer');

  const AccountRole(this.value);

  final String value;

  static AccountRole fromValue(
    String value,
  ) {
    return AccountRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => AccountRole.user,
    );
  }
}