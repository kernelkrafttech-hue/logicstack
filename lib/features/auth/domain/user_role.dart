/// The three roles supported in MaintenanceOS.
///
/// The wire format (`storageValue`) is stable and is what gets written to
/// Firestore. Display strings live next to the enum so role pickers stay
/// consistent across the UI.
enum UserRole {
  landlord(
    storageValue: 'landlord',
    displayName: 'Landlord',
    description: 'I own or manage one or more rental properties.',
  ),
  tenant(
    storageValue: 'tenant',
    displayName: 'Tenant',
    description: 'I rent a unit and need to report maintenance issues.',
  ),
  contractor(
    storageValue: 'contractor',
    displayName: 'Contractor',
    description: 'I perform maintenance work for landlords and properties.',
  );

  const UserRole({
    required this.storageValue,
    required this.displayName,
    required this.description,
  });

  final String storageValue;
  final String displayName;
  final String description;

  static UserRole? fromStorage(String? value) {
    if (value == null) return null;
    for (final UserRole role in UserRole.values) {
      if (role.storageValue == value) return role;
    }
    return null;
  }
}
