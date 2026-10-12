import 'verification_history_model.dart';

/// Reconstruct only events whose occurrence and timestamp are recorded.
/// Current approval flags never create an approval event at submission time.
List<VerificationHistoryModel> verificationTimeline({
  required List<Map<String, dynamic>> logs,
  required List<Map<String, dynamic>> requests,
  required List<Map<String, dynamic>> banks,
  String? emailConfirmedAt,
  String? phoneConfirmedAt,
}) {
  final rows = logs.map(VerificationHistoryModel.fromJson).toList();
  void add(String id, String request, String action, String status, String at) {
    rows.add(VerificationHistoryModel(id: id, verificationRequestId: request,
      action: action, oldStatus: null, newStatus: status, performedBy: null,
      notes: null, createdAt: DateTime.parse(at)));
  }
  for (final request in requests) {
    final id = request['id'] as String;
    if (rows.any((row) => row.verificationRequestId == id &&
        (row.action == 'submit' || row.action == 'submitted'))) {
      continue;
    }
    final document = request['identity_documents'] as Map?;
    final type = document?['document_type'] as String? ?? 'document';
    add('request:$id', id, 'submit:$type', 'pending',
      request['created_at'] as String);
  }
  for (final bank in banks) {
    final id = bank['id'] as String;
    add('bank:$id', '', 'submit:bank', 'pending', bank['created_at'] as String);
    for (final event in bank['review_events'] as List? ?? []) {
      final e = Map<String, dynamic>.from(event as Map);
      final approved = e['action'] == 'kyc.bank.approve';
      rows.add(VerificationHistoryModel(id: 'bank-event:${e['id']}',
        verificationRequestId: '', action: approved ? 'approve:bank' : 'reject:bank',
        oldStatus: 'pending', newStatus: approved ? 'approved' : 'rejected',
        performedBy: null, notes: e['notes'] as String?,
        createdAt: DateTime.parse(e['created_at'] as String)));
    }
  }
  if (emailConfirmedAt != null) {
    add('auth:email:$emailConfirmedAt', '', 'email_confirmed', 'verified', emailConfirmedAt);
  }
  if (phoneConfirmedAt != null) {
    add('auth:phone:$phoneConfirmedAt', '', 'phone_confirmed', 'verified', phoneConfirmedAt);
  }
  rows.sort((a, b) {
    final order = b.createdAt.compareTo(a.createdAt);
    return order == 0 ? a.id.compareTo(b.id) : order;
  });
  return rows;
}
