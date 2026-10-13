import 'package:kaosure/l10n/app_localizations.dart';

import '../../domain/failures/business_organization_failure.dart';

extension BusinessOrganizationTexts on AppLocalizations {
  String businessOrgFailureMessage(BusinessOrganizationFailureCode code) => switch (code) {
    BusinessOrganizationFailureCode.session => businessRegErrorSession,
    BusinessOrganizationFailureCode.restricted => businessRegErrorRestricted,
    BusinessOrganizationFailureCode.kaoIdRequired => businessRegKaoIdRequiredBody,
    BusinessOrganizationFailureCode.roleRequired => businessOrgErrorRole,
    BusinessOrganizationFailureCode.businessKaoIdRequired => businessOrgErrorBusinessKaoId,
    BusinessOrganizationFailureCode.nameMismatch => businessOrgErrorNameMismatch,
    BusinessOrganizationFailureCode.reviewActive => bankPendingHelp,
    BusinessOrganizationFailureCode.duplicate => bankDuplicate,
    BusinessOrganizationFailureCode.invalidBank => bankErrorInvalid,
    BusinessOrganizationFailureCode.invalidEvidence => bankErrorEvidenceMissing,
    BusinessOrganizationFailureCode.uploadFailed => bankErrorUploadNetwork,
    BusinessOrganizationFailureCode.conflict => bankErrorConflict,
    BusinessOrganizationFailureCode.unknown => businessRegErrorGeneric,
  };

  String businessOrgRoleLabel(String role) => switch (role) {
    'owner' => businessOrgRoleOwner,
    'director' => businessOrgRoleDirector,
    'authorized_person' => businessOrgRoleAuthorized,
    'finance' => businessOrgRoleFinance,
    _ => businessOrgRoleMember,
  };
}
