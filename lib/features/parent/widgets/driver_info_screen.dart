import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class DriverInfoScreen extends StatefulWidget {
  final String driverId;
  final String busId;
  
  const DriverInfoScreen({
    super.key,
    required this.driverId,
    required this.busId,
  });

  @override
  State<DriverInfoScreen> createState() => _DriverInfoScreenState();
}

class _DriverInfoScreenState extends State<DriverInfoScreen> {
  // Mock driver data
  final Map<String, dynamic> _driverData = {
    'id': 'driver_001',
    'name': 'Mike Wilson',
    'profileImage': '',
    'phone': '+1 234 567 8901',
    'email': 'mike.wilson@andco.com',
    'experience': '8 years',
    'rating': 4.8,
    'totalRatings': 156,
    'licenseNumber': 'DL123456789',
    'licenseExpiry': '2025-12-31',
    'emergencyContact': '+1 234 567 8902',
    'languages': ['English', 'Spanish'],
    'certifications': ['Defensive Driving', 'First Aid', 'Child Safety'],
    'joinDate': '2020-03-15',
    'totalTrips': 2340,
    'safetyScore': 98,
  };

  final Map<String, dynamic> _vehicleData = {
    'busNumber': 'BUS-001',
    'make': 'Blue Bird',
    'model': 'Vision',
    'year': 2022,
    'capacity': 30,
    'plateNumber': 'SCH-001-TX',
    'color': 'Yellow',
    'features': ['GPS Tracking', 'Security Cameras', 'First Aid Kit', 'Fire Extinguisher', 'Emergency Exit'],
    'lastInspection': '2024-01-15',
    'nextInspection': '2024-07-15',
    'mileage': 45000,
    'fuelType': 'Diesel',
    'insuranceExpiry': '2024-12-31',
  };

  double _userRating = 0;
  final _reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver & Vehicle Info'),
        backgroundColor: AppColors.parentColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _callDriver,
            icon: const Icon(Icons.phone),
          ),
          IconButton(
            onPressed: _messageDriver,
            icon: const Icon(Icons.message),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Profile Card
            _buildDriverProfileCard(),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Vehicle Information Card
            _buildVehicleInfoCard(),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Rating & Reviews Section
            _buildRatingSection(),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Safety & Certifications
            _buildSafetyCertificationsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.driverColor.withOpacity(0.1),
                  backgroundImage: _driverData['profileImage'].isNotEmpty 
                      ? AssetImage(_driverData['profileImage']) 
                      : null,
                  child: _driverData['profileImage'].isEmpty
                      ? Text(
                          _driverData['name'][0],
                          style: TextStyle(
                            color: AppColors.driverColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                
                // Driver Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverData['name'],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_driverData['rating']} (${_driverData['totalRatings']} reviews)',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_driverData['experience']} experience',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Active',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Contact Information
            Row(
              children: [
                Expanded(
                  child: _buildContactInfo(
                    'Phone',
                    _driverData['phone'],
                    Icons.phone,
                    () => _callDriver(),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: _buildContactInfo(
                    'Email',
                    _driverData['email'],
                    Icons.email,
                    () => _emailDriver(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Trips',
                    _driverData['totalTrips'].toString(),
                    Icons.directions_bus,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Safety Score',
                    '${_driverData['safetyScore']}%',
                    Icons.shield,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Languages',
                    _driverData['languages'].length.toString(),
                    Icons.language,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_bus,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Text(
                  'Vehicle Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Vehicle Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVehicleDetailRow('Bus Number', _vehicleData['busNumber']),
                      _buildVehicleDetailRow('Make & Model', '${_vehicleData['make']} ${_vehicleData['model']}'),
                      _buildVehicleDetailRow('Year', _vehicleData['year'].toString()),
                      _buildVehicleDetailRow('Capacity', '${_vehicleData['capacity']} students'),
                      _buildVehicleDetailRow('Plate Number', _vehicleData['plateNumber']),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVehicleDetailRow('Mileage', '${_vehicleData['mileage']} miles'),
                      _buildVehicleDetailRow('Fuel Type', _vehicleData['fuelType']),
                      _buildVehicleDetailRow('Last Inspection', _vehicleData['lastInspection']),
                      _buildVehicleDetailRow('Next Inspection', _vehicleData['nextInspection']),
                      _buildVehicleDetailRow('Insurance Expiry', _vehicleData['insuranceExpiry']),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Safety Features
            Text(
              'Safety Features',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _vehicleData['features'].map<Widget>((feature) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    feature,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate This Driver',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Star Rating
            Row(
              children: [
                Text(
                  'Your Rating:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Row(
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _userRating = index + 1.0;
                        });
                      },
                      child: Icon(
                        index < _userRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Text(
                  _userRating > 0 ? _userRating.toString() : 'Not rated',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Review Text Field
            TextFormField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Write a review (optional)',
                hintText: 'Share your experience with this driver...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Submit Rating Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _userRating > 0 ? _submitRating : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.parentColor,
                ),
                child: const Text('Submit Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCertificationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety & Certifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Certifications
            ...(_driverData['certifications'] as List).map((cert) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(cert),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // License Information
            _buildLicenseInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVehicleDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseInfo() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'License Information',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'License #: ${_driverData['licenseNumber']}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Expires: ${_driverData['licenseExpiry']}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _callDriver() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${_driverData['name']}...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _messageDriver() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with ${_driverData['name']}...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _emailDriver() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening email to ${_driverData['name']}...'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  void _submitRating() {
    if (_userRating > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rating submitted: $_userRating stars'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Clear the form
      setState(() {
        _userRating = 0;
        _reviewController.clear();
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
