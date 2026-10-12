import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/passport.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/thai_address.dart';
import 'package:kaosure/features/kao_id/kyc/domain/entities/thai_document_kind.dart';
import 'package:kaosure/features/kao_id/kyc/domain/reference/countries.dart';
import 'package:kaosure/features/kao_id/kyc/domain/reference/thai_provinces.dart';
import 'package:kaosure/features/kao_id/kyc/domain/validators/alien_id_number.dart';

void main() {
  test('13-digit personal number uses the DOPA mod-11 check digit', () {
    expect(isValidThaiPersonalNumber('6100000000009'), isTrue);
    expect(isValidThaiPersonalNumber('1101700230708'), isTrue);
    expect(isValidThaiPersonalNumber('6100000000001'), isFalse);
    expect(isValidThaiPersonalNumber('610000000000'), isFalse);
    expect(isValidThaiPersonalNumber('61000000000090'), isFalse);
    expect(isValidThaiPersonalNumber('610000000000a'), isFalse);
  });

  test('Thai address follows the server rules', () {
    const valid = ThaiAddress(line: '99/1 Moo 4', subdistrict: 'Khlong Tan', district: 'Khlong Toei',
      province: 'กรุงเทพมหานคร', postalCode: '10110');
    expect(valid.isValid, isTrue);
    const invalid = ThaiAddress(line: '9', subdistrict: 'K', district: '', province: 'Bangkok',
      postalCode: '01234');
    expect(invalid.invalidFields, ThaiAddressField.values.toSet());
  });

  test('Reference data: 77 unique provinces and ISO alpha-3 countries without Thailand', () {
    expect(thaiProvinces.length, 77);
    expect(thaiProvinces.map((p) => p.th).toSet().length, 77);
    expect(thaiProvinceByName('เชียงใหม่')?.en, 'Chiang Mai');
    final codes = countries.map((c) => c.code).toList();
    expect(codes.toSet().length, codes.length);
    expect(codes.every((c) => RegExp(r'^[A-Z]{3}$').hasMatch(c)), isTrue);
    expect(countryByCode('THA'), isNull);
    expect(countryByCode('JPN')?.name('th'), isNotEmpty);
    expect(countryByCode('JPN')?.name('vi'), 'Japan');
  });

  test('Passport numbers are normalized to upper-case letters and digits', () {
    expect(normalizePassportNumber(' aa 123 4567 '), 'AA1234567');
    expect(isValidPassportNumber('aa1234567'), isTrue);
    expect(isValidPassportNumber('A-12345'), isFalse);
    expect(isValidPassportNumber('A12'), isFalse);
  });

  test('Document kinds round-trip their database codes', () {
    for (final kind in ThaiDocumentKind.values) {
      expect(ThaiDocumentKind.parse(kind.code), kind);
    }
    expect(ThaiDocumentKind.parse('residence_card'), isNull);
  });
}
