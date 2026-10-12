import 'package:kaosure/features/kao_id/kyc/domain/entities/id_image.dart';

class NationalIdRecord {
  const NationalIdRecord({required this.id, required this.owner, required this.status,
    required this.paths, this.rejection, this.expiry});
  final String id;
  final String owner;
  final String status;
  final List<String> paths;
  final String? rejection;
  final DateTime? expiry;
  bool get canResubmit => status == 'rejected' || status == 'expired' || status == 'revoked' ||
      (status == 'approved' && expiry != null && !expiry!.isAfter(DateTime.now().add(const Duration(days: 30))));
  factory NationalIdRecord.fromJson(Map<String, dynamic> json) {
    final files = (json['document_files'] as List? ?? []).cast<Map<String, dynamic>>();
    final paths = files.map((f) => f['file_path'] as String).toList()..sort();
    return NationalIdRecord(id: json['id'] as String, owner: json['owner_id'] as String,
      status: json['status'] as String, paths: paths, rejection: json['rejected_reason'] as String?, expiry: DateTime.tryParse(json['expiry_date']?.toString() ?? ''));
  }
}

class NationalIdDraft {
  const NationalIdDraft({required this.id, required this.owner, required this.number,
    required this.fullName, required this.issued, required this.expiry,
    required this.front, required this.back, required this.addressLine,
    required this.subdistrict, required this.district, required this.province,
    required this.postalCode});
  final String id, owner, number, fullName;
  final String addressLine, subdistrict, district, province, postalCode;
  final DateTime issued;
  final DateTime? expiry;
  final IdImage front, back;
}
