import 'id_image.dart';

class ResidenceDraft {
  const ResidenceDraft({required this.id, required this.owner, required this.number,
    required this.given, required this.family, required this.singleName,
    required this.familyFirst, required this.country, required this.format, required this.noExpiry,
    required this.issued, required this.expiry, required this.front, this.back});
  final String id, owner, number, given, family, country, format;
  final bool singleName, familyFirst, noExpiry;
  final DateTime issued;
  final DateTime? expiry;
  final IdImage front;
  final IdImage? back;
}

class ResidenceRecord {
  ResidenceRecord(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get status => data['status'] as String;
  String? get rejection => data['rejected_reason'] as String?;
  DateTime? get expiry => DateTime.tryParse(data['expiry_date']?.toString() ?? '');
  List<String> get paths => (data['document_files'] as List? ?? [])
      .map((f) => (f as Map<String, dynamic>)['file_path'] as String).toList();
  bool get canResubmit => status == 'rejected' || status == 'expired' || status == 'revoked' ||
      (status == 'approved' && expiry != null && !expiry!.isAfter(DateTime.now().add(const Duration(days: 30))));
}
