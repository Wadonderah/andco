import 'package:andco/core/services/driver_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverService Tests', () {
    test('should create DriverService instance', () {
      // Act
      final service = DriverService.instance;

      // Assert
      expect(service, isNotNull);
      expect(service, isA<DriverService>());
    });

    test('should be singleton', () {
      // Act
      final service1 = DriverService.instance;
      final service2 = DriverService.instance;

      // Assert
      expect(service1, same(service2));
    });

    // Additional tests can be added here when needed
  });
}
