import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;

/// Comprehensive school admin service for managing all administrative operations
class SchoolAdminService {
  static SchoolAdminService? _instance;
  static SchoolAdminService get instance =>
      _instance ??= SchoolAdminService._();

  SchoolAdminService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Initialize school admin service
  Future<void> initialize() async {
    try {
      debugPrint('✅ School Admin service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize school admin service: $e');
      rethrow;
    }
  }

  // ==================== STUDENT MANAGEMENT ====================

  /// Get all students for the school
  Stream<List<Map<String, dynamic>>> getSchoolStudentsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return <Map<String, dynamic>>[];

      final schoolId = userDoc.data()?['schoolId'] as String?;
      if (schoolId == null) return <Map<String, dynamic>>[];

      final studentsSnapshot = await _firestore
          .collection('children')
          .where('schoolId', isEqualTo: schoolId)
          .orderBy('name')
          .get();

      return studentsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Add new student
  Future<String> addStudent(Map<String, dynamic> studentData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Admin not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final schoolId = userDoc.data()?['schoolId'] as String?;
      if (schoolId == null) throw Exception('School not assigned');

      final studentDoc = await _firestore.collection('children').add({
        ...studentData,
        'schoolId': schoolId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
      });

      debugPrint('✅ Student added successfully: ${studentDoc.id}');
      return studentDoc.id;
    } catch (e) {
      debugPrint('❌ Failed to add student: $e');
      rethrow;
    }
  }

  /// Update student information
  Future<void> updateStudent(
      String studentId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('children').doc(studentId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });

      debugPrint('✅ Student updated successfully: $studentId');
    } catch (e) {
      debugPrint('❌ Failed to update student: $e');
      rethrow;
    }
  }

  /// Delete student
  Future<void> deleteStudent(String studentId) async {
    try {
      await _firestore.collection('children').doc(studentId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.currentUser?.uid,
      });

      debugPrint('✅ Student deleted successfully: $studentId');
    } catch (e) {
      debugPrint('❌ Failed to delete student: $e');
      rethrow;
    }
  }

  // ==================== DRIVER MANAGEMENT ====================

  /// Get pending driver applications
  Stream<List<Map<String, dynamic>>> getPendingDriversStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return <Map<String, dynamic>>[];

      final schoolId = userDoc.data()?['schoolId'] as String?;
      if (schoolId == null) return <Map<String, dynamic>>[];

      final driversSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('schoolId', isEqualTo: schoolId)
          .where('isApproved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return driversSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Approve driver application
  Future<void> approveDriver(
      String driverId, Map<String, dynamic> approvalData) async {
    try {
      await _firestore.collection('users').doc(driverId).update({
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid,
        'approvalNotes': approvalData['notes'],
        'assignedBusId': approvalData['busId'],
        'assignedRouteId': approvalData['routeId'],
      });

      // Send approval notification
      await _sendDriverApprovalNotification(driverId, true);

      debugPrint('✅ Driver approved successfully: $driverId');
    } catch (e) {
      debugPrint('❌ Failed to approve driver: $e');
      rethrow;
    }
  }

  /// Reject driver application
  Future<void> rejectDriver(String driverId, String reason) async {
    try {
      await _firestore.collection('users').doc(driverId).update({
        'isApproved': false,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid,
        'rejectionReason': reason,
      });

      // Send rejection notification
      await _sendDriverApprovalNotification(driverId, false, reason: reason);

      debugPrint('✅ Driver rejected successfully: $driverId');
    } catch (e) {
      debugPrint('❌ Failed to reject driver: $e');
      rethrow;
    }
  }

  /// Send driver approval/rejection notification
  Future<void> _sendDriverApprovalNotification(String driverId, bool approved,
      {String? reason}) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': driverId,
        'title': approved ? 'Application Approved' : 'Application Rejected',
        'message': approved
            ? 'Your driver application has been approved. You can now start accepting routes.'
            : 'Your driver application has been rejected. Reason: ${reason ?? 'Not specified'}',
        'type': 'driver_approval',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'approved': approved,
          'reason': reason,
        },
      });
    } catch (e) {
      debugPrint('❌ Failed to send driver notification: $e');
    }
  }

  // ==================== ROUTE MANAGEMENT ====================

  /// Get all routes for the school
  Stream<List<Map<String, dynamic>>> getSchoolRoutesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return <Map<String, dynamic>>[];

      final schoolId = userDoc.data()?['schoolId'] as String?;
      if (schoolId == null) return <Map<String, dynamic>>[];

      final routesSnapshot = await _firestore
          .collection('routes')
          .where('schoolId', isEqualTo: schoolId)
          .orderBy('name')
          .get();

      return routesSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Create new route
  Future<String> createRoute(Map<String, dynamic> routeData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Admin not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final schoolId = userDoc.data()?['schoolId'] as String?;
      if (schoolId == null) throw Exception('School not assigned');

      final routeDoc = await _firestore.collection('routes').add({
        ...routeData,
        'schoolId': schoolId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
      });

      debugPrint('✅ Route created successfully: ${routeDoc.id}');
      return routeDoc.id;
    } catch (e) {
      debugPrint('❌ Failed to create route: $e');
      rethrow;
    }
  }

  /// Assign student to route
  Future<void> assignStudentToRoute(
      String studentId, String routeId, String stopId) async {
    try {
      await _firestore.collection('children').doc(studentId).update({
        'routeId': routeId,
        'pickupStopId': stopId,
        'dropoffStopId': stopId,
        'updatedAt': FieldValue.serverTimestamp(),
        'assignedBy': _auth.currentUser?.uid,
      });

      debugPrint('✅ Student assigned to route successfully');
    } catch (e) {
      debugPrint('❌ Failed to assign student to route: $e');
      rethrow;
    }
  }

  // ==================== INCIDENT MONITORING ====================

  /// Get all incidents for the school
  Stream<List<Map<String, dynamic>>> getSchoolIncidentsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return <Map<String, dynamic>>[];

      final schoolId = userDoc.data()?['schoolId'] as String?;
      if (schoolId == null) return <Map<String, dynamic>>[];

      final incidentsSnapshot = await _firestore
          .collection('incidents')
          .where('schoolId', isEqualTo: schoolId)
          .orderBy('createdAt', descending: true)
          .get();

      return incidentsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Update incident status
  Future<void> updateIncidentStatus(
      String incidentId, String status, String notes) async {
    try {
      await _firestore.collection('incidents').doc(incidentId).update({
        'status': status,
        'adminNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });

      debugPrint('✅ Incident status updated successfully');
    } catch (e) {
      debugPrint('❌ Failed to update incident status: $e');
      rethrow;
    }
  }

  // ==================== REPORT GENERATION ====================

  /// Generate student report
  Future<String> generateStudentReport(
      String format, Map<String, dynamic> filters) async {
    try {
      final students = await getSchoolStudentsStream().first;

      if (format.toLowerCase() == 'csv') {
        return await _generateStudentCSV(students, filters);
      } else if (format.toLowerCase() == 'pdf') {
        return await _generateStudentPDF(students, filters);
      } else {
        throw Exception('Unsupported format: $format');
      }
    } catch (e) {
      debugPrint('❌ Failed to generate student report: $e');
      rethrow;
    }
  }

  /// Generate CSV report
  Future<String> _generateStudentCSV(
      List<Map<String, dynamic>> students, Map<String, dynamic> filters) async {
    try {
      final headers = [
        'Name',
        'Grade',
        'Class',
        'Parent Name',
        'Phone',
        'Route',
        'Status'
      ];
      final rows = <List<String>>[headers];

      for (final student in students) {
        rows.add([
          student['name'] ?? '',
          student['grade'] ?? '',
          student['className'] ?? '',
          student['parentName'] ?? '',
          student['parentPhone'] ?? '',
          student['routeId'] ?? 'Not Assigned',
          student['isActive'] == true ? 'Active' : 'Inactive',
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);

      // Upload to Firebase Storage
      final fileName =
          'student_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final ref = _storage.ref().child('reports').child(fileName);
      await ref.putString(csv);

      final downloadUrl = await ref.getDownloadURL();
      debugPrint('✅ CSV report generated: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Failed to generate CSV report: $e');
      rethrow;
    }
  }

  /// Generate PDF report
  Future<String> _generateStudentPDF(
      List<Map<String, dynamic>> students, Map<String, dynamic> filters) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Student Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Generated on: ${DateTime.now().toString()}'),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['Name', 'Grade', 'Class', 'Status'],
                  data: students
                      .map((student) => [
                            student['name'] ?? '',
                            student['grade'] ?? '',
                            student['className'] ?? '',
                            student['isActive'] == true ? 'Active' : 'Inactive',
                          ])
                      .toList(),
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      // Upload to Firebase Storage
      final fileName =
          'student_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final ref = _storage.ref().child('reports').child(fileName);
      await ref.putData(pdfBytes);

      final downloadUrl = await ref.getDownloadURL();
      debugPrint('✅ PDF report generated: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Failed to generate PDF report: $e');
      rethrow;
    }
  }

  /// Get school analytics data
  Future<Map<String, dynamic>> getSchoolAnalytics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Admin not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final schoolId = userDoc.data()?['schoolId'] as String?;
      if (schoolId == null) throw Exception('School not assigned');

      // Get various counts and statistics
      final studentsCount = await _firestore
          .collection('children')
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      final driversCount = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('schoolId', isEqualTo: schoolId)
          .where('isApproved', isEqualTo: true)
          .count()
          .get();

      final routesCount = await _firestore
          .collection('routes')
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      return {
        'totalStudents': studentsCount.count,
        'totalDrivers': driversCount.count,
        'totalRoutes': routesCount.count,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Failed to get school analytics: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}
