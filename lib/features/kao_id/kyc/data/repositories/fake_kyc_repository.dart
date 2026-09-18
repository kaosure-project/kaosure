import '../../domain/entities/bank_verification.dart';
import '../../domain/entities/kyc_identity_document.dart';
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
  Future<List<KycIdentityDocument>>
      getIdentityDocuments() async {
    return [
      KycIdentityDocument(
        id: 'identity-001',
        ownerId: 'profile-001',
        documentType: 'thai_national_id',
        documentNumber: '1234567890123',
        status: VerificationStatus.approved.value,
        issuedDate: DateTime(2021, 3, 25),
        expiryDate: DateTime(2031, 3, 25),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      KycIdentityDocument(
        id: 'passport-001',
        ownerId: 'profile-001',
        documentType: 'passport',
        documentNumber: 'AA1234567',
        status: VerificationStatus.notStarted.value,
        issuedDate: DateTime(2023, 1, 1),
        expiryDate: DateTime(2033, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      KycIdentityDocument(
        id: 'residence-001',
        ownerId: 'profile-001',
        documentType: 'residence_card',
        documentNumber: 'RP-000001',
        status: VerificationStatus.approved.value,
        issuedDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2029, 1, 15),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
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

}
