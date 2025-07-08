import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class SchoolApprovalScreen extends StatefulWidget {
  const SchoolApprovalScreen({super.key});

  @override
  State<SchoolApprovalScreen> createState() => _SchoolApprovalScreenState();
}

class _SchoolApprovalScreenState extends State<SchoolApprovalScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ApprovalStatus _selectedStatus = ApprovalStatus.all;

  final List<SchoolApplication> _applications = [
    SchoolApplication(
      id: 'app_001',
      schoolName: 'Maplewood Elementary',
      principalName: 'Dr. Jennifer Martinez',
      contactEmail: 'principal@maplewood.edu',
      contactPhone: '+1 555-0301',
      address: '789 Maple Street, Westfield',
      studentCount: 320,
      requestedBuses: 6,
      subscriptionPlan: 'Premium',
      status: ApprovalStatus.pending,
      submissionDate: DateTime.now().subtract(const Duration(days: 2)),
      lastReviewDate: null,
      reviewedBy: null,
      documents: [
        Document(
            id: '1',
            name: 'School License',
            type: DocumentType.license,
            status: DocumentStatus.verified),
        Document(
            id: '2',
            name: 'Insurance Certificate',
            type: DocumentType.insurance,
            status: DocumentStatus.verified),
        Document(
            id: '3',
            name: 'Accreditation',
            type: DocumentType.accreditation,
            status: DocumentStatus.pending),
        Document(
            id: '4',
            name: 'Safety Certificate',
            type: DocumentType.safety,
            status: DocumentStatus.verified),
      ],
      notes: [],
      estimatedRevenue: 3200.00,
      coordinates: {'lat': 40.7589, 'lng': -73.9851},
    ),
    SchoolApplication(
      id: 'app_002',
      schoolName: 'Oakridge High School',
      principalName: 'Mr. David Thompson',
      contactEmail: 'admin@oakridge.edu',
      contactPhone: '+1 555-0302',
      address: '456 Oak Ridge Road, Hillside',
      studentCount: 850,
      requestedBuses: 12,
      subscriptionPlan: 'Enterprise',
      status: ApprovalStatus.approved,
      submissionDate: DateTime.now().subtract(const Duration(days: 10)),
      lastReviewDate: DateTime.now().subtract(const Duration(days: 3)),
      reviewedBy: 'Super Admin',
      documents: [
        Document(
            id: '5',
            name: 'School License',
            type: DocumentType.license,
            status: DocumentStatus.verified),
        Document(
            id: '6',
            name: 'Insurance Certificate',
            type: DocumentType.insurance,
            status: DocumentStatus.verified),
        Document(
            id: '7',
            name: 'Accreditation',
            type: DocumentType.accreditation,
            status: DocumentStatus.verified),
        Document(
            id: '8',
            name: 'Safety Certificate',
            type: DocumentType.safety,
            status: DocumentStatus.verified),
      ],
      notes: [
        ReviewNote(
            id: '1',
            content: 'All documents verified successfully',
            author: 'Super Admin',
            date: DateTime.now().subtract(const Duration(days: 3))),
        ReviewNote(
            id: '2',
            content: 'School meets all requirements for Enterprise plan',
            author: 'Super Admin',
            date: DateTime.now().subtract(const Duration(days: 3))),
      ],
      estimatedRevenue: 8500.00,
      coordinates: {'lat': 40.7505, 'lng': -73.9934},
    ),
    SchoolApplication(
      id: 'app_003',
      schoolName: 'Pine Valley Academy',
      principalName: 'Ms. Lisa Chen',
      contactEmail: 'contact@pinevalley.edu',
      contactPhone: '+1 555-0303',
      address: '321 Pine Valley Drive, Greenwood',
      studentCount: 180,
      requestedBuses: 3,
      subscriptionPlan: 'Basic',
      status: ApprovalStatus.rejected,
      submissionDate: DateTime.now().subtract(const Duration(days: 15)),
      lastReviewDate: DateTime.now().subtract(const Duration(days: 8)),
      reviewedBy: 'Super Admin',
      documents: [
        Document(
            id: '9',
            name: 'School License',
            type: DocumentType.license,
            status: DocumentStatus.verified),
        Document(
            id: '10',
            name: 'Insurance Certificate',
            type: DocumentType.insurance,
            status: DocumentStatus.rejected),
        Document(
            id: '11',
            name: 'Accreditation',
            type: DocumentType.accreditation,
            status: DocumentStatus.pending),
      ],
      notes: [
        ReviewNote(
            id: '3',
            content: 'Insurance certificate expired',
            author: 'Super Admin',
            date: DateTime.now().subtract(const Duration(days: 8))),
        ReviewNote(
            id: '4',
            content: 'Missing safety certificate',
            author: 'Super Admin',
            date: DateTime.now().subtract(const Duration(days: 8))),
        ReviewNote(
            id: '5',
            content:
                'Application rejected - please resubmit with valid documents',
            author: 'Super Admin',
            date: DateTime.now().subtract(const Duration(days: 8))),
      ],
      estimatedRevenue: 1800.00,
      coordinates: {'lat': 40.7282, 'lng': -74.0776},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'School Approval System',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _exportApprovalReport,
                      icon: const Icon(Icons.download),
                      label: const Text('Export Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                // Search and Filter Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Search applications by school name, principal, or email...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: DropdownButtonFormField<ApprovalStatus>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status Filter',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                        ),
                        items: ApprovalStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Stats Row
                Row(
                  children: [
                    _buildStatCard('Total Applications',
                        _applications.length.toString(), AppColors.info),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard(
                        'Pending',
                        _getApplicationCount(ApprovalStatus.pending).toString(),
                        AppColors.warning),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard(
                        'Approved',
                        _getApplicationCount(ApprovalStatus.approved)
                            .toString(),
                        AppColors.success),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard(
                        'Rejected',
                        _getApplicationCount(ApprovalStatus.rejected)
                            .toString(),
                        AppColors.error),
                    const SizedBox(width: AppConstants.paddingMedium),
                    _buildStatCard(
                        'Est. Revenue',
                        '\$${_getTotalEstimatedRevenue().toStringAsFixed(0)}K',
                        AppColors.purple),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.info,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.info,
              tabs: const [
                Tab(text: 'All Applications'),
                Tab(text: 'Document Review'),
                Tab(text: 'Approval Workflow'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApplicationsList(),
                _buildDocumentReviewTab(),
                _buildApprovalWorkflowTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsList() {
    final filteredApplications = _getFilteredApplications();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: filteredApplications.length,
      itemBuilder: (context, index) {
        final application = filteredApplications[index];
        return _buildApplicationCard(application);
      },
    );
  }

  Widget _buildApplicationCard(SchoolApplication application) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(application.status)
                        .withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Icon(
                    Icons.school,
                    color: _getStatusColor(application.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.schoolName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Principal: ${application.principalName}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${application.studentCount} students • ${application.requestedBuses} buses • ${application.subscriptionPlan}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(application.status)
                        .withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    application.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(application.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Application Details
            Row(
              children: [
                _buildDetailItem(Icons.email, application.contactEmail),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildDetailItem(Icons.phone, application.contactPhone),
                const SizedBox(width: AppConstants.paddingLarge),
                _buildDetailItem(Icons.location_on, application.address),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Document Status
            Row(
              children: [
                const Text('Documents: ',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                ...application.documents.map((doc) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDocumentStatusColor(doc.status)
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: Text(
                        doc.name,
                        style: TextStyle(
                          color: _getDocumentStatusColor(doc.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Action Buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _viewApplicationDetails(application),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
                TextButton.icon(
                  onPressed: () => _reviewDocuments(application),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Review Documents'),
                ),
                const Spacer(),
                if (application.status == ApprovalStatus.pending) ...[
                  TextButton.icon(
                    onPressed: () => _rejectApplication(application),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  ElevatedButton.icon(
                    onPressed: () => _approveApplication(application),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDocumentReviewTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document Review Queue',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Expanded(
            child: ListView.builder(
              itemCount: _applications.length,
              itemBuilder: (context, index) {
                final application = _applications[index];
                return _buildDocumentReviewCard(application);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentReviewCard(SchoolApplication application) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(application.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          ),
          child: Icon(
            Icons.folder_open,
            color: _getStatusColor(application.status),
          ),
        ),
        title: Text(application.schoolName),
        subtitle: Text(
            '${application.documents.length} documents • ${_getPendingDocumentCount(application)} pending review'),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Documents:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                ...application.documents.map(
                    (document) => _buildDocumentItem(document, application)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(Document document, SchoolApplication application) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(
            _getDocumentTypeIcon(document.type),
            color: _getDocumentStatusColor(document.status),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  document.type.displayName,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getDocumentStatusColor(document.status)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Text(
              document.status.displayName,
              style: TextStyle(
                color: _getDocumentStatusColor(document.status),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          if (document.status == DocumentStatus.pending) ...[
            TextButton.icon(
              onPressed: () => _rejectDocument(document, application),
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
            ElevatedButton.icon(
              onPressed: () => _verifyDocument(document, application),
              icon: const Icon(Icons.check),
              label: const Text('Verify'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApprovalWorkflowTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Approval Workflow',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Workflow Steps
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Standard Approval Process',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildWorkflowStep(
                      1,
                      'Application Submission',
                      'School submits application with required documents',
                      true),
                  _buildWorkflowStep(2, 'Document Verification',
                      'Review and verify all submitted documents', true),
                  _buildWorkflowStep(3, 'Background Check',
                      'Verify school credentials and accreditation', true),
                  _buildWorkflowStep(4, 'Final Approval',
                      'Super admin makes final approval decision', true),
                  _buildWorkflowStep(5, 'Account Setup',
                      'Create school account and assign resources', false),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Pending Approvals
          const Text(
            'Pending Approvals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Expanded(
            child: ListView.builder(
              itemCount: _getPendingApplications().length,
              itemBuilder: (context, index) {
                final application = _getPendingApplications()[index];
                return _buildPendingApprovalCard(application);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStep(
      int step, String title, String description, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      step.toString(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalCard(SchoolApplication application) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child:
                  const Icon(Icons.pending_actions, color: AppColors.warning),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.schoolName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Submitted ${_formatDate(application.submissionDate)} • Est. Revenue: \$${application.estimatedRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _reviewApplication(application),
              icon: const Icon(Icons.rate_review),
              label: const Text('Review'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  List<SchoolApplication> _getFilteredApplications() {
    return _applications.where((application) {
      final matchesSearch = _searchQuery.isEmpty ||
          application.schoolName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          application.principalName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          application.contactEmail
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatus == ApprovalStatus.all ||
          application.status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  List<SchoolApplication> _getPendingApplications() {
    return _applications
        .where((app) => app.status == ApprovalStatus.pending)
        .toList();
  }

  int _getApplicationCount(ApprovalStatus status) {
    return _applications.where((app) => app.status == status).length;
  }

  double _getTotalEstimatedRevenue() {
    return _applications.fold<double>(
            0, (sum, app) => sum + app.estimatedRevenue) /
        1000;
  }

  int _getPendingDocumentCount(SchoolApplication application) {
    return application.documents
        .where((doc) => doc.status == DocumentStatus.pending)
        .length;
  }

  Color _getStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return AppColors.warning;
      case ApprovalStatus.approved:
        return AppColors.success;
      case ApprovalStatus.rejected:
        return AppColors.error;
      case ApprovalStatus.all:
        return AppColors.info;
    }
  }

  Color _getDocumentStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.verified:
        return AppColors.success;
      case DocumentStatus.pending:
        return AppColors.warning;
      case DocumentStatus.rejected:
        return AppColors.error;
    }
  }

  IconData _getDocumentTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.license:
        return Icons.verified_user;
      case DocumentType.insurance:
        return Icons.security;
      case DocumentType.accreditation:
        return Icons.school;
      case DocumentType.safety:
        return Icons.health_and_safety;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Action Methods
  void _exportApprovalReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Approval Report'),
        content: const Text(
            'Approval report export functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _viewApplicationDetails(SchoolApplication application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(application.schoolName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Principal: ${application.principalName}'),
            Text('Email: ${application.contactEmail}'),
            Text('Phone: ${application.contactPhone}'),
            Text('Address: ${application.address}'),
            Text('Students: ${application.studentCount}'),
            Text('Requested Buses: ${application.requestedBuses}'),
            Text('Plan: ${application.subscriptionPlan}'),
            Text('Status: ${application.status.displayName}'),
            Text('Submitted: ${_formatDate(application.submissionDate)}'),
            Text(
                'Est. Revenue: \$${application.estimatedRevenue.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _reviewDocuments(SchoolApplication application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review Documents - ${application.schoolName}'),
        content:
            const Text('Document review interface would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _approveApplication(SchoolApplication application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Application'),
        content:
            Text('Are you sure you want to approve ${application.schoolName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final index =
                    _applications.indexWhere((app) => app.id == application.id);
                if (index != -1) {
                  _applications[index] = application.copyWith(
                    status: ApprovalStatus.approved,
                    lastReviewDate: DateTime.now(),
                    reviewedBy: 'Super Admin',
                  );
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('${application.schoolName} has been approved')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectApplication(SchoolApplication application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content:
            Text('Are you sure you want to reject ${application.schoolName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final index =
                    _applications.indexWhere((app) => app.id == application.id);
                if (index != -1) {
                  _applications[index] = application.copyWith(
                    status: ApprovalStatus.rejected,
                    lastReviewDate: DateTime.now(),
                    reviewedBy: 'Super Admin',
                  );
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('${application.schoolName} has been rejected')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _verifyDocument(Document document, SchoolApplication application) {
    setState(() {
      final appIndex =
          _applications.indexWhere((app) => app.id == application.id);
      if (appIndex != -1) {
        final docIndex = _applications[appIndex]
            .documents
            .indexWhere((doc) => doc.id == document.id);
        if (docIndex != -1) {
          _applications[appIndex].documents[docIndex] =
              document.copyWith(status: DocumentStatus.verified);
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${document.name} has been verified')),
    );
  }

  void _rejectDocument(Document document, SchoolApplication application) {
    setState(() {
      final appIndex =
          _applications.indexWhere((app) => app.id == application.id);
      if (appIndex != -1) {
        final docIndex = _applications[appIndex]
            .documents
            .indexWhere((doc) => doc.id == document.id);
        if (docIndex != -1) {
          _applications[appIndex].documents[docIndex] =
              document.copyWith(status: DocumentStatus.rejected);
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${document.name} has been rejected')),
    );
  }

  void _reviewApplication(SchoolApplication application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review Application - ${application.schoolName}'),
        content: const Text(
            'Application review interface would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Data Models
enum ApprovalStatus {
  all('All'),
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const ApprovalStatus(this.displayName);
  final String displayName;
}

enum DocumentStatus {
  verified('Verified'),
  pending('Pending'),
  rejected('Rejected');

  const DocumentStatus(this.displayName);
  final String displayName;
}

enum DocumentType {
  license('School License'),
  insurance('Insurance Certificate'),
  accreditation('Accreditation'),
  safety('Safety Certificate');

  const DocumentType(this.displayName);
  final String displayName;
}

class SchoolApplication {
  final String id;
  final String schoolName;
  final String principalName;
  final String contactEmail;
  final String contactPhone;
  final String address;
  final int studentCount;
  final int requestedBuses;
  final String subscriptionPlan;
  final ApprovalStatus status;
  final DateTime submissionDate;
  final DateTime? lastReviewDate;
  final String? reviewedBy;
  final List<Document> documents;
  final List<ReviewNote> notes;
  final double estimatedRevenue;
  final Map<String, double> coordinates;

  SchoolApplication({
    required this.id,
    required this.schoolName,
    required this.principalName,
    required this.contactEmail,
    required this.contactPhone,
    required this.address,
    required this.studentCount,
    required this.requestedBuses,
    required this.subscriptionPlan,
    required this.status,
    required this.submissionDate,
    this.lastReviewDate,
    this.reviewedBy,
    required this.documents,
    required this.notes,
    required this.estimatedRevenue,
    required this.coordinates,
  });

  SchoolApplication copyWith({
    String? id,
    String? schoolName,
    String? principalName,
    String? contactEmail,
    String? contactPhone,
    String? address,
    int? studentCount,
    int? requestedBuses,
    String? subscriptionPlan,
    ApprovalStatus? status,
    DateTime? submissionDate,
    DateTime? lastReviewDate,
    String? reviewedBy,
    List<Document>? documents,
    List<ReviewNote>? notes,
    double? estimatedRevenue,
    Map<String, double>? coordinates,
  }) {
    return SchoolApplication(
      id: id ?? this.id,
      schoolName: schoolName ?? this.schoolName,
      principalName: principalName ?? this.principalName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      studentCount: studentCount ?? this.studentCount,
      requestedBuses: requestedBuses ?? this.requestedBuses,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      status: status ?? this.status,
      submissionDate: submissionDate ?? this.submissionDate,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      documents: documents ?? this.documents,
      notes: notes ?? this.notes,
      estimatedRevenue: estimatedRevenue ?? this.estimatedRevenue,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}

class Document {
  final String id;
  final String name;
  final DocumentType type;
  final DocumentStatus status;

  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
  });

  Document copyWith({
    String? id,
    String? name,
    DocumentType? type,
    DocumentStatus? status,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }
}

class ReviewNote {
  final String id;
  final String content;
  final String author;
  final DateTime date;

  ReviewNote({
    required this.id,
    required this.content,
    required this.author,
    required this.date,
  });
}
