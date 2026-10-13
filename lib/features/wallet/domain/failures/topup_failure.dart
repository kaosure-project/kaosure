/// A top-up problem the member can act on. [code] is the server's error code,
/// or `slip_file` when the picked image can't be used.
class TopupFailure implements Exception {
  const TopupFailure(this.code);

  final String code;

  @override
  String toString() => 'TopupFailure($code)';
}
