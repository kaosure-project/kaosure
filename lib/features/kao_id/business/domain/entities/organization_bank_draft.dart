import 'dart:typed_data';

enum OrganizationBankAccountType { savings, current }

/// A company bank account about to be sent for review; [id] stays the same across retries.
class OrganizationBankDraft {
  const OrganizationBankDraft({
    required this.id,
    required this.organizationId,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.branch,
    required this.type,
    required this.evidenceJpeg,
  });

  final String id;
  final String organizationId;
  final String bankName;

  /// Must match the company's Thai or English legal name.
  final String accountName;
  final String accountNumber;
  final String branch;
  final OrganizationBankAccountType type;

  /// Bank book or statement photo, re-encoded as JPEG.
  final Uint8List evidenceJpeg;
}
