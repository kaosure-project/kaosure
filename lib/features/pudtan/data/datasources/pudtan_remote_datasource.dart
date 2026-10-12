import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pudtan_response.dart';

class PudtanRemoteDataSource {
  PudtanRemoteDataSource();

  static const String baseUrl = String.fromEnvironment(
    'PUDTAN_API_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );
  static const String askPath = '/api/v1/pudtan/ask';

  Future<PudtanResponse> ask({
    required String projectId,
    required String query,
    int limit = 10,
  }) async {
    final accessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;

    if (accessToken == null) {
      throw StateError('Kao ID sign-in is required to talk to Pudtan.');
    }

    final uri = Uri.parse('$baseUrl$askPath');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'project_id': projectId,
        'query': query,
        'limit': limit,
      }),
    );

    final responseBody = response.body;

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Pudtan API returned HTTP ${response.statusCode}: '
        '$responseBody',
      );
    }

    final decoded = jsonDecode(responseBody);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid Pudtan API response',
      );
    }

    return PudtanResponse.fromJson(decoded);
  }
}
