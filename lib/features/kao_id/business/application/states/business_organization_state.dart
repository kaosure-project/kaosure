import '../../domain/entities/business_organization.dart';
import '../../domain/failures/business_organization_failure.dart';

final class BusinessOrganizationState {
  const BusinessOrganizationState({
    this.organizations = const [],
    this.isLoading = true,
    this.isSubmitting = false,
    this.submitted = false,
    this.failure,
  });

  final List<BusinessOrganization> organizations;
  final bool isLoading;
  final bool isSubmitting;

  /// The last company bank submission reached the review queue.
  final bool submitted;
  final BusinessOrganizationFailureCode? failure;

  bool get isBusy => isLoading || isSubmitting;

  BusinessOrganizationState copyWith({
    List<BusinessOrganization>? organizations,
    bool? isLoading,
    bool? isSubmitting,
    bool? submitted,
    BusinessOrganizationFailureCode? failure,
    bool clearFailure = false,
  }) {
    return BusinessOrganizationState(
      organizations: organizations ?? this.organizations,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitted: submitted ?? this.submitted,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
