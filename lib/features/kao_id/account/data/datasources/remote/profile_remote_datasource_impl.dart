import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile_model.dart';
import 'profile_remote_datasource.dart';

final class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._supabase);

  final SupabaseClient _supabase;

  static const _table = 'profiles';
  static const _bucket = 'avatars';

  @override
  Future<ProfileModel> getProfile({required String profileId}) async {
    final json = await _supabase
        .from(_table)
        .select()
        .eq('id', profileId)
        .single();

    return ProfileModel.fromJson(json);
  }

  @override
  Future<void> createProfile({required ProfileModel profile}) async {
    await _supabase.from(_table).insert(profile.toJson());
  }

  @override
  Future<void> updateProfile({required ProfileModel profile}) async {
    final data = <String, dynamic>{
      'display_name': profile.displayName,
      'avatar_url': profile.avatarUrl,
      'bio': profile.bio,
      'language_code': profile.languageCode,
    };

    await _supabase.from(_table).update(data).eq('id', profile.id);
  }

  @override
  Future<void> deleteProfile({required String profileId}) async {
    await _supabase.from(_table).delete().eq('id', profileId);
  }

  @override
  Future<bool> exists({required String profileId}) async {
    final result = await _supabase
        .from(_table)
        .select('id')
        .eq('id', profileId)
        .maybeSingle();

    return result != null;
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
  }) async {
    final profile = await _supabase
        .from(_table)
        .select('avatar_url')
        .eq('id', userId)
        .single();

    final oldAvatarUrl = profile['avatar_url'] as String?;

    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final path = '$userId/$fileName';

    await _supabase.storage
        .from(_bucket)
        .uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(
            upsert: true,
            cacheControl: '0',
            contentType: 'image/jpeg',
          ),
        );

    final avatarUrl = _supabase.storage.from(_bucket).getPublicUrl(path);

    if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(oldAvatarUrl);

        final oldPath = uri.pathSegments
            .skipWhile((segment) => segment != _bucket)
            .skip(1)
            .join('/');

        if (oldPath.isNotEmpty) {
          await _supabase.storage.from(_bucket).remove([oldPath]);
        }
      } catch (_) {
        // ไม่ให้การลบรูปเก่าทำให้การอัปโหลดล้มเหลว
      }
    }

    return avatarUrl;
  }

  @override
  Future<bool> isUsernameAvailable({required String username}) async {
    final result = await _supabase
        .from(_table)
        .select('id')
        .eq('username', username)
        .maybeSingle();

    return result == null;
  }

  @override
  Future<void> setUsername({
    required String profileId,
    required String username,
  }) async {
    final existing = await _supabase
        .from(_table)
        .select('username')
        .eq('id', profileId)
        .maybeSingle();

    if (existing == null) {
      throw Exception('Profile not found.');
    }

    final currentUsername = existing['username'] as String?;

    if (currentUsername != null && currentUsername.trim().isNotEmpty) {
      throw Exception('Username has already been set and cannot be changed.');
    }

    final available = await isUsernameAvailable(username: username);

    if (!available) {
      throw Exception('Username นี้ถูกใช้งานแล้ว');
    }

    await _supabase
        .from(_table)
        .update({'username': username})
        .eq('id', profileId);
  }
}
