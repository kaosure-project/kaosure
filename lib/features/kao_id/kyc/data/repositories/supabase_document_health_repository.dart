import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/features/kao_id/kyc/domain/repositories/document_health_repository.dart';

final documentHealthRepositoryProvider = Provider<DocumentHealthRepository>((ref) => SupabaseDocumentHealthRepository(ref));

class SupabaseDocumentHealthRepository implements DocumentHealthRepository {
  SupabaseDocumentHealthRepository(this.ref);
  final Ref ref;
  @override
  Future<Map<String, dynamic>> load(String? profile) async => Map<String, dynamic>.from(
    await ref.read(supabaseClientProvider).rpc('document_health_r11a', params: {'p_profile': profile}) as Map);
  @override
  Future<void> revoke(String document, String reason) async {
    await ref.read(supabaseClientProvider).rpc('revoke_document_r11a', params: {'p_document': document, 'p_reason': reason});
  }
}
