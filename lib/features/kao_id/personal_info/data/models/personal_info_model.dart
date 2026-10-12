import '../../domain/entities/personal_info.dart';

abstract final class PersonalInfoModel {
  static PersonalInfo fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? map(Object? value) =>
        value is Map ? Map<String, dynamic>.from(value) : null;
    String? text(Object? value) {
      final s = value is String ? value.trim() : null;
      return s == null || s.isEmpty ? null : s;
    }
    VerifiedValue field(Object? value, {String key = 'value', String? Function(String)? guard}) {
      final m = map(value) ?? const {};
      final raw = text(m[key]);
      return VerifiedValue(raw == null || guard == null ? raw : guard(raw),
        VerificationMark.parse(m['status']));
    }

    final document = map(json['document']);
    final address = map(json['address']);
    return PersonalInfo(
      name: field(json['name']),
      email: field(json['email']),
      phone: field(json['phone'], key: 'masked', guard: ensureMasked),
      document: document == null ? null : IdentityDocumentSummary(
        type: text(document['type']) ?? 'unknown',
        maskedNumber: switch (text(document['masked_number'])) {
          final number? => ensureMasked(number),
          null => null,
        },
        mark: VerificationMark.parse(document['status']),
        issuedDate: DateTime.tryParse(document['issued_date'] as String? ?? ''),
        expiryDate: DateTime.tryParse(document['expiry_date'] as String? ?? ''),
        country: text(document['country']),
      ),
      address: address == null || text(address['line']) == null ? null : IdAddress(
        line: text(address['line'])!,
        subdistrict: text(address['subdistrict']),
        district: text(address['district']),
        province: text(address['province']),
        postalCode: text(address['postal_code']),
        mark: VerificationMark.parse(address['status']),
      ),
    );
  }

  /// Defence in depth: never display an unmasked value from the summary payload.
  static String ensureMasked(String value) {
    if (value.contains('X')) return value;
    final digits = value.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    if (digits.length <= 4) return 'X' * digits.length;
    return '${'X' * (digits.length - 4)}${digits.substring(digits.length - 4)}';
  }
}
