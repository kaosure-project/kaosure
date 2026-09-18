import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/business_registration_repository_provider.dart';
import '../../domain/usecases/business_registration_use_cases.dart';
import '../controllers/business_registration_controller.dart';
import '../states/business_registration_state.dart';

final businessRegistrationUseCasesProvider =
    Provider<BusinessRegistrationUseCases>((ref) {
  return BusinessRegistrationUseCases(
    ref.watch(businessRegistrationRepositoryProvider),
  );
});

final businessRegistrationDependenciesProvider =
    Provider<BusinessRegistrationDependencies>((ref) {
  final useCases = ref.watch(
    businessRegistrationUseCasesProvider,
  );

  return BusinessRegistrationDependencies(
    loadCurrentRegistration: useCases.getCurrent,
    saveDraft: useCases.createDraft,
    updateDraft: useCases.updateDraft,
    attachDocument: (registrationId) async {
      // Document upload ยังต้องรับไฟล์จาก UI
      // ก่อนจึงจะสามารถเรียก attachDocument(registrationId, documentId)
      // ได้อย่างถูกต้อง
      return null;
    },
    submitRegistration: useCases.submit,
    cancelRegistration: useCases.cancelDraft,
  );
});

final businessRegistrationControllerProvider =
    StateNotifierProvider<
        BusinessRegistrationController,
        BusinessRegistrationState>(
  (ref) {
    final dependencies = ref.watch(
      businessRegistrationDependenciesProvider,
    );

    return BusinessRegistrationController(
      loadCurrentRegistration:
          dependencies.loadCurrentRegistration,
      saveDraft: dependencies.saveDraft,
      updateDraft: dependencies.updateDraft,
      attachDocument: dependencies.attachDocument,
      submitRegistration: dependencies.submitRegistration,
      cancelRegistration: dependencies.cancelRegistration,
    );
  },
);

final class BusinessRegistrationDependencies {
  const BusinessRegistrationDependencies({
    required this.loadCurrentRegistration,
    required this.saveDraft,
    required this.updateDraft,
    required this.attachDocument,
    required this.submitRegistration,
    required this.cancelRegistration,
  });

  final LoadCurrentBusinessRegistration loadCurrentRegistration;
  final SaveBusinessRegistration saveDraft;
  final UpdateBusinessRegistration updateDraft;
  final AttachBusinessDocument attachDocument;
  final SubmitBusinessRegistration submitRegistration;
  final CancelBusinessRegistration cancelRegistration;
}