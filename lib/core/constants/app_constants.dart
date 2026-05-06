class AppConstants {
  const AppConstants._();

  static const String appName = 'MaintenanceOS';
  static const String tagline = 'Maintenance, coordinated.';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String propertiesCollection = 'properties';
  static const String maintenanceRequestsCollection = 'maintenanceRequests';

  /// Cloud Storage prefix for photos attached to a maintenance request.
  static const String requestPhotosStoragePath = 'maintenanceRequests';
}
