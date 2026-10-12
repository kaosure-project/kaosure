/// Personal data shown masked by default and revealed only after a password check.
enum SensitiveField {
  phone('phone'),
  idNumber('id_number');

  const SensitiveField(this.code);

  /// Field name understood by the reveal RPC.
  final String code;
}

/// Short-lived proof that the owner re-entered their password.
abstract class RevealGrant {
  DateTime get expiresAt;

  bool get isActive => DateTime.now().isBefore(expiresAt);
}

class PersonalInfoFailure implements Exception {
  const PersonalInfoFailure(this.code);

  /// One of: password, session, rate_limited, not_found, load, reveal.
  final String code;

  @override
  String toString() => 'PersonalInfoFailure($code)';
}
