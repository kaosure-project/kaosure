import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile_model.dart';
import 'profile_remote_datasource.dart';

final class ProfileRemoteDataSourceImpl
    implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<ProfileModel> getProfile({
    required String profileId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> createProfile({
    required ProfileModel profile,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProfile({
    required ProfileModel profile,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProfile({
    required String profileId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> exists({
    required String profileId,
  }) {
    throw UnimplementedError();
  }
}