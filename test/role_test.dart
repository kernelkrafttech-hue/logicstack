import 'package:flutter_test/flutter_test.dart';
import 'package:maintenanceos/features/auth/domain/user_role.dart';

void main() {
  group('UserRole', () {
    test('round-trips through storage value', () {
      for (final UserRole role in UserRole.values) {
        expect(UserRole.fromStorage(role.storageValue), role);
      }
    });

    test('returns null for unknown values', () {
      expect(UserRole.fromStorage('admin'), isNull);
      expect(UserRole.fromStorage(null), isNull);
    });

    test('exposes a human-readable display name', () {
      expect(UserRole.landlord.displayName, 'Landlord');
      expect(UserRole.tenant.displayName, 'Tenant');
      expect(UserRole.contractor.displayName, 'Contractor');
    });
  });
}
