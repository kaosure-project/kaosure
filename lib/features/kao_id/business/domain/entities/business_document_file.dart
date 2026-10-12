import 'dart:typed_data';

final class BusinessDocumentFile {
  const BusinessDocumentFile({
    required this.name,
    required this.bytes,
    required this.extension,
  });

  static const maxBytes = 10 * 1024 * 1024;
  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  final String name;
  final Uint8List bytes;
  final String extension;

  String get storageExtension {
    final value = extension.toLowerCase();
    return value == 'jpeg' ? 'jpg' : value;
  }

  String get mimeType => switch (storageExtension) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        _ => 'image/jpeg',
      };

  /// The server only sees the declared MIME type, so the content signature is
  /// checked here before upload.
  bool get isAcceptable =>
      allowedExtensions.contains(extension.toLowerCase()) &&
      bytes.isNotEmpty &&
      bytes.length <= maxBytes &&
      _matchesSignature;

  bool get _matchesSignature => switch (storageExtension) {
        'pdf' => _startsWith(const [0x25, 0x50, 0x44, 0x46]),
        'png' => _startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
        'jpg' => _startsWith(const [0xFF, 0xD8, 0xFF]),
        _ => false,
      };

  bool _startsWith(List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }
}
