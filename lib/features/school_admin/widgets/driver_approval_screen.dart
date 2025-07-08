import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class DriverApprovalScreen extends StatefulWidget {
  const DriverApprovalScreen({super.key});

  @override
  State<DriverApprovalScreen> createState() => _DriverApprovalScreenState();
}

class _DriverApprovalScreenState extends State<DriverApprovalScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final List<DriverApplication> _driverApplications = [
    DriverApplication(
      id: '1',
      name: 'Michael Johnson',
      email: 'michael.johnson@email.com',
      phone: '+1 234 567 8900',
      licenseNumber: 'DL123456789',
      licenseExpiry: DateTime(2025, 12, 31),
      experience: '5 years',
      status: ApplicationStatus.pending,
      submittedDate: DateTime.now().subtract(const Duration(days: 2)),
      documents: ['License Copy', 'Background Check', 'Medical Certificate'],
      backgroundCheckStatus: 'Completed - Clear',
      medicalCertStatus: 'Valid until 2025',
    ),
    DriverApplication(
      id: '2',
      name: 'Sarah Williams',
      email: 'sarah.williams@email.com',
      phone: '+1 234 567 8901',
      licenseNumber: 'DL987654321',
      licenseExpiry: DateTime(2026, 6, 15),
      experience: '8 years',
      status: ApplicationStatus.approved,
      submittedDate: DateTime.now().subtract(const Duration(days: 5)),
      documents: [
        'License Copy',
        'Background Check',
        'Medical Certificate',
        'References'
      ],
      backgroundCheckStatus: 'Completed - Clear',
      medicalCertStatus: 'Valid until 2026',
    ),
  ];

  final List<VehicleRegistration> _vehicleRegistrations = [
    VehicleRegistration(
      id: '1',
      make: 'Blue Bird',
      model: 'Vision',
      year: 2022,
      plateNumber: 'SCH-001',
      capacity: 45,
      status: RegistrationStatus.pending,
      submittedDate: DateTime.now().subtract(const Duration(days: 1)),
      documents: ['Registration', 'Insurance', 'Safety Inspection'],
      insuranceExpiry: DateTime(2025, 8, 30),
      inspectionExpiry: DateTime(2024, 12, 15),
    ),
    VehicleRegistration(
      id: '2',
      make: 'Thomas Built',
      model: 'Saf-T-Liner',
      year: 2021,
      plateNumber: 'SCH-002',
      capacity: 40,
      status: RegistrationStatus.approved,
      submittedDate: DateTime.now().subtract(const Duration(days: 7)),
      documents: [
        'Registration',
        'Insurance',
        'Safety Inspection',
        'Maintenance Records'
      ],
      insuranceExpiry: DateTime(2025, 10, 20),
      inspectionExpiry: DateTime(2024, 11, 30),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver & Vehicle Approvals'),
        backgroundColor: AppColors.schoolAdminColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Driver Applications'),
            Tab(text: 'Vehicle Registrations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDriverApplicationsTab(),
          _buildVehicleRegistrationsTab(),
        ],
      ),
    );
  }

  Widget _buildDriverApplicationsTab() {
    return Column(
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          color: AppColors.surfaceVariant,
          child: Row(
            children: [
              Expanded(
                  child: _buildStatCard('Total',
                      _driverApplications.length.toString(), AppColors.info)),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                  child: _buildStatCard(
                      'Pending',
                      _getDriverApplicationCount(ApplicationStatus.pending)
                          .toString(),
                      AppColors.warning)),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                  child: _buildStatCard(
                      'Approved',
                      _getDriverApplicationCount(ApplicationStatus.approved)
                          .toString(),
                      AppColors.success)),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                  child: _buildStatCard(
                      'Rejected',
                      _getDriverApplicationCount(ApplicationStatus.rejected)
                          .toString(),
                      AppColors.error)),
            ],
          ),
        ),

        // Applications List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium),
            itemCount: _driverApplications.length,
            itemBuilder: (context, index) {
              final application = _driverApplications[index];
              return _buildDriverApplicationCard(application);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleRegistrationsTab() {
    return Column(
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          color: AppColors.surfaceVariant,
          child: Row(
            children: [
              Expanded(
                  child: _buildStatCard('Total',
                      _vehicleRegistrations.length.toString(), AppColors.info)),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                  child: _buildStatCard(
                      'Pending',
                      _getVehicleRegistrationCount(RegistrationStatus.pending)
                          .toString(),
                      AppColors.warning)),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                  child: _buildStatCard(
                      'Approved',
                      _getVehicleRegistrationCount(RegistrationStatus.approved)
                          .toString(),
                      AppColors.success)),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                  child: _buildStatCard(
                      'Rejected',
                      _getVehicleRegistrationCount(RegistrationStatus.rejected)
                          .toString(),
                      AppColors.error)),
            ],
          ),
        ),

        // Registrations List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium),
            itemCount: _vehicleRegistrations.length,
            itemBuilder: (context, index) {
              final registration = _vehicleRegistrations[index];
              return _buildVehicleRegistrationCard(registration);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverApplicationCard(DriverApplication application) {
    final statusColor = _getApplicationStatusColor(application.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.schoolAdminColor,
                  child: Text(
                    application.name[0],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'License: ${application.licenseNumber}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                      Text(
                        'Experience: ${application.experience}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    application.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            if (application.status == ApplicationStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectApplication(application),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveApplication(application),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper Methods
  Color _getApplicationStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return AppColors.warning;
      case ApplicationStatus.approved:
        return AppColors.success;
      case ApplicationStatus.rejected:
        return AppColors.error;
    }
  }

  Color _getRegistrationStatusColor(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.pending:
        return AppColors.warning;
      case RegistrationStatus.approved:
        return AppColors.success;
      case RegistrationStatus.rejected:
        return AppColors.error;
    }
  }

  int _getDriverApplicationCount(ApplicationStatus status) {
    return _driverApplications.where((app) => app.status == status).length;
  }

  int _getVehicleRegistrationCount(RegistrationStatus status) {
    return _vehicleRegistrations.where((reg) => reg.status == status).length;
  }

  void _approveApplication(DriverApplication application) {
    setState(() {
      final index =
          _driverApplications.indexWhere((app) => app.id == application.id);
      if (index != -1) {
        _driverApplications[index] =
            application.copyWith(status: ApplicationStatus.approved);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${application.name} application approved'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _rejectApplication(DriverApplication application) {
    setState(() {
      final index =
          _driverApplications.indexWhere((app) => app.id == application.id);
      if (index != -1) {
        _driverApplications[index] =
            application.copyWith(status: ApplicationStatus.rejected);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${application.name} application rejected'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _approveRegistration(VehicleRegistration registration) {
    setState(() {
      final index =
          _vehicleRegistrations.indexWhere((reg) => reg.id == registration.id);
      if (index != -1) {
        _vehicleRegistrations[index] =
            registration.copyWith(status: RegistrationStatus.approved);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vehicle ${registration.plateNumber} approved'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _rejectRegistration(VehicleRegistration registration) {
    setState(() {
      final index =
          _vehicleRegistrations.indexWhere((reg) => reg.id == registration.id);
      if (index != -1) {
        _vehicleRegistrations[index] =
            registration.copyWith(status: RegistrationStatus.rejected);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vehicle ${registration.plateNumber} rejected'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Widget _buildVehicleRegistrationCard(VehicleRegistration registration) {
    final statusColor = _getRegistrationStatusColor(registration.status);

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
                    color: AppColors.schoolAdminColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: const Icon(Icons.directions_bus,
                      color: AppColors.schoolAdminColor),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${registration.year} ${registration.make} ${registration.model}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Plate: ${registration.plateNumber} • Capacity: ${registration.capacity}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    registration.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            if (registration.status == RegistrationStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRegistration(registration),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRegistration(registration),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum ApplicationStatus { pending, approved, rejected }

enum RegistrationStatus { pending, approved, rejected }

class DriverApplication {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String experience;
  final ApplicationStatus status;
  final DateTime submittedDate;
  final List<String> documents;
  final String backgroundCheckStatus;
  final String medicalCertStatus;

  DriverApplication({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.experience,
    required this.status,
    required this.submittedDate,
    required this.documents,
    required this.backgroundCheckStatus,
    required this.medicalCertStatus,
  });

  DriverApplication copyWith({ApplicationStatus? status}) {
    return DriverApplication(
      id: id,
      name: name,
      email: email,
      phone: phone,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      experience: experience,
      status: status ?? this.status,
      submittedDate: submittedDate,
      documents: documents,
      backgroundCheckStatus: backgroundCheckStatus,
      medicalCertStatus: medicalCertStatus,
    );
  }
}

class VehicleRegistration {
  final String id;
  final String make;
  final String model;
  final int year;
  final String plateNumber;
  final int capacity;
  final RegistrationStatus status;
  final DateTime submittedDate;
  final List<String> documents;
  final DateTime insuranceExpiry;
  final DateTime inspectionExpiry;

  VehicleRegistration({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.capacity,
    required this.status,
    required this.submittedDate,
    required this.documents,
    required this.insuranceExpiry,
    required this.inspectionExpiry,
  });

  VehicleRegistration copyWith({RegistrationStatus? status}) {
    return VehicleRegistration(
      id: id,
      make: make,
      model: model,
      year: year,
      plateNumber: plateNumber,
      capacity: capacity,
      status: status ?? this.status,
      submittedDate: submittedDate,
      documents: documents,
      insuranceExpiry: insuranceExpiry,
      inspectionExpiry: inspectionExpiry,
    );
  }
}
