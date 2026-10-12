import 'package:kaosure/features/kao_id/contact_change/domain/entities/contact_snapshot.dart';

abstract interface class ContactChangeRepository {
  Future<ContactSnapshot> read(ContactKind kind);
  Future<void> request(ContactKind kind, String owner, String target,
      String password, {required bool resend, String? factorId, String? code});
  Future<void> verifyPhone(String owner, String target, String token);
}
