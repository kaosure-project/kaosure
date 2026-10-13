import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'business_organization_remote_data_source.dart';

final class BusinessOrganizationRemoteDataSourceImpl implements BusinessOrganizationRemoteDataSource {
  BusinessOrganizationRemoteDataSourceImpl({required this._supabase});

  static const _bucket = 'identity-documents';

  final SupabaseClient _supabase;

  @override
  String? currentUserId() => _supabase.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> myOrganizations() async {
    final response = await _supabase.rpc('my_organizations_r27c');
    return [
      for (final row in response as List? ?? const [])
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  @override
  Future<void> uploadEvidence({required String path, required Uint8List bytes}) async {
    await _supabase.storage
        .from(_bucket)
        .uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false));
  }

  @override
  Future<Uint8List?> downloadEvidence(String path) async {
    try {
      return await _supabase.storage.from(_bucket).download(path);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> submitBank({
    required String organizationId,
    required String id,
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String branch,
    required String type,
    required String evidencePath,
  }) async {
    await _supabase.rpc(
      'submit_org_bank_r27c',
      params: {
        'p_organization_id': organizationId,
        'p_id': id,
        'p_bank': bankName,
        'p_name': accountName,
        'p_number': accountNumber,
        'p_branch': branch,
        'p_type': type,
        'p_evidence': evidencePath,
      },
    );
  }
}
