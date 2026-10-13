import '../entities/business_organization.dart';
import '../entities/organization_bank_draft.dart';
import '../repositories/business_organization_repository.dart';

final class BusinessOrganizationUseCases {
  const BusinessOrganizationUseCases(this._repository);

  final BusinessOrganizationRepository _repository;

  String? currentUserId() => _repository.currentUserId();

  Future<List<BusinessOrganization>> myOrganizations() => _repository.myOrganizations();

  Future<void> submitBank(OrganizationBankDraft draft) => _repository.submitBank(draft);
}
