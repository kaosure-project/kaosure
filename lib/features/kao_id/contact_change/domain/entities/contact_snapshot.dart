import '../../../phone_verification/domain/phone_verification_repository.dart';

enum ContactKind { email, phone }

class ContactSnapshot {
  const ContactSnapshot(this.owner, this.value, this.confirmed, this.pending,
      {this.factorIds = const []});
  final String owner;
  final String value;
  final bool confirmed;
  final String pending;
  final List<String> factorIds;
}

String? normalizeContact(ContactKind kind, String input) {
  if (kind == ContactKind.phone) { return normalizePhone(input); }
  final value = input.trim();
  if (value.length > 254 || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
    return null;
  }
  return value.toLowerCase();
}
