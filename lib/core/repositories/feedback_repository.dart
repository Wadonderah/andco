import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/incident_model.dart';
import '../services/firebase_service.dart';
import 'base_repository.dart';

/// Repository for managing feedback from parents and drivers
class FeedbackRepository extends BaseRepository<FeedbackModel> {
  @override
  String get collectionName => 'feedback';

  @override
  FeedbackModel fromMap(Map<String, dynamic> map) => FeedbackModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(FeedbackModel model) => model.toMap();

  /// Get feedback by school
  Stream<List<FeedbackModel>> getFeedbackBySchool(String schoolId) {
    return collection
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get feedback by status
  Stream<List<FeedbackModel>> getFeedbackByStatus(
      String schoolId, FeedbackStatus status) {
    return collection
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get feedback by type
  Stream<List<FeedbackModel>> getFeedbackByType(
      String schoolId, FeedbackType type) {
    return collection
        .where('schoolId', isEqualTo: schoolId)
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get feedback by category
  Stream<List<FeedbackModel>> getFeedbackByCategory(
      String schoolId, FeedbackCategory category) {
    return collection
        .where('schoolId', isEqualTo: schoolId)
        .where('category', isEqualTo: category.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get feedback by driver
  Stream<List<FeedbackModel>> getFeedbackByDriver(String driverId) {
    return collection
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get feedback by route
  Stream<List<FeedbackModel>> getFeedbackByRoute(String routeId) {
    return collection
        .where('routeId', isEqualTo: routeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get pending feedback for school
  Stream<List<FeedbackModel>> getPendingFeedback(String schoolId) {
    return collection
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Update feedback status
  Future<void> updateFeedbackStatus(
      String feedbackId, FeedbackStatus status) async {
    try {
      await update(feedbackId, {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('❌ Error updating feedback status: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to update feedback status',
      );
      rethrow;
    }
  }

  /// Assign feedback to user
  Future<void> assignFeedback(String feedbackId, String assignedTo) async {
    try {
      await update(feedbackId, {
        'assignedTo': assignedTo,
        'status': FeedbackStatus.inProgress.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('❌ Error assigning feedback: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to assign feedback',
      );
      rethrow;
    }
  }

  /// Respond to feedback
  Future<void> respondToFeedback(
      String feedbackId, String response, String respondedBy) async {
    try {
      await update(feedbackId, {
        'response': response,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
        'status': FeedbackStatus.resolved.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('❌ Error responding to feedback: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to respond to feedback',
      );
      rethrow;
    }
  }

  /// Get feedback statistics for school
  Future<Map<String, dynamic>> getFeedbackStatistics(String schoolId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      // Get all feedback for the school
      final allFeedback =
          await collection.where('schoolId', isEqualTo: schoolId).get();

      final feedback = allFeedback.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Calculate statistics
      final totalFeedback = feedback.length;
      final pendingFeedback = feedback.where((f) => f.isPending).length;
      final resolvedFeedback = feedback.where((f) => f.isResolved).length;
      final monthlyFeedback =
          feedback.where((f) => f.createdAt.isAfter(startOfMonth)).length;
      final weeklyFeedback =
          feedback.where((f) => f.createdAt.isAfter(startOfWeek)).length;

      // Calculate average rating
      double avgRating = 0;
      if (feedback.isNotEmpty) {
        final totalRating = feedback
            .map((f) => f.rating)
            .fold(0, (sum, rating) => sum + rating);
        avgRating = totalRating / feedback.length;
      }

      // Calculate response time
      final respondedFeedback =
          feedback.where((f) => f.respondedAt != null).toList();
      double avgResponseTime = 0;
      if (respondedFeedback.isNotEmpty) {
        final totalResponseTime = respondedFeedback
            .map((f) => f.respondedAt!.difference(f.createdAt).inHours)
            .fold(0, (sum, hours) => sum + hours);
        avgResponseTime = totalResponseTime / respondedFeedback.length;
      }

      // Group by type
      final feedbackByType = <String, int>{};
      for (final fb in feedback) {
        final type = fb.type.toString().split('.').last;
        feedbackByType[type] = (feedbackByType[type] ?? 0) + 1;
      }

      // Group by category
      final feedbackByCategory = <String, int>{};
      for (final fb in feedback) {
        final category = fb.category.toString().split('.').last;
        feedbackByCategory[category] = (feedbackByCategory[category] ?? 0) + 1;
      }

      // Calculate satisfaction metrics
      final positiveFeedback = feedback.where((f) => f.isPositive).length;
      final negativeFeedback = feedback.where((f) => f.isNegative).length;
      final satisfactionRate = totalFeedback > 0
          ? (positiveFeedback / totalFeedback * 100).round()
          : 0;

      return {
        'totalFeedback': totalFeedback,
        'pendingFeedback': pendingFeedback,
        'resolvedFeedback': resolvedFeedback,
        'monthlyFeedback': monthlyFeedback,
        'weeklyFeedback': weeklyFeedback,
        'avgRating': avgRating,
        'avgResponseTimeHours': avgResponseTime,
        'feedbackByType': feedbackByType,
        'feedbackByCategory': feedbackByCategory,
        'positiveFeedback': positiveFeedback,
        'negativeFeedback': negativeFeedback,
        'satisfactionRate': satisfactionRate,
        'responseRate': totalFeedback > 0
            ? (respondedFeedback.length / totalFeedback * 100).round()
            : 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting feedback statistics: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get feedback statistics',
      );
      return {};
    }
  }

  /// Search feedback
  Future<List<FeedbackModel>> searchFeedback(
      String schoolId, String query) async {
    try {
      if (query.isEmpty) return [];

      final queryLower = query.toLowerCase();

      // Search by title
      final titleQuery = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      // Search by description
      final descQuery = await collection
          .where('schoolId', isEqualTo: schoolId)
          .where('description', isGreaterThanOrEqualTo: queryLower)
          .where('description', isLessThanOrEqualTo: '$queryLower\uf8ff')
          .get();

      final feedbackMap = <String, FeedbackModel>{};

      // Add results from title search
      for (final doc in titleQuery.docs) {
        feedbackMap[doc.id] = fromMap(doc.data() as Map<String, dynamic>);
      }

      // Add results from description search
      for (final doc in descQuery.docs) {
        feedbackMap[doc.id] = fromMap(doc.data() as Map<String, dynamic>);
      }

      return feedbackMap.values.toList();
    } catch (e) {
      debugPrint('❌ Error searching feedback: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to search feedback',
      );
      return [];
    }
  }

  /// Get feedback with pagination
  Future<List<FeedbackModel>> getFeedbackPaginated({
    required String schoolId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    FeedbackStatus? status,
    FeedbackType? type,
    FeedbackCategory? category,
  }) async {
    try {
      Query query = collection
          .where('schoolId', isEqualTo: schoolId)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query =
            query.where('status', isEqualTo: status.toString().split('.').last);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (category != null) {
        query = query.where('category',
            isEqualTo: category.toString().split('.').last);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting paginated feedback: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get paginated feedback',
      );
      return [];
    }
  }
}
