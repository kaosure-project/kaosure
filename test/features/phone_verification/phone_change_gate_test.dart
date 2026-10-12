import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaosure/features/kao_id/phone_verification/data/supabase_phone_verification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late List<String> calls;
  late int beginStatus;

  SupabaseClient client() => SupabaseClient(
        'https://example.supabase.co',
        'publishable-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          if (request.url.path.endsWith('/rpc/begin_phone_change_r19')) {
            expect(jsonDecode(request.body), {'p_phone': '+66899990000'});
            return http.Response(beginStatus == 200 ? '{"expires_at":"2026-10-12T10:00:00Z"}'
                : '{"code":"42501","message":"kao_id_only"}', beginStatus,
                headers: {'content-type': 'application/json'}, request: request);
          }
          return http.Response('{}', 200, headers: {'content-type': 'application/json'}, request: request);
        }),
      );

  setUp(() {
    calls = [];
    beginStatus = 200;
  });

  test('resending a phone OTP first tells Kao ID which number is being verified', () async {
    final supabase = client();
    await SupabasePhoneVerificationRepository(supabase).resend('+66899990000');
    expect(calls, ['POST /rest/v1/rpc/begin_phone_change_r19', 'POST /auth/v1/resend']);
    await supabase.dispose();
  });

  test('no OTP is requested when Kao ID refuses the phone change', () async {
    beginStatus = 403;
    final supabase = client();
    await expectLater(SupabasePhoneVerificationRepository(supabase).resend('+66899990000'),
        throwsA(isA<PostgrestException>()));
    expect(calls, ['POST /rest/v1/rpc/begin_phone_change_r19']);
    await supabase.dispose();
  });
}
