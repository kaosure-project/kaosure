import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile_model.dart';
import 'profile_remote_datasource.dart';

final class ProfileRemoteDataSourceImpl
    implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._supabase);

  final SupabaseClient _supabase;

  static const _table = 'profiles';
  static const _bucket = 'avatars';

  @override
  Future<ProfileModel> getProfile({
    required String profileId,
  }) async {
    final json = await _supabase
        .from(_table)
        .select()
        .eq('id', profileId)
        .single();

    print('PROFILE JSON: $json');

    return ProfileModel.fromJson(json);
  }

  @override
  Future<void> createProfile({
    required ProfileModel profile,
  }) async {
    await _supabase
        .from(_table)
        .insert(profile.toJson());
  }

  @override
  Future<void> updateProfile({
    required ProfileModel profile,
  }) async {
    print('========== UPDATE PROFILE ==========');
print('avatar_url = ${profile.avatarUrl}');
print('displayName = ${profile.displayName}');
print('====================================');
    await _supabase
        .from(_table)
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  @override
  Future<void> deleteProfile({
    required String profileId,
  }) async {
    await _supabase
        .from(_table)
        .delete()
        .eq('id', profileId);
  }

  @override
  Future<bool> exists({
    required String profileId,
  }) async {
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
    // โหลด URL รูปเดิมจากฐานข้อมูล
    final profile = await _supabase
        .from(_table)
        .select('avatar_url')
        .eq('id', userId)
        .single();

    final String? oldAvatarUrl =
        profile['avatar_url'] as String?;

    // สร้างชื่อไฟล์ใหม่ทุกครั้ง
    final fileName =
        'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final path = '$userId/$fileName';

    // อัปโหลดรูปใหม่
    await _supabase.storage
        .from(_bucket)
        .uploadBinary(
          path,
          imageBytes,
        );

    // สร้าง URL ใหม่
    final avatarUrl = _supabase.storage
        .from(_bucket)
        .getPublicUrl(path);

    // อัปเดตฐานข้อมูล
    await _supabase
        .from(_table)
        .update({
          'avatar_url': avatarUrl,
        })
        .eq('id', userId);

    // ลบรูปเก่า (ถ้ามี)
    if (oldAvatarUrl != null &&
        oldAvatarUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(oldAvatarUrl);

        final objectPath = uri.pathSegments
            .skipWhile(
              (segment) => segment != 'avatars',
            )
            .skip(1)
            .join('/');

        if (objectPath.isNotEmpty) {
          await _supabase.storage
              .from(_bucket)
              .remove([
            objectPath,
          ]);
        }
      } catch (_) {
        // ถ้าลบไม่ได้ ไม่ให้กระทบการอัปโหลด
      }
    }

    return avatarUrl;
  }
}