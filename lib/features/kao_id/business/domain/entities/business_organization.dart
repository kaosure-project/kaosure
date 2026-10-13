enum OrganizationBankStatus { pending, approved, rejected }

/// A company bank account (only the last four digits leave the server).
class OrganizationBank {
  const OrganizationBank({
    required this.id,
    required this.bankName,
    required this.accountName,
    required this.last4,
    required this.status,
    this.reason,
    this.submittedAt,
    this.verifiedAt,
  });

  final String id;
  final String bankName;
  final String accountName;
  final String last4;
  final OrganizationBankStatus status;

  /// Reviewer's note for a rejected account.
  final String? reason;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;

  bool get isPending => status == OrganizationBankStatus.pending;
}

/// A company the signed-in person belongs to, with its business Kao ID and bank state.
class BusinessOrganization {
  const BusinessOrganization({
    required this.organizationId,
    required this.name,
    required this.role,
    this.legalName,
    this.legalNameEn,
    this.registrationNumber,
    this.verificationStatus,
    this.businessKaoId,
    this.kaoIdStatus,
    this.canManageBank = false,
    this.bankVerified = false,
    this.banks = const [],
    this.shopName,
  });

  final String organizationId;
  final String name;
  final String role;
  final String? legalName;
  final String? legalNameEn;
  final String? registrationNumber;
  final String? verificationStatus;
  final String? businessKaoId;
  final String? kaoIdStatus;

  /// Owners, directors and authorized persons may submit the company bank account.
  final bool canManageBank;
  final bool bankVerified;

  /// Newest first, at most five.
  final List<OrganizationBank> banks;
  final String? shopName;

  bool get hasBusinessKaoId => businessKaoId != null && kaoIdStatus == 'active';

  bool get hasPendingBank => banks.any((bank) => bank.isPending);

  bool get canSubmitBank => canManageBank && hasBusinessKaoId && !hasPendingBank;
}
