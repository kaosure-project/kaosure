import '../../domain/entities/bank_verification.dart';
import '../../domain/entities/identity_card.dart';
import '../../domain/entities/passport.dart';
import '../../domain/entities/residence_permit.dart';
import '../../domain/entities/verification.dart';
import '../../domain/entities/verification_history.dart';
import '../../domain/entities/verification_request.dart';
import '../../domain/enums/verification_status.dart';
import '../../domain/repositories/kyc_repository.dart';

final class FakeKycRepository
    implements KycRepository {
  @override
  Future<Verification> getVerification() async {
    return Verification(
      id: 'verification-001',
      profileId: 'profile-001',
      accountLevel: 'registered',
      status:
          VerificationStatus.approved.value,
      emailVerified: true,
      phoneVerified: true,
      identityCardStatus:
          VerificationStatus.approved.value,
      passportStatus:
          VerificationStatus.notStarted.value,
      residencePermitStatus:
          VerificationStatus.approved.value,
      bankStatus:
          VerificationStatus.approved.value,
      identityExpiry:
          DateTime(2031, 3, 25),
      passportExpiry: null,
      residencePermitExpiry:
          DateTime(2029, 1, 15),
      identityScore: 75,
      lastVerifiedAt: DateTime.now(),
      lastReviewedBy: 'admin-001',
      rejectedReason: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<VerificationRequest?>
      getVerificationRequest() async {
    return null;
  }

  @override
  Future<void> submitVerificationRequest({
    required String documentId,
  }) async {}

  @override
  Future<IdentityCard?>
      getIdentityCard() async {
    return IdentityCard(
      id: 'identity-001',
      ownerId: 'profile-001',
      documentType: 'identity_card',
      cardNumber: '1234567890123',
      fullName: 'Kao ID User',
      countryCode: 'TH',
      status:
          VerificationStatus.approved.value,
      issuedDate:
          DateTime(2021, 3, 25),
      expiryDate:
          DateTime(2031, 3, 25),
      verificationMethod: 'manual',
      verifiedAt: DateTime.now(),
      verifiedBy: 'admin-001',
      rejectedReason: null,
      deletedAt: null,
      filePath:
          'profile-001/identity_card/identity_card.jpg',
      fileUrl:
          'https://example.com/identity_card.jpg',
      fileName: 'identity_card.jpg',
      fileSize: 245678,
      mimeType: 'image/jpeg',
      uploadedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Passport?> getPassport() async {
    return Passport(
      id: 'passport-001',
      ownerId: 'profile-001',
      documentType: 'passport',
      passportNumber: 'AA1234567',
      fullName: 'Kao ID User',
      countryCode: 'TH',
      status:
          VerificationStatus.notStarted.value,
      issuedDate:
          DateTime(2023, 1, 1),
      expiryDate:
          DateTime(2033, 1, 1),
      verificationMethod: null,
      verifiedAt: null,
      verifiedBy: null,
      rejectedReason: null,
      deletedAt: null,
      filePath: null,
      fileUrl: null,
      fileName: null,
      fileSize: null,
      mimeType: null,
      uploadedAt: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<ResidencePermit?>
      getResidencePermit() async {
    return ResidencePermit(
      id: 'residence-001',
      ownerId: 'profile-001',
      documentType:
          'residence_permit',
      permitNumber: 'RP-000001',
      fullName: 'Kao ID User',
      countryCode: 'JP',
      status:
          VerificationStatus.approved.value,
      issuedDate:
          DateTime(2024, 1, 1),
      expiryDate:
          DateTime(2029, 1, 15),
      verificationMethod: 'manual',
      verifiedAt: DateTime.now(),
      verifiedBy: 'admin-001',
      rejectedReason: null,
      deletedAt: null,
      filePath:
          'profile-001/residence_permit/residence.jpg',
      fileUrl:
          'https://example.com/residence.jpg',
      fileName: 'residence.jpg',
      fileSize: 234567,
      mimeType: 'image/jpeg',
      uploadedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<BankVerification?>
      getBankVerification() async {
    return BankVerification(
      id: 'bank-001',
      profileId: 'profile-001',
      bankCode: 'SCB',
      bankName: 'ธนาคารไทยพาณิชย์',
      accountName: 'Kao ID User',
      accountNumber: '123-4-56789-0',
      status:
          VerificationStatus.approved.value,
      verifiedAt: DateTime.now(),
      verifiedBy: 'admin-001',
      rejectedReason: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<VerificationHistory>>
      getVerificationHistory() async {
    return [
      VerificationHistory(
        id: 'history-001',
        verificationRequestId: 'request-001',
        action: 'approve',
        oldStatus: 'under_review',
        newStatus: 'approved',
        performedBy: 'admin-001',
        notes: 'Identity verification approved',
        createdAt: DateTime.now(),
      ),
      VerificationHistory(
        id: 'history-002',
        verificationRequestId: 'request-001',
        action: 'review',
        oldStatus: 'pending',
        newStatus: 'under_review',
        performedBy: 'admin-001',
        notes: null,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> submitIdentityCard(
    IdentityCard identityCard,
  ) async {}

  @override
  Future<void> submitPassport(
    Passport passport,
  ) async {}

  @override
  Future<void> submitResidencePermit(
    ResidencePermit residencePermit,
  ) async {}

  @override
  Future<void> submitBankVerification(
    BankVerification bankVerification,
  ) async {}
}