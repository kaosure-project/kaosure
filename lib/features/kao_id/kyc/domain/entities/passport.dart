import 'id_image.dart';
import 'thai_address.dart';

final _passportNumber = RegExp(r'^[A-Z0-9]{5,20}$');

/// Passport numbers are stored upper-case without spaces.
String normalizePassportNumber(String value) => value.replaceAll(RegExp(r'\s'), '').toUpperCase();

bool isValidPassportNumber(String value) => _passportNumber.hasMatch(normalizePassportNumber(value));

class PassportDraft {
  const PassportDraft({required this.id, required this.owner, required this.number,
    required this.given, required this.family, required this.singleName,
    required this.familyFirst, required this.nationality, required this.birth,
    required this.issued, required this.expiry, required this.address, required this.image});
  final String id, owner, number, given, family;

  /// ISO 3166-1 alpha-3 code.
  final String nationality;
  final bool singleName, familyFirst;
  final DateTime birth, issued, expiry;
  final ThaiAddress address;
  final IdImage image;
}

class PassportRecord {
  PassportRecord(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get status => data['status'] as String;
  String? get rejection => data['rejected_reason'] as String?;
  String? get nationality => (data['nationality'] ?? data['issuing_country']) as String?;
  DateTime? get expiry => DateTime.tryParse(data['expiry_date']?.toString() ?? '');
  List<String> get paths => (data['document_files'] as List? ?? [])
      .map((f) => (f as Map<String, dynamic>)['file_path'] as String).toList();
  bool get canResubmit => status == 'rejected' || status == 'expired' || status == 'revoked' ||
      (status == 'approved' && expiry != null && !expiry!.isAfter(DateTime.now().add(const Duration(days: 30))));
}
