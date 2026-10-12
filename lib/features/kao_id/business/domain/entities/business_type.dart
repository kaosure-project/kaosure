/// Business types accepted by `submit_business_registration`, which maps them
/// onto `organizations.organization_type` (`company` or `organization`).
abstract final class BusinessType {
  static const registeredBusiness = 'registered_business';
  static const organization = 'organization';

  static const values = [registeredBusiness, organization];
}

/// Category codes stored in `business_registrations.business_category`.
abstract final class BusinessCategory {
  static const retail = 'retail';
  static const food = 'food_beverage';
  static const services = 'services';
  static const technology = 'technology';
  static const other = 'other';

  static const values = [retail, food, services, technology, other];
}
