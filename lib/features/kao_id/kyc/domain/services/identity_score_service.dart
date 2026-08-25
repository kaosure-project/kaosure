import '../entities/verification.dart';
import '../enums/verification_status.dart';

final class IdentityScoreService {
  const IdentityScoreService._();

  static int calculate(
    Verification verification,
  ) {
    int score = 0;

    // Email
    if (verification.emailVerified) {
      score += 15;
    }

    // Phone
    if (verification.phoneVerified) {
      score += 15;
    }

    // Identity Card
    if (VerificationStatus.fromValue(
          verification.identityCardStatus,
        ) ==
        VerificationStatus.approved) {
      score += 30;
    }

    // Bank
    if (VerificationStatus.fromValue(
          verification.bankStatus,
        ) ==
        VerificationStatus.approved) {
      score += 30;
    }

    // Passport หรือ Residence Permit
    final passportApproved =
        VerificationStatus.fromValue(
              verification.passportStatus,
            ) ==
            VerificationStatus.approved;

    final residenceApproved =
        VerificationStatus.fromValue(
              verification.residencePermitStatus,
            ) ==
            VerificationStatus.approved;

    if (passportApproved || residenceApproved) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  static bool isComplete(
    Verification verification,
  ) {
    return calculate(verification) == 100;
  }

  static bool isHighTrust(
    Verification verification,
  ) {
    return calculate(verification) >= 80;
  }
}