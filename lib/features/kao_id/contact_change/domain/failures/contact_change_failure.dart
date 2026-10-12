
class ContactChangeFailure implements Exception {
  const ContactChangeFailure(this.code);
  final String code;
}
