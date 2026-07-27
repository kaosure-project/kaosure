import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/remote/profile_remote_datasource.dart';
import '../mappers/profile_mapper.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remoteDataSource);

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<Profile> getProfile({
    required String profileId,
  }) async {
    final model = await _remoteDataSource.getProfile(
      profileId: profileId,
    );

    return ProfileMapper.toEntity(model);
  }

  @override
  Future<void> createProfile({
    required Profile profile,
  }) {
    return _remoteDataSource.createProfile(
      profile: ProfileMapper.toModel(profile),
    );
  }

  @override
  Future<void> updateProfile({
    required Profile profile,
  }) {
    return _remoteDataSource.updateProfile(
      profile: ProfileMapper.toModel(profile),
    );
  }

  @override
  Future<void> deleteProfile({
    required String profileId,
  }) {
    return _remoteDataSource.deleteProfile(
      profileId: profileId,
    );
  }

  @override
  Future<bool> exists({
    required String profileId,
  }) {
    return _remoteDataSource.exists(
      profileId: profileId,
    );
  }
}