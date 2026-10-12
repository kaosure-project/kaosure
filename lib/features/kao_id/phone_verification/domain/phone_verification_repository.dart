class PhoneIdentity {
  const PhoneIdentity(this.userId, this.phone, this.confirmed);
  final String userId;
  final String phone;
  final bool confirmed;
}

abstract interface class PhoneVerificationRepository {
  Future<PhoneIdentity> current();
  Future<void> send(String phone);
  Future<void> resend(String phone);
  Future<void> verify(String phone, String token);
}

/// Thai local mobile input or an explicit international number.
String? normalizePhone(String input) {
  var value = input.trim().replaceAll(RegExp(r'[\s()\-]'), '');
  if (RegExp(r'^0[689][0-9]{8}$').hasMatch(value)) {
    value = '+66${value.substring(1)}';
  }
  return RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(value) ? value : null;
}
