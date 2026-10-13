import 'dart:typed_data';

import '../entities/topup_request.dart';

/// `topup_*_r28`. The server checks the Kao ID, limits and slip; the app only
/// shows what it answers.
abstract class TopupRepository {
  Future<TopupInfo> info();

  Future<TopupRequest> create(double amount);

  /// Uploads [jpeg] to the member's request folder, then hands the request to staff.
  Future<TopupRequest> sendSlip(TopupRequest request, Uint8List jpeg);

  /// Only before a slip was sent.
  Future<TopupRequest> cancel(String id);

  /// Newest first, 20 per page.
  Future<List<TopupRequest>> history({DateTime? before});
}
