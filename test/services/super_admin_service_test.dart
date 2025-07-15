import 'package:andco/core/services/super_admin_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SuperAdminService Tests', () {
    test('should create SuperAdminService instance', () {
      // Act
      final service = SuperAdminService.instance;

      // Assert
      expect(service, isNotNull);
      expect(service, isA<SuperAdminService>());
    });

    test('should be singleton', () {
      // Act
      final service1 = SuperAdminService.instance;
      final service2 = SuperAdminService.instance;

      // Assert
      expect(service1, same(service2));
    });

    // Additional tests can be added here when needed
  });
}
