import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/school_model.dart';
import '../../shared/models/user_model.dart';
import '../repositories/school_repository.dart';
import '../repositories/user_repository.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

/// Service for managing approval workflows
class ApprovalWorkflowService {
  static ApprovalWorkflowService? _instance;
  static ApprovalWorkflowService get instance =>
      _instance ??= ApprovalWorkflowService._();

  ApprovalWorkflowService._();

  final SchoolRepository _schoolRepository = SchoolRepository();
  final UserRepository _userRepository = UserRepository();
  final NotificationService _notificationService = NotificationService.instance;

  /// Submit school for approval
  Future<ApprovalResult> submitSchoolForApproval({
    required String schoolId,
    required String submittedBy,
    String? notes,
    List<String>? attachments,
  }) async {
    try {
      // Get school details
      final school = await _schoolRepository.getById(schoolId);
      if (school == null) {
        return ApprovalResult(
          success: false,
          message: 'School not found',
        );
      }

      // Check if school is already approved or pending
      if (school.status == SchoolStatus.active) {
        return ApprovalResult(
          success: false,
          message: 'School is already approved',
        );
      }

      if (school.status == SchoolStatus.pending) {
        return ApprovalResult(
          success: false,
          message: 'School approval is already pending',
        );
      }

      // Update school status to pending
      await _schoolRepository.update(schoolId, {
        'status': SchoolStatus.pending.toString().split('.').last,
        'updatedAt': DateTime.now(),
        'submittedForApprovalAt': DateTime.now(),
        'submittedBy': submittedBy,
        'approvalNotes': notes,
        'approvalAttachments': attachments ?? [],
      });

      // Notify all super admins
      await _notifySuperAdmins(
        title: 'New School Approval Request',
        body: '${school.name} has submitted an approval request',
        data: {
          'type': 'school_approval_request',
          'school_id': schoolId,
          'school_name': school.name,
          'submitted_by': submittedBy,
        },
      );

      // Log event
      await FirebaseService.instance.logEvent('school_approval_submitted', {
        'school_id': schoolId,
        'school_name': school.name,
        'submitted_by': submittedBy,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      return ApprovalResult(
        success: true,
        message: 'School submitted for approval successfully',
      );
    } catch (e) {
      debugPrint('❌ Error submitting school for approval: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to submit school for approval: $schoolId',
      );
      return ApprovalResult(
        success: false,
        message: 'Failed to submit school for approval: ${e.toString()}',
      );
    }
  }

  /// Approve school (Super Admin only)
  Future<ApprovalResult> approveSchool({
    required String schoolId,
    required String approvedBy,
    String? notes,
  }) async {
    try {
      // Verify approver is super admin
      final approver = await _userRepository.getById(approvedBy);
      if (approver == null || !approver.isSuperAdmin) {
        return ApprovalResult(
          success: false,
          message: 'Only Super Admins can approve schools',
        );
      }

      // Get school details
      final school = await _schoolRepository.getById(schoolId);
      if (school == null) {
        return ApprovalResult(
          success: false,
          message: 'School not found',
        );
      }

      if (school.status != SchoolStatus.pending) {
        return ApprovalResult(
          success: false,
          message: 'School is not pending approval',
        );
      }

      // Approve the school
      await _schoolRepository.approveSchool(schoolId, approvedBy, notes: notes);

      // Notify school admin
      await _notifySchoolAdmin(
        schoolId: schoolId,
        title: 'School Approved!',
        body: 'Your school ${school.name} has been approved and is now active.',
        data: {
          'type': 'school_approved',
          'school_id': schoolId,
          'approved_by': approvedBy,
          'approved_at': DateTime.now().toIso8601String(),
        },
      );

      // Enable school admin access
      await _enableSchoolAdminAccess(schoolId);

      return ApprovalResult(
        success: true,
        message: 'School approved successfully',
      );
    } catch (e) {
      debugPrint('❌ Error approving school: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to approve school: $schoolId',
      );
      return ApprovalResult(
        success: false,
        message: 'Failed to approve school: ${e.toString()}',
      );
    }
  }

  /// Reject school (Super Admin only)
  Future<ApprovalResult> rejectSchool({
    required String schoolId,
    required String rejectedBy,
    required String reason,
  }) async {
    try {
      // Verify rejector is super admin
      final rejector = await _userRepository.getById(rejectedBy);
      if (rejector == null || !rejector.isSuperAdmin) {
        return ApprovalResult(
          success: false,
          message: 'Only Super Admins can reject schools',
        );
      }

      // Get school details
      final school = await _schoolRepository.getById(schoolId);
      if (school == null) {
        return ApprovalResult(
          success: false,
          message: 'School not found',
        );
      }

      // Reject the school
      await _schoolRepository.rejectSchool(schoolId, rejectedBy, reason);

      // Notify school admin
      await _notifySchoolAdmin(
        schoolId: schoolId,
        title: 'School Application Rejected',
        body: 'Your school application has been rejected. Reason: $reason',
        data: {
          'type': 'school_rejected',
          'school_id': schoolId,
          'rejected_by': rejectedBy,
          'rejection_reason': reason,
          'rejected_at': DateTime.now().toIso8601String(),
        },
      );

      return ApprovalResult(
        success: true,
        message: 'School rejected successfully',
      );
    } catch (e) {
      debugPrint('❌ Error rejecting school: $e');
      await FirebaseService.instance.logError(
        e,
        StackTrace.current,
        reason: 'Failed to reject school: $schoolId',
      );
      return ApprovalResult(
        success: false,
        message: 'Failed to reject school: ${e.toString()}',
      );
    }
  }

  /// Check if user can access school features
  Future<bool> canAccessSchoolFeatures(String userId) async {
    try {
      final user = await _userRepository.getById(userId);
      if (user == null) return false;

      // Super admins can always access
      if (user.isSuperAdmin) return true;

      // For school admins, check if their school is approved
      if (user.isSchoolAdmin && user.schoolId != null) {
        final school = await _schoolRepository.getById(user.schoolId!);
        return school?.isActive ?? false;
      }

      // For drivers and parents, check if their school is approved
      if ((user.isDriver || user.isParent) && user.schoolId != null) {
        final school = await _schoolRepository.getById(user.schoolId!);
        return school?.isActive ?? false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking school access: $e');
      return false;
    }
  }

  /// Get approval status for school
  Future<SchoolApprovalStatus> getSchoolApprovalStatus(String schoolId) async {
    try {
      final school = await _schoolRepository.getById(schoolId);
      if (school == null) {
        return SchoolApprovalStatus(
          status: SchoolStatus.inactive,
          message: 'School not found',
          canSubmitForApproval: false,
        );
      }

      String message;
      bool canSubmitForApproval = false;

      switch (school.status) {
        case SchoolStatus.pending:
          message = 'Your school approval is pending review by Super Admin';
          break;
        case SchoolStatus.active:
          message = 'Your school is approved and active';
          break;
        case SchoolStatus.rejected:
          message =
              'Your school application was rejected: ${school.rejectionReason ?? 'No reason provided'}';
          canSubmitForApproval = true;
          break;
        case SchoolStatus.suspended:
          message = 'Your school is temporarily suspended';
          break;
        case SchoolStatus.inactive:
          message = 'Your school is inactive';
          canSubmitForApproval = true;
          break;
      }

      return SchoolApprovalStatus(
        status: school.status,
        message: message,
        canSubmitForApproval: canSubmitForApproval,
        approvedAt: school.approvedAt,
        approvedBy: school.approvedBy,
        rejectionReason: school.rejectionReason,
      );
    } catch (e) {
      debugPrint('❌ Error getting school approval status: $e');
      return SchoolApprovalStatus(
        status: SchoolStatus.inactive,
        message: 'Error checking approval status',
        canSubmitForApproval: false,
      );
    }
  }

  /// Notify all super admins
  Future<void> _notifySuperAdmins({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final superAdmins =
          await _userRepository.getUsersByRole(UserRole.superAdmin);

      for (final admin in superAdmins) {
        if (admin.isActive) {
          await _notificationService.sendNotificationRequest(
            type: 'admin_notification',
            userIds: [admin.uid],
            data: {
              'title': title,
              'body': body,
              ...data ?? {},
            },
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error notifying super admins: $e');
    }
  }

  /// Notify school admin
  Future<void> _notifySchoolAdmin({
    required String schoolId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final schoolAdmins = await _userRepository.getUsersBySchoolAndRole(
        schoolId,
        UserRole.schoolAdmin,
      );

      for (final admin in schoolAdmins) {
        if (admin.isActive) {
          await _notificationService.sendNotificationRequest(
            type: 'admin_notification',
            userIds: [admin.uid],
            data: {
              'title': title,
              'body': body,
              ...data ?? {},
            },
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error notifying school admin: $e');
    }
  }

  /// Enable school admin access after approval
  Future<void> _enableSchoolAdminAccess(String schoolId) async {
    try {
      final schoolAdmins = await _userRepository.getUsersBySchoolAndRole(
        schoolId,
        UserRole.schoolAdmin,
      );

      for (final admin in schoolAdmins) {
        await _userRepository.update(admin.uid, {
          'isActive': true,
          'isVerified': true,
          'updatedAt': DateTime.now(),
        });
      }
    } catch (e) {
      debugPrint('❌ Error enabling school admin access: $e');
    }
  }
}

/// Approval result model
class ApprovalResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  ApprovalResult({
    required this.success,
    required this.message,
    this.data,
  });
}

/// School approval status model
class SchoolApprovalStatus {
  final SchoolStatus status;
  final String message;
  final bool canSubmitForApproval;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;

  SchoolApprovalStatus({
    required this.status,
    required this.message,
    required this.canSubmitForApproval,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
  });
}

/// Provider for approval workflow service
final approvalWorkflowServiceProvider =
    Provider<ApprovalWorkflowService>((ref) {
  return ApprovalWorkflowService.instance;
});
