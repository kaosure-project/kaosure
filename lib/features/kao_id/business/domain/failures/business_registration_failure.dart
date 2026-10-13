enum BusinessRegistrationFailureCode {
  session,
  restricted,
  kaoIdRequired,
  activeExists,
  notEditable,
  documentRequired,
  invalidFile,
  duplicateRegistration,
  invalidName,
  invalidNumber,
  invalidNameEn,
  invalidCertificateDate,
  certificateTooOld,
  certificateDateRequired,
  declarationRequired,
  unknown,
}

final class BusinessRegistrationFailure implements Exception {
  const BusinessRegistrationFailure(this.code);

  final BusinessRegistrationFailureCode code;

  @override
  String toString() => 'BusinessRegistrationFailure(${code.name})';
}
