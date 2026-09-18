import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/supabase_kyc_remote_datasource.dart';
import '../../data/repositories/supabase_kyc_repository.dart';

import '../../domain/repositories/kyc_repository.dart';

import '../../domain/usecases/get_bank_verification_usecase.dart';
import '../../domain/usecases/get_kyc_identity_documents_usecase.dart';
import '../../domain/usecases/get_verification_history_usecase.dart';
import '../../domain/usecases/get_verification_request_usecase.dart';
import '../../domain/usecases/get_verification_usecase.dart';
import '../../domain/usecases/submit_bank_verification_usecase.dart';
import '../../domain/usecases/submit_verification_request_usecase.dart';

import '../controllers/kyc_controller.dart';
import '../states/kyc_state.dart';
final supabaseClientProvider =
    Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final kycRemoteDataSourceProvider =
    Provider<SupabaseKycRemoteDataSource>(
  (ref) => SupabaseKycRemoteDataSource(
    ref.watch(
      supabaseClientProvider,
    ),
  ),
);

final kycRepositoryProvider =
    Provider<KycRepository>(
  (ref) => SupabaseKycRepository(
    ref.watch(
      kycRemoteDataSourceProvider,
    ),
  ),
);

final getVerificationUseCaseProvider =
    Provider<GetVerificationUseCase>(
  (ref) => GetVerificationUseCase(
    ref.watch(
      kycRepositoryProvider,
    ),
  ),
);

final getVerificationRequestUseCaseProvider =
    Provider<GetVerificationRequestUseCase>(
  (ref) => GetVerificationRequestUseCase(
    ref.watch(
      kycRepositoryProvider,
    ),
  ),
);

final getIdentityDocumentsUseCaseProvider =
    Provider<GetKycIdentityDocumentsUseCase>(
  (ref) => GetKycIdentityDocumentsUseCase(
    ref.watch(
      kycRepositoryProvider,
    ),
  ),
);

final getBankVerificationUseCaseProvider =
    Provider<GetBankVerificationUseCase>(
  (ref) => GetBankVerificationUseCase(
    ref.watch(
      kycRepositoryProvider,
    ),
  ),
);

final submitBankVerificationUseCaseProvider =
    Provider<SubmitBankVerificationUseCase>(
  (ref) => SubmitBankVerificationUseCase(
    ref.watch(
      kycRepositoryProvider,
    ),
  ),
);

final getVerificationHistoryUseCaseProvider =
    Provider<GetVerificationHistoryUseCase>(
  (ref) => GetVerificationHistoryUseCase(
    ref.watch(
      kycRepositoryProvider,
    ),
  ),
);

final submitVerificationRequestUseCaseProvider =
    Provider<SubmitVerificationRequestUseCase>(
  (ref) => SubmitVerificationRequestUseCase(
    ref.watch(
      kycRepositoryProvider,
    ),
  ),
);

final kycControllerProvider =
    StateNotifierProvider<
        KycController,
        KycState>(
  (ref) {
    return KycController(
      getVerificationUseCase:
          ref.watch(
        getVerificationUseCaseProvider,
      ),
      getIdentityDocumentsUseCase:
          ref.watch(
        getIdentityDocumentsUseCaseProvider,
      ),
      getBankVerificationUseCase:
          ref.watch(
        getBankVerificationUseCaseProvider,
      ),
      submitBankVerificationUseCase:
          ref.watch(
        submitBankVerificationUseCaseProvider,
      ),
      getVerificationHistoryUseCase:
          ref.watch(
        getVerificationHistoryUseCaseProvider,
      ),
      getVerificationRequestUseCase:
          ref.watch(
        getVerificationRequestUseCaseProvider,
      ),
      submitVerificationRequestUseCase:
          ref.watch(
        submitVerificationRequestUseCaseProvider,
      ),
    );
  },
);