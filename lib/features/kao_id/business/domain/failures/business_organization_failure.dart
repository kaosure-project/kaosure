enum BusinessOrganizationFailureCode {
  session,
  restricted,
  kaoIdRequired,
  roleRequired,
  businessKaoIdRequired,
  nameMismatch,
  reviewActive,
  duplicate,
  invalidBank,
  invalidEvidence,
  uploadFailed,
  conflict,
  unknown,
}

final class BusinessOrganizationFailure implements Exception {
  const BusinessOrganizationFailure(this.code);

  final BusinessOrganizationFailureCode code;

  @override
  String toString() => 'BusinessOrganizationFailure(${code.name})';
}
