import 'package:andco/core/services/school_admin_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SchoolAdminService Tests', () {
    test('should create SchoolAdminService instance', () {
      // Act
      final service = SchoolAdminService.instance;

      // Assert
      expect(service, isNotNull);
      expect(service, isA<SchoolAdminService>());
    });

    test('should be singleton', () {
      // Act
      final service1 = SchoolAdminService.instance;
      final service2 = SchoolAdminService.instance;

      // Assert
      expect(service1, same(service2));
    });

    // Additional tests can be added here when needed
  });
}
