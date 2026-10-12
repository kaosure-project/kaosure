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
          KaoIdSsoHandoff.validateReturnTo(
            rawReturnTo: value,
            appUrl: appUrl,
            allowedServicePaths: allowedPaths,
          ),
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
