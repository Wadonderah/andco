import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/attendance_model.dart';
import '../services/firebase_service.dart';
import 'base_repository.dart';

/// Repository for managing safety check data
class SafetyCheckRepository extends BaseRepository<SafetyCheckModel> {
  @override
  String get collectionName => 'safety_checks';

  @override
  SafetyCheckModel fromMap(Map<String, dynamic> map) =>
      SafetyCheckModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(SafetyCheckModel model) => model.toMap();

  /// Get safety checks by driver
  Future<List<SafetyCheckModel>> getSafetyChecksByDriver(String driverId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = collection.where('driverId', isEqualTo: driverId);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.orderBy('date', descending: true).get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting safety checks by driver: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get safety checks by driver: $driverId',
      );
      return [];
    }
  }

  /// Get safety checks by driver stream
  Stream<List<SafetyCheckModel>> getSafetyChecksByDriverStream(String driverId,
      {DateTime? startDate, DateTime? endDate}) {
    Query query = collection.where('driverId', isEqualTo: driverId);

    if (startDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query =
          query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.orderBy('date', descending: true).snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get safety checks by bus
  Future<List<SafetyCheckModel>> getSafetyChecksByBus(String busId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = collection.where('busId', isEqualTo: busId);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.orderBy('date', descending: true).get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting safety checks by bus: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get safety checks by bus: $busId',
      );
      return [];
    }
  }

  /// Get today's safety check for driver and bus
  Future<SafetyCheckModel?> getTodaysSafetyCheck(
      String driverId, String busId, SafetyCheckType type) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await collection
          .where('driverId', isEqualTo: driverId)
          .where('busId', isEqualTo: busId)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting today\'s safety check: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get today\'s safety check: $driverId, $busId',
      );
      return null;
    }
  }

  /// Create safety check with default items
  Future<SafetyCheckModel> createSafetyCheckWithDefaults(
    String driverId,
    String busId,
    SafetyCheckType type,
  ) async {
    try {
      final now = DateTime.now();
      final checkId =
          '${driverId}_${busId}_${type.toString().split('.').last}_${now.millisecondsSinceEpoch}';

      final defaultItems = _getDefaultSafetyCheckItems(type);

      final safetyCheck = SafetyCheckModel(
        id: checkId,
        driverId: driverId,
        busId: busId,
        date: now,
        type: type,
        items: defaultItems,
        status: SafetyCheckStatus.pending,
        photoUrls: [],
        createdAt: now,
        updatedAt: now,
      );

      await create(safetyCheck);

      // Log safety check creation event
      await FirebaseService.instance.logEvent('safety_check_created', {
        'safety_check_id': checkId,
        'driver_id': driverId,
        'bus_id': busId,
        'type': type.toString().split('.').last,
        'created_at': now.toIso8601String(),
      });

      debugPrint('✅ Safety check created: $checkId');
      return safetyCheck;
    } catch (e) {
      debugPrint('❌ Error creating safety check: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to create safety check: $driverId, $busId',
      );
      rethrow;
    }
  }

  /// Update safety check item
  Future<void> updateSafetyCheckItem(
    String safetyCheckId,
    String itemId,
    bool isPassed, {
    String? notes,
    String? photoUrl,
  }) async {
    try {
      final safetyCheck = await getById(safetyCheckId);
      if (safetyCheck == null) throw Exception('Safety check not found');

      final updatedItems = safetyCheck.items.map((item) {
        if (item.id == itemId) {
          return SafetyCheckItem(
            id: item.id,
            name: item.name,
            description: item.description,
            isPassed: isPassed,
            isCritical: item.isCritical,
            notes: notes ?? item.notes,
            photoUrl: photoUrl ?? item.photoUrl,
          );
        }
        return item;
      }).toList();

      // Determine overall status
      final hasCriticalFailures =
          updatedItems.any((item) => item.isCritical && !item.isPassed);
      final hasAnyFailures = updatedItems.any((item) => !item.isPassed);
      final allItemsChecked = updatedItems
          .every((item) => item.isPassed || item.notes?.isNotEmpty == true);

      SafetyCheckStatus status;
      if (!allItemsChecked) {
        status = SafetyCheckStatus.pending;
      } else if (hasCriticalFailures) {
        status = SafetyCheckStatus.failed;
      } else if (hasAnyFailures) {
        status = SafetyCheckStatus.needsAttention;
      } else {
        status = SafetyCheckStatus.passed;
      }

      await update(safetyCheckId, {
        'items': updatedItems.map((item) => item.toMap()).toList(),
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Log safety check item update event
      await FirebaseService.instance.logEvent('safety_check_item_updated', {
        'safety_check_id': safetyCheckId,
        'item_id': itemId,
        'is_passed': isPassed,
        'status': status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Safety check item updated: $itemId - $isPassed');
    } catch (e) {
      debugPrint('❌ Error updating safety check item: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to update safety check item: $itemId',
      );
      rethrow;
    }
  }

  /// Complete safety check
  Future<void> completeSafetyCheck(String safetyCheckId,
      {String? notes, List<String>? photoUrls}) async {
    try {
      final safetyCheck = await getById(safetyCheckId);
      if (safetyCheck == null) throw Exception('Safety check not found');

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (notes != null) {
        updateData['notes'] = notes;
      }

      if (photoUrls != null) {
        updateData['photoUrls'] = photoUrls;
      }

      await update(safetyCheckId, updateData);

      // Log safety check completion event
      await FirebaseService.instance.logEvent('safety_check_completed', {
        'safety_check_id': safetyCheckId,
        'status': safetyCheck.status.toString().split('.').last,
        'completed_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Safety check completed: $safetyCheckId');
    } catch (e) {
      debugPrint('❌ Error completing safety check: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to complete safety check: $safetyCheckId',
      );
      rethrow;
    }
  }

  /// Get safety check statistics for driver
  Future<Map<String, dynamic>> getDriverSafetyStats(String driverId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final safetyChecks = await getSafetyChecksByDriver(driverId,
          startDate: startDate, endDate: endDate);

      final totalChecks = safetyChecks.length;
      final passedChecks = safetyChecks
          .where((check) => check.status == SafetyCheckStatus.passed)
          .length;
      final failedChecks = safetyChecks
          .where((check) => check.status == SafetyCheckStatus.failed)
          .length;
      final needsAttentionChecks = safetyChecks
          .where((check) => check.status == SafetyCheckStatus.needsAttention)
          .length;

      return {
        'totalChecks': totalChecks,
        'passedChecks': passedChecks,
        'failedChecks': failedChecks,
        'needsAttentionChecks': needsAttentionChecks,
        'passRate': totalChecks > 0 ? (passedChecks / totalChecks) * 100 : 0,
        'failureRate': totalChecks > 0 ? (failedChecks / totalChecks) * 100 : 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting driver safety stats: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to get driver safety stats: $driverId',
      );
      return {
        'totalChecks': 0,
        'passedChecks': 0,
        'failedChecks': 0,
        'needsAttentionChecks': 0,
        'passRate': 0,
        'failureRate': 0,
      };
    }
  }

  /// Get default safety check items based on type
  List<SafetyCheckItem> _getDefaultSafetyCheckItems(SafetyCheckType type) {
    final commonItems = [
      SafetyCheckItem(
        id: 'tires',
        name: 'Tires',
        description: 'Check tire condition and pressure',
        isPassed: false,
        isCritical: true,
      ),
      SafetyCheckItem(
        id: 'brakes',
        name: 'Brakes',
        description: 'Test brake functionality',
        isPassed: false,
        isCritical: true,
      ),
      SafetyCheckItem(
        id: 'lights',
        name: 'Lights',
        description: 'Check all lights (headlights, taillights, indicators)',
        isPassed: false,
        isCritical: true,
      ),
      SafetyCheckItem(
        id: 'mirrors',
        name: 'Mirrors',
        description: 'Adjust and clean all mirrors',
        isPassed: false,
        isCritical: false,
      ),
      SafetyCheckItem(
        id: 'seatbelts',
        name: 'Seatbelts',
        description: 'Check all seatbelts for proper function',
        isPassed: false,
        isCritical: true,
      ),
      SafetyCheckItem(
        id: 'emergency_exits',
        name: 'Emergency Exits',
        description: 'Ensure emergency exits are clear and functional',
        isPassed: false,
        isCritical: true,
      ),
      SafetyCheckItem(
        id: 'first_aid_kit',
        name: 'First Aid Kit',
        description: 'Check first aid kit is present and stocked',
        isPassed: false,
        isCritical: false,
      ),
      SafetyCheckItem(
        id: 'fire_extinguisher',
        name: 'Fire Extinguisher',
        description: 'Check fire extinguisher is present and charged',
        isPassed: false,
        isCritical: true,
      ),
    ];

    if (type == SafetyCheckType.preTrip) {
      return [
        ...commonItems,
        SafetyCheckItem(
          id: 'engine_fluids',
          name: 'Engine Fluids',
          description: 'Check oil, coolant, and other fluid levels',
          isPassed: false,
          isCritical: true,
        ),
        SafetyCheckItem(
          id: 'windshield',
          name: 'Windshield',
          description: 'Check windshield for cracks and clean',
          isPassed: false,
          isCritical: false,
        ),
      ];
    }

    return commonItems;
  }
}
