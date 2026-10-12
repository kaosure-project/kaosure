import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Valid DOPA mod-11 personal number of a foreign resident.
const validAlienId = '6100000000009';

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 180, scrollable: find.byType(Scrollable).first);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

/// Opens a searchable picker, searches [query] and selects [value].
Future<void> choosePickerOption(WidgetTester tester, String fieldKey, String query, String value) async {
  final field = find.byKey(ValueKey(fieldKey));
  await _reveal(tester, field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(ValueKey('$fieldKey-search')), query);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('$fieldKey-option-$value')));
  await tester.pumpAndSettle();
}

/// Fills a Thai address group with a Bangkok address.
Future<void> fillThaiAddress(WidgetTester tester, String prefix) async {
  for (final (key, value) in const [('address_line', '99/1 Moo 4'), ('subdistrict', 'Khlong Tan'),
      ('district', 'Khlong Toei'), ('postal_code', '10110')]) {
    final field = find.byKey(ValueKey('$prefix-$key'));
    await _reveal(tester, field);
    await tester.enterText(field, value);
  }
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await choosePickerOption(tester, '$prefix-province', 'Bangkok', 'กรุงเทพมหานคร');
}
