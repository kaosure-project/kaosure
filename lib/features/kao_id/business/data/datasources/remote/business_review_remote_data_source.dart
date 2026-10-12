import 'dart:typed_data';

abstract interface class BusinessReviewRemoteDataSource {
  String? currentUserId();

  Future<List<Map<String, dynamic>>> queue();

  Future<Uint8List> download(String path);

  Future<String> signedUrl(String path);

  /// Returns the server status: approved, rejected or awaiting_second.
  Future<String> decide({
    required String expectedUserId,
    required String registrationId,
    required bool approve,
    String? reason,
  });
}
