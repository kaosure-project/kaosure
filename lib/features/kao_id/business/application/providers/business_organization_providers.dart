import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../kyc/application/providers/id_image_picker_provider.dart';
import '../../data/providers/business_organization_repository_provider.dart';
import '../../domain/usecases/business_organization_use_cases.dart';
import '../controllers/business_organization_controller.dart';
import '../states/business_organization_state.dart';

/// Picks a bank book or statement photo and returns it as JPEG bytes.
typedef OrganizationEvidencePicker = Future<Uint8List?> Function();

final businessOrganizationUseCasesProvider = Provider<BusinessOrganizationUseCases>((ref) {
  return BusinessOrganizationUseCases(ref.watch(businessOrganizationRepositoryProvider));
});

final organizationEvidencePickerProvider = Provider<OrganizationEvidencePicker>((ref) {
  final pick = ref.watch(nationalIdImagePickerProvider);
  return () async => (await pick())?.bytes;
});

final businessOrganizationControllerProvider =
    StateNotifierProvider.autoDispose<BusinessOrganizationController, BusinessOrganizationState>((ref) {
      return BusinessOrganizationController(
        useCases: ref.watch(businessOrganizationUseCasesProvider),
        newId: const Uuid().v4,
      )..load();
    });
