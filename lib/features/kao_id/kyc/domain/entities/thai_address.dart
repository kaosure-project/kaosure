import '../reference/thai_provinces.dart';

enum ThaiAddressField { line, subdistrict, district, province, postalCode }

/// Address in Thailand split the way Thai government documents print it.
class ThaiAddress {
  const ThaiAddress({
    required this.line,
    required this.subdistrict,
    required this.district,
    required this.province,
    required this.postalCode,
  });

  /// House number, village, soi and road.
  final String line;

  /// Khwaeng / tambon.
  final String subdistrict;

  /// Khet / amphoe.
  final String district;

  /// Thai province name from [thaiProvinces].
  final String province;

  final String postalCode;

  /// Fields that the server would reject; empty when the address is complete.
  Set<ThaiAddressField> get invalidFields => {
        if (!_length(line, 3, 300)) ThaiAddressField.line,
        if (!_length(subdistrict, 2, 100)) ThaiAddressField.subdistrict,
        if (!_length(district, 2, 100)) ThaiAddressField.district,
        if (thaiProvinceByName(province.trim()) == null) ThaiAddressField.province,
        if (!RegExp(r'^[1-9]\d{4}$').hasMatch(postalCode.trim())) ThaiAddressField.postalCode,
      };

  bool get isValid => invalidFields.isEmpty;

  static bool _length(String value, int min, int max) {
    final length = value.trim().length;
    return length >= min && length <= max;
  }
}
