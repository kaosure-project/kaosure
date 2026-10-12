enum PayoutBankStatus { approved, pending, rejected, missing }

/// The owner's Kao ID bank account used for business payouts.
final class PayoutBankAccount {
  const PayoutBankAccount({
    required this.status,
    this.bankName,
    this.maskedNumber,
  });

  static const none = PayoutBankAccount(status: PayoutBankStatus.missing);

  final PayoutBankStatus status;
  final String? bankName;
  final String? maskedNumber;

  bool get isApproved => status == PayoutBankStatus.approved;
}
