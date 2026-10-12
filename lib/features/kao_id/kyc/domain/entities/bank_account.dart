import 'id_image.dart';

class BankDraft {
  const BankDraft({required this.id, required this.owner, required this.bank,
    required this.name, required this.number, required this.branch,
    required this.type, required this.evidence});
  final String id, owner, bank, name, number, branch, type;
  final IdImage evidence;
}

class BankRecord {
  BankRecord(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get status => data['status'] as String? ?? 'unknown';
  bool get pending => status == 'pending' || status == 'manual_review';
  String? get evidence => data['evidence_path'] as String?;
  // Mask again as defense in depth, including old fixture/API responses.
  String get maskedNumber {
    final number = data['account_number'] as String? ?? '';
    return number.length >= 4 ? '•••• ${number.substring(number.length - 4)}' : '••••';
  }
}
