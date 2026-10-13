/// Client-side copies of the server rules in `kaoid_private.business_fields_r27c`.
abstract final class BusinessRegistrationRules {
  static final _legalNameEn = RegExp(r"^[A-Za-z0-9][A-Za-z0-9 .,&()'/-]*$");

  /// 13-digit Thai juristic number with the standard check digit.
  static bool isValidJuristicNumber(String value) {
    final text = value.trim();
    if (!RegExp(r'^\d{13}$').hasMatch(text)) return false;
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(text[i]) * (13 - i);
    }
    return (11 - sum % 11) % 10 == int.parse(text[12]);
  }

  static bool isValidLegalNameEn(String value) {
    final text = value.trim();
    return text.isEmpty || (text.length >= 2 && text.length <= 200 && _legalNameEn.hasMatch(text));
  }

  /// The oldest certificate issue date accepted on [today].
  static DateTime oldestCertificateDate(DateTime today) {
    final month = today.month - 6;
    final year = today.year + (month <= 0 ? -1 : 0);
    final targetMonth = month <= 0 ? month + 12 : month;
    final lastDay = DateTime(year, targetMonth + 1, 0).day;
    return DateTime(year, targetMonth, today.day > lastDay ? lastDay : today.day);
  }

  static bool isCertificateDateAccepted(DateTime issuedOn, DateTime today) {
    final day = DateTime(issuedOn.year, issuedOn.month, issuedOn.day);
    final current = DateTime(today.year, today.month, today.day);
    return !day.isAfter(current) && !day.isBefore(oldestCertificateDate(current));
  }
}
