/// Thai government documents a foreign resident can verify with. All carry the
/// holder's 13-digit personal number.
enum ThaiDocumentKind {
  workPermit('work_permit', cardByDefault: true),
  residenceCertificate('residence_certificate', cardByDefault: false),
  pinkCard('pink_card', cardByDefault: true),
  houseRegistrationTr13('house_registration_tr13', cardByDefault: false);

  const ThaiDocumentKind(this.code, {required this.cardByDefault});

  final String code;

  /// Cards need a front and back image; books and paper certificates need one page.
  final bool cardByDefault;

  static ThaiDocumentKind? parse(String? code) {
    for (final kind in values) {
      if (kind.code == code) return kind;
    }
    return null;
  }
}
