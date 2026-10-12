import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/document_picker_service.dart';
import '../../../kyc/data/repositories/supabase_bank_repository.dart';
import '../../data/providers/business_registration_repository_provider.dart';
import '../../domain/entities/business_document_file.dart';
import '../../domain/usecases/business_registration_use_cases.dart';
import '../controllers/business_registration_controller.dart';
import '../services/payout_bank_reader.dart';
import '../states/business_registration_state.dart';

typedef BusinessDocumentPicker = Future<BusinessDocumentFile?> Function();

final businessRegistrationUseCasesProvider =
    Provider<BusinessRegistrationUseCases>((ref) {
  return BusinessRegistrationUseCases(
    ref.watch(businessRegistrationRepositoryProvider),
  );
});

final payoutBankReaderProvider = Provider<PayoutBankReader>((ref) {
  return kaoIdPayoutBankReader(ref.watch(bankRepositoryProvider));
});

final businessDocumentPickerProvider = Provider<BusinessDocumentPicker>((ref) {
  return () async {
    final picked = await const DocumentPickerService()
        .pickDocument(BusinessDocumentFile.allowedExtensions);
    if (picked == null) return null;
    return BusinessDocumentFile(
      name: picked.name,
      bytes: picked.bytes,
      extension: picked.extension,
    );
  };
});

final businessRegistrationControllerProvider = StateNotifierProvider.autoDispose<
    BusinessRegistrationController, BusinessRegistrationState>((ref) {
  return BusinessRegistrationController(
    useCases: ref.watch(businessRegistrationUseCasesProvider),
    readPayoutBank: ref.watch(payoutBankReaderProvider),
  )..load();
});
