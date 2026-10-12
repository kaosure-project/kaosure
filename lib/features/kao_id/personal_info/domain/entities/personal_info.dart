/// How far a piece of personal information has been verified.
enum VerificationMark {
  verified,
  pending,
  unverified,
  expired,
  rejected,
  revoked,
  none;

  static VerificationMark parse(Object? value) => switch (value) {
        'verified' => verified,
        'pending' => pending,
        'expired' => expired,
        'rejected' => rejected,
        'revoked' => revoked,
        'unverified' => unverified,
        _ => none,
      };
}

class VerifiedValue {
  const VerifiedValue(this.value, this.mark);

  /// Display value; masked for sensitive fields.
  final String? value;
  final VerificationMark mark;

  bool get isEmpty => value == null || value!.isEmpty;
}

class IdentityDocumentSummary {
  const IdentityDocumentSummary({required this.type, required this.maskedNumber,
    required this.mark, this.issuedDate, this.expiryDate, this.country});

  final String type;
  final String? maskedNumber;
  final VerificationMark mark;
  final DateTime? issuedDate;
  final DateTime? expiryDate;
  final String? country;
}

class IdAddress {
  const IdAddress({required this.line, required this.subdistrict, required this.district,
    required this.province, required this.postalCode, required this.mark});

  final String line;
  final String? subdistrict;
  final String? district;
  final String? province;
  final String? postalCode;
  final VerificationMark mark;
}

class PersonalInfo {
  const PersonalInfo({required this.name, required this.email, required this.phone,
    this.document, this.address});

  final VerifiedValue name;
  final VerifiedValue email;

  /// Masked phone number; the full number is only available through a reveal.
  final VerifiedValue phone;
  final IdentityDocumentSummary? document;
  final IdAddress? address;
}
