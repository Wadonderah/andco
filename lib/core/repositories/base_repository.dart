import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/firebase_service.dart';

/// Base repository class for common Firestore operations
abstract class BaseRepository<T> {
  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  /// Collection name in Firestore
  String get collectionName;

  /// Convert map to model
  T fromMap(Map<String, dynamic> map);

  /// Convert model to map
  Map<String, dynamic> toMap(T model);

  /// Get collection reference
  CollectionReference get collection => _firestore.collection(collectionName);

  /// Create a new document
  Future<String> create(T model) async {
    try {
      final docRef = await collection.add(toMap(model));
      await FirebaseService.instance.logEvent('${collectionName}_created', {
        'document_id': docRef.id,
      });
      return docRef.id;
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to create $collectionName');
      rethrow;
    }
  }

  /// Create a document with specific ID
  Future<void> createWithId(String id, T model) async {
    try {
      await collection.doc(id).set(toMap(model));
      await FirebaseService.instance.logEvent('${collectionName}_created', {
        'document_id': id,
      });
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to create $collectionName with ID');
      rethrow;
    }
  }

  /// Get document by ID
  Future<T?> getById(String id) async {
    try {
      final doc = await collection.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to get $collectionName by ID');
      return null;
    }
  }

  /// Get all documents
  Future<List<T>> getAll() async {
    try {
      final querySnapshot = await collection.get();
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to get all $collectionName');
      return [];
    }
  }

  /// Get documents with query
  Future<List<T>> getWhere(String field, dynamic value) async {
    try {
      final querySnapshot =
          await collection.where(field, isEqualTo: value).get();
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to query $collectionName');
      return [];
    }
  }

  /// Get documents with multiple conditions
  Future<List<T>> getWhereMultiple(Map<String, dynamic> conditions) async {
    try {
      Query query = collection;

      conditions.forEach((field, value) {
        query = query.where(field, isEqualTo: value);
      });

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to query $collectionName with multiple conditions');
      return [];
    }
  }

  /// Update document
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await collection.doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseService.instance.logEvent('${collectionName}_updated', {
        'document_id': id,
      });
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to update $collectionName');
      rethrow;
    }
  }

  /// Delete document
  Future<void> delete(String id) async {
    try {
      await collection.doc(id).delete();
      await FirebaseService.instance.logEvent('${collectionName}_deleted', {
        'document_id': id,
      });
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to delete $collectionName');
      rethrow;
    }
  }

  /// Soft delete (mark as inactive)
  Future<void> softDelete(String id) async {
    try {
      await update(id, {'isActive': false});
      await FirebaseService.instance
          .logEvent('${collectionName}_soft_deleted', {
        'document_id': id,
      });
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to soft delete $collectionName');
      rethrow;
    }
  }

  /// Get documents stream for real-time updates
  Stream<List<T>> getStream() {
    return collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get document stream by ID
  Stream<T?> getStreamById(String id) {
    return collection.doc(id).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Get documents stream with query
  Stream<List<T>> getStreamWhere(String field, dynamic value) {
    return collection
        .where(field, isEqualTo: value)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Batch operations
  Future<void> batchCreate(List<T> models) async {
    try {
      final batch = _firestore.batch();

      for (final model in models) {
        final docRef = collection.doc();
        batch.set(docRef, toMap(model));
      }

      await batch.commit();
      await FirebaseService.instance
          .logEvent('${collectionName}_batch_created', {
        'count': models.length,
      });
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to batch create $collectionName');
      rethrow;
    }
  }

  /// Batch update
  Future<void> batchUpdate(Map<String, Map<String, dynamic>> updates) async {
    try {
      final batch = _firestore.batch();

      updates.forEach((id, data) {
        batch.update(collection.doc(id), {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();
      await FirebaseService.instance
          .logEvent('${collectionName}_batch_updated', {
        'count': updates.length,
      });
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to batch update $collectionName');
      rethrow;
    }
  }

  /// Get paginated results
  Future<List<T>> getPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query query = collection;

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
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
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to get paginated $collectionName');
      return [];
    }
  }

  /// Count documents
  Future<int> count() async {
    try {
      final querySnapshot = await collection.count().get();
      return querySnapshot.count ?? 0;
    } catch (e) {
      debugPrint('Failed to count $collectionName: $e');
      return 0;
    }
  }

  /// Check if document exists
  Future<bool> exists(String id) async {
    try {
      final doc = await collection.doc(id).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Failed to check if $collectionName exists: $e');
      return false;
    }
  }
}

/// Repository for user-specific data with additional security
abstract class UserRepository<T> extends BaseRepository<T> {
  /// Get documents for specific user
  Future<List<T>> getForUser(String userId) async {
    return getWhere('userId', userId);
  }

  /// Get documents stream for specific user
  Stream<List<T>> getStreamForUser(String userId) {
    return getStreamWhere('userId', userId);
  }

  /// Create document for specific user
  Future<String> createForUser(String userId, T model) async {
    final modelMap = toMap(model);
    modelMap['userId'] = userId;

    try {
      final docRef = await collection.add(modelMap);
      await FirebaseService.instance
          .logEvent('${collectionName}_created_for_user', {
        'document_id': docRef.id,
        'user_id': userId,
      });
      return docRef.id;
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Failed to create $collectionName for user');
      rethrow;
    }
  }
}
