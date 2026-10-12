import 'package:kaosure/l10n/app_localizations.dart';

import '../../domain/entities/business_registration_step.dart';
import '../../domain/entities/business_type.dart';
import '../../domain/failures/business_registration_failure.dart';

extension BusinessRegistrationTexts on AppLocalizations {
  String businessStepLabel(BusinessRegistrationStep step) => switch (step) {
        BusinessRegistrationStep.details => businessRegStepDetails,
        BusinessRegistrationStep.document => businessRegStepDocument,
        BusinessRegistrationStep.bankAccount => businessRegStepBank,
        BusinessRegistrationStep.review => businessRegStepReview,
      };

  String businessTypeLabel(String type) => type == BusinessType.organization
      ? businessRegTypeOrganization
      : businessRegTypeCompany;

  String businessCategoryLabel(String category) => switch (category) {
        BusinessCategory.retail => businessRegCategoryRetail,
        BusinessCategory.food => businessRegCategoryFood,
        BusinessCategory.services => businessRegCategoryServices,
        BusinessCategory.technology => businessRegCategoryTechnology,
        BusinessCategory.other => businessRegCategoryOther,
        _ => category,
      };

  String businessFailureMessage(BusinessRegistrationFailureCode code) => switch (code) {
        BusinessRegistrationFailureCode.session => businessRegErrorSession,
        BusinessRegistrationFailureCode.restricted => businessRegErrorRestricted,
        BusinessRegistrationFailureCode.activeExists => businessRegErrorActiveExists,
        BusinessRegistrationFailureCode.notEditable => businessRegErrorNotEditable,
        BusinessRegistrationFailureCode.documentRequired => businessRegErrorDocumentRequired,
        BusinessRegistrationFailureCode.bankRequired => businessRegErrorBankRequired,
        BusinessRegistrationFailureCode.invalidFile => businessRegErrorFile,
        BusinessRegistrationFailureCode.duplicateRegistration => businessRegErrorDuplicate,
        BusinessRegistrationFailureCode.unknown => businessRegErrorGeneric,
      };
}
