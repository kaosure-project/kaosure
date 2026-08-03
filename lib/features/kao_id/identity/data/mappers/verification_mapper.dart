import '../../domain/entities/verification.dart';
import '../models/verification_model.dart';

extension VerificationModelMapper on VerificationModel {
  Verification toDomain() {
    return toEntity();
  }
}

extension VerificationEntityMapper on Verification {
  VerificationModel toModel() {
    return VerificationModel.fromEntity(this);
  }
}