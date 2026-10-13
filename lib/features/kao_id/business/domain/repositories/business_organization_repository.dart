import '../entities/business_organization.dart';
import '../entities/organization_bank_draft.dart';

abstract interface class BusinessOrganizationRepository {
  String? currentUserId();

  Future<List<BusinessOrganization>> myOrganizations();

  /// Uploads the evidence privately and sends the company account for staff review.
  Future<void> submitBank(OrganizationBankDraft draft);
}
