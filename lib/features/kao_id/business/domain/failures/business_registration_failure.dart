enum BusinessRegistrationFailureCode {
  session,
  restricted,
  activeExists,
  notEditable,
  documentRequired,
  bankRequired,
  invalidFile,
  duplicateRegistration,
  unknown,
}

final class BusinessRegistrationFailure implements Exception {
  const BusinessRegistrationFailure(this.code);

  final BusinessRegistrationFailureCode code;

  @override
  String toString() => 'BusinessRegistrationFailure(${code.name})';
}
