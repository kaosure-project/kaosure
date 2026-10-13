import 'dart:typed_data';

abstract interface class BusinessOrganizationRemoteDataSource {
  String? currentUserId();

  Future<List<Map<String, dynamic>>> myOrganizations();

  Future<void> uploadEvidence({required String path, required Uint8List bytes});

  /// The stored object at [path], or null when it cannot be read.
  Future<Uint8List?> downloadEvidence(String path);

  Future<void> submitBank({
    required String organizationId,
    required String id,
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String branch,
    required String type,
    required String evidencePath,
  });
}
