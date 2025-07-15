import 'package:andco/core/services/payment_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentService Tests', () {
    test('should create PaymentService instance', () {
      // Act
      final service = PaymentService.instance;

      // Assert
      expect(service, isNotNull);
      expect(service, isA<PaymentService>());
    });

    test('should be singleton', () {
      // Act
      final service1 = PaymentService.instance;
      final service2 = PaymentService.instance;

      // Assert
      expect(service1, same(service2));
    });

    // Additional tests can be added here when needed
  });
}
