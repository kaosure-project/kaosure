import 'id_image.dart';
import 'thai_address.dart';
import 'thai_document_kind.dart';

/// A Thai government document held by a foreign resident (work permit,
/// residence certificate, pink card or Tor.Ror.13). Stored as `residence_card`.
class ResidenceDraft {
  const ResidenceDraft({required this.id, required this.owner, required this.kind, required this.number,
    required this.given, required this.family, required this.singleName,
    required this.familyFirst, required this.nationality, required this.format, required this.noExpiry,
    required this.issued, required this.expiry, required this.address, required this.front, this.back});
  final String id, owner, number, given, family, format;
  final ThaiDocumentKind kind;

  /// ISO 3166-1 alpha-3 code.
  final String nationality;
  final bool singleName, familyFirst, noExpiry;
  final DateTime issued;
  final DateTime? expiry;
  final ThaiAddress address;
  final IdImage front;
  final IdImage? back;
}

class ResidenceRecord {
  ResidenceRecord(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get status => data['status'] as String;
  String? get rejection => data['rejected_reason'] as String?;

  /// Null for residence documents sent before Thai document kinds existed.
  ThaiDocumentKind? get kind => ThaiDocumentKind.parse(data['thai_document_kind'] as String?);
  String? get nationality => data['nationality'] as String?;
  DateTime? get expiry => DateTime.tryParse(data['expiry_date']?.toString() ?? '');
  List<String> get paths => (data['document_files'] as List? ?? [])
      .map((f) => (f as Map<String, dynamic>)['file_path'] as String).toList();
  bool get canResubmit => status == 'rejected' || status == 'expired' || status == 'revoked' ||
      (status == 'approved' && expiry != null && !expiry!.isAfter(DateTime.now().add(const Duration(days: 30))));
}
