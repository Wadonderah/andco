import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/bus_model.dart';
import '../../shared/models/trip_model.dart';
import '../repositories/bus_repository.dart';
import '../repositories/checkin_repository.dart';
import '../repositories/child_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/route_repository.dart';
import '../repositories/trip_repository.dart';
import '../repositories/user_repository.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

// ==================== FIREBASE SERVICES ====================

/// Firebase core service provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService.instance;
});

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

// ==================== REPOSITORY PROVIDERS ====================

/// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Child repository provider
final childRepositoryProvider = Provider<ChildRepository>((ref) {
  return ChildRepository();
});

/// Bus repository provider
final busRepositoryProvider = Provider<BusRepository>((ref) {
  return BusRepository();
});

/// Route repository provider
final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return RouteRepository();
});

/// Trip repository provider
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository();
});

/// Check-in repository provider
final checkinRepositoryProvider = Provider<CheckinRepository>((ref) {
  return CheckinRepository();
});

/// Payment repository provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

/// Notification repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

// ==================== STREAM PROVIDERS ====================

/// Current user stream provider
final currentUserStreamProvider = StreamProvider((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);

  return firebaseService.auth.authStateChanges().asyncMap((user) async {
    if (user == null) return null;
    try {
      return await userRepo.getById(user.uid);
    } catch (e) {
      return null;
    }
  });
});

/// User children stream provider
final userChildrenStreamProvider =
    StreamProvider.family((ref, String parentId) {
  final childRepo = ref.watch(childRepositoryProvider);
  return childRepo.getChildrenStreamForParent(parentId);
});

/// School buses stream provider
final schoolBusesStreamProvider = StreamProvider.family((ref, String schoolId) {
  final busRepo = ref.watch(busRepositoryProvider);
  return busRepo.getBusesStreamForSchool(schoolId);
});

/// School routes stream provider
final schoolRoutesStreamProvider =
    StreamProvider.family((ref, String schoolId) {
  final routeRepo = ref.watch(routeRepositoryProvider);
  return routeRepo.getRoutesStreamForSchool(schoolId);
});

/// Active trips stream provider
final activeTripsStreamProvider =
    StreamProvider.family<List<TripModel>, String>((ref, String schoolId) {
  final tripRepo = ref.watch(tripRepositoryProvider);
  return tripRepo.getActiveTripsStreamForSchool(schoolId);
});

/// Trip check-ins stream provider
final tripCheckinsStreamProvider = StreamProvider.family((ref, String tripId) {
  final checkinRepo = ref.watch(checkinRepositoryProvider);
  return checkinRepo.getCheckinsStreamForTrip(tripId);
});

/// User notifications stream provider
final userNotificationsStreamProvider =
    StreamProvider.family((ref, String userId) {
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  return notificationRepo.getNotificationsStreamForUser(userId);
});

/// User payments stream provider
final userPaymentsStreamProvider = StreamProvider.family((ref, String userId) {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return paymentRepo.getPaymentsStreamForUser(userId);
});

// ==================== STATE PROVIDERS ====================

/// Firebase initialization state provider
final firebaseInitializationProvider = FutureProvider<bool>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.isInitialized;
});

/// FCM token provider
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.fcmToken;
});

// ==================== UTILITY PROVIDERS ====================

/// Analytics logger provider
final analyticsLoggerProvider = Provider((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return (String event, Map<String, Object>? parameters) {
    firebaseService.logEvent(event, parameters);
  };
});

/// Error logger provider
final errorLoggerProvider = Provider((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return (dynamic error, StackTrace? stackTrace, {String? reason}) {
    firebaseService.logError(error, stackTrace, reason: reason);
  };
});

/// File uploader provider
final fileUploaderProvider = Provider((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return storageService;
});

// ==================== NOTIFICATION PROVIDERS ====================

/// Send notification provider
final sendNotificationProvider = Provider((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService;
});

/// Subscribe to topic provider
final subscribeToTopicProvider = Provider((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return (String topic) => notificationService.subscribeToTopic(topic);
});

/// Unsubscribe from topic provider
final unsubscribeFromTopicProvider = Provider((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return (String topic) => notificationService.unsubscribeFromTopic(topic);
});

// ==================== BATCH OPERATION PROVIDERS ====================

/// Batch create provider
final batchCreateProvider = Provider((ref) {
  return <T>(Provider<dynamic> repositoryProvider, List<T> items) async {
    final repo = ref.read(repositoryProvider);
    if (repo.runtimeType.toString().contains('Repository')) {
      await (repo as dynamic).batchCreate(items);
    }
  };
});

/// Batch update provider
final batchUpdateProvider = Provider((ref) {
  return <T>(Provider<dynamic> repositoryProvider,
      Map<String, Map<String, dynamic>> updates) async {
    final repo = ref.read(repositoryProvider);
    if (repo.runtimeType.toString().contains('Repository')) {
      await (repo as dynamic).batchUpdate(updates);
    }
  };
});

/// Batch delete provider
final batchDeleteProvider = Provider((ref) {
  return (Provider<dynamic> repositoryProvider, List<String> ids) async {
    final repo = ref.read(repositoryProvider);
    if (repo.runtimeType.toString().contains('Repository')) {
      await (repo as dynamic).batchDelete(ids);
    }
  };
});

// ==================== REAL-TIME LOCATION PROVIDERS ====================

/// Bus location stream provider
final busLocationStreamProvider =
    StreamProvider.family<BusModel?, String>((ref, String busId) {
  final busRepo = ref.watch(busRepositoryProvider);
  return busRepo.getStreamById(busId);
});
s
/// Trip location updates stream provider
final tripLocationStreamProvider =
    StreamProvider.family<LocationData?, String>((ref, String tripId) {
  final tripRepo = ref.watch(tripRepositoryProvider);
  return tripRepo.getStreamById(tripId).map((trip) => trip?.currentLocation);
});

// ==================== EMERGENCY PROVIDERS ====================

/// Emergency alert provider
final emergencyAlertProvider = Provider((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return (String schoolId, String message, String severity, {Map<String, dynamic>? additionalData}) async {
    await notificationService.sendEmergencyNotification(
      schoolId: schoolId,
      message: message,
      severity: severity,
      additionalData: additionalData,
    );
  };
});

/// SOS provider
final sosProvider = Provider((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return (String schoolId, String message, Map<String, dynamic> location) async {
    await notificationService.sendEmergencyNotification(
      schoolId: schoolId,
      message: message,
      severity: 'critical',
      additionalData: {
        'type': 'sos',
        'location': location,
      },
    );
  };
});

// ==================== PAYMENT PROVIDERS ====================

/// Process payment provider
final processPaymentProvider = Provider((ref) {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return paymentRepo.processPayment;
});

/// Payment status stream provider
final paymentStatusStreamProvider =
    StreamProvider.family((ref, String paymentId) {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return paymentRepo.getPaymentStatusStream(paymentId);
});

// ==================== REPORTING PROVIDERS ====================

/// Generate report provider
final generateReportProvider = Provider((ref) {
  return (String reportType, Map<String, dynamic> parameters) async {
    // This would call a cloud function to generate reports
    final firebaseService = ref.read(firebaseServiceProvider);
    return await firebaseService.firestore.collection('reports').add({
      'type': reportType,
      'parameters': parameters,
      'status': 'pending',
      'createdAt': DateTime.now(),
    });
  };
});

/// Report status stream provider
final reportStatusStreamProvider =
    StreamProvider.family((ref, String reportId) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.firestore
      .collection('reports')
      .doc(reportId)
      .snapshots()
      .map((doc) => doc.data());
});
