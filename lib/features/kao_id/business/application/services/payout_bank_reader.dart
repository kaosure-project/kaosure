import '../../../kyc/domain/entities/bank_account.dart';
import '../../../kyc/domain/repositories/bank_repository.dart';
import '../../domain/entities/payout_bank_account.dart';

typedef PayoutBankReader = Future<PayoutBankAccount> Function();

/// Reads the owner's Kao ID bank accounts and picks the one that decides
/// whether a business registration can be submitted.
PayoutBankReader kaoIdPayoutBankReader(BankRepository repository) => () async {
      final records = await repository.list(await repository.owner());
      BankRecord? first(bool Function(BankRecord record) test) {
        for (final record in records) {
          if (test(record)) return record;
        }
        return null;
      }

      final approved = first((r) => r.status == 'approved');
      final pending = first((r) => r.pending);
      final rejected = first((r) => r.status == 'rejected' || r.status == 'expired');
      final chosen = approved ?? pending ?? rejected;
      if (chosen == null) return PayoutBankAccount.none;
      return PayoutBankAccount(
        status: identical(chosen, approved)
            ? PayoutBankStatus.approved
            : identical(chosen, pending)
                ? PayoutBankStatus.pending
                : PayoutBankStatus.rejected,
        bankName: chosen.data['bank_name'] as String?,
        maskedNumber: chosen.maskedNumber,
      );
    };
