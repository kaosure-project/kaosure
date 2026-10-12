import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/supabase_provider.dart';
import '../../domain/repositories/app_client_registry_repository.dart';
import '../../domain/repositories/oauth_consent_repository.dart';
import '../repositories/supabase_app_client_registry_repository.dart';
import '../repositories/supabase_oauth_consent_repository.dart';

final oauthConsentRepositoryProvider = Provider<OAuthConsentRepository>((ref) {
  return SupabaseOAuthConsentRepository(ref.watch(supabaseClientProvider));
});

final appClientRegistryRepositoryProvider = Provider<AppClientRegistryRepository>((ref) {
  return SupabaseAppClientRegistryRepository(ref.watch(supabaseClientProvider));
});
