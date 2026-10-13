import 'package:flutter_test/flutter_test.dart';
import 'package:kaosure/features/kao_id/auth/application/kao_id_sso_handoff.dart';

void main() {
  group('KaoIdSsoHandoff.validateReturnTo', () {
    const appUrl = 'https://kaosure.example';
    const allowedPaths = '/secondhand,/auction';

    test('allows a registered service path on the same origin', () {
      final result = KaoIdSsoHandoff.validateReturnTo(
        rawReturnTo: 'https://kaosure.example/secondhand/item/123',
        appUrl: appUrl,
        allowedServicePaths: allowedPaths,
      );

      expect(result?.path, '/secondhand/item/123');
    });

    test('allows another explicitly registered service path', () {
      final result = KaoIdSsoHandoff.validateReturnTo(
        rawReturnTo: 'https://kaosure.example/auction',
        appUrl: appUrl,
        allowedServicePaths: allowedPaths,
      );

      expect(result?.path, '/auction');
    });

    test('rejects another origin', () {
      expect(
        KaoIdSsoHandoff.validateReturnTo(
          rawReturnTo: 'https://attacker.example/secondhand',
          appUrl: appUrl,
          allowedServicePaths: allowedPaths,
        ),
        isNull,
      );
    });

    test('rejects unregistered paths and login loops', () {
      expect(
        KaoIdSsoHandoff.validateReturnTo(
          rawReturnTo: 'https://kaosure.example/login',
          appUrl: appUrl,
          allowedServicePaths: allowedPaths,
        ),
        isNull,
      );
      expect(
        KaoIdSsoHandoff.validateReturnTo(
          rawReturnTo: 'https://kaosure.example/secondhand-other',
          appUrl: appUrl,
          allowedServicePaths: allowedPaths,
        ),
        isNull,
      );
    });

    test('rejects query strings and fragments', () {
      for (final value in [
        'https://kaosure.example/secondhand?token=bad',
        'https://kaosure.example/secondhand#fragment',
      ]) {
        expect(
          KaoIdSsoHandoff.validateReturnTo(rawReturnTo: value, appUrl: appUrl, allowedServicePaths: allowedPaths),
          isNull,
        );
      }
    });

    test('allows a matching localhost origin for local proxy testing', () {
      final result = KaoIdSsoHandoff.validateReturnTo(
        rawReturnTo: 'http://localhost:7357/secondhand/',
        appUrl: 'http://localhost:7357/',
        allowedServicePaths: allowedPaths,
      );

      expect(result?.path, '/secondhand/');
    });

    test('a service launch counts only for the same member and only briefly', () {
      final at = DateTime(2026, 10, 13, 10);
      final raw = '{"uid":"member-a","at":${at.millisecondsSinceEpoch}}';
      bool recent(String raw, String? userId, Duration after) =>
          KaoIdSsoHandoff.isRecentServiceLaunch(raw, userId: userId, now: at.add(after));

      expect(recent(raw, 'member-a', const Duration(seconds: 30)), isTrue);
      expect(recent(raw, 'member-b', const Duration(seconds: 30)), isFalse);
      expect(recent(raw, null, const Duration(seconds: 30)), isFalse);
      expect(recent(raw, 'member-a', const Duration(minutes: 3)), isFalse);
      expect(recent(raw, 'member-a', const Duration(seconds: -5)), isFalse);
      expect(recent('not json', 'member-a', Duration.zero), isFalse);
    });

    test('rejects non-local insecure origins', () {
      expect(
        KaoIdSsoHandoff.validateReturnTo(
          rawReturnTo: 'http://kaosure.example/secondhand',
          appUrl: 'http://kaosure.example',
          allowedServicePaths: allowedPaths,
        ),
        isNull,
      );
    });
  });
}
