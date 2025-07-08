import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class ChildCheckInSystem extends StatefulWidget {
  final CheckInMode mode;
  final Function(CheckInResult) onCheckInComplete;
  final List<Child> children;

  const ChildCheckInSystem({
    super.key,
    required this.mode,
    required this.onCheckInComplete,
    required this.children,
  });

  @override
  State<ChildCheckInSystem> createState() => _ChildCheckInSystemState();
}

class _ChildCheckInSystemState extends State<ChildCheckInSystem>
    with TickerProviderStateMixin {
  late TabController _tabController;
  CameraController? _cameraController;
  QRViewController? _qrController;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _isProcessing = false;
  String? _detectedQRCode;
  Child? _selectedChild;
  CheckInType _checkInType = CheckInType.pickup;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Child Check-In System'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.face), text: 'Face ID'),
            Tab(icon: Icon(Icons.qr_code), text: 'QR Code'),
            Tab(icon: Icon(Icons.list), text: 'Manual'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Check-in Type Selector
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Check-in Type:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: SegmentedButton<CheckInType>(
                    segments: const [
                      ButtonSegment(
                        value: CheckInType.pickup,
                        label: Text('Pickup'),
                        icon: Icon(Icons.login),
                      ),
                      ButtonSegment(
                        value: CheckInType.dropoff,
                        label: Text('Drop-off'),
                        icon: Icon(Icons.logout),
                      ),
                    ],
                    selected: {_checkInType},
                    onSelectionChanged: (Set<CheckInType> selection) {
                      setState(() {
                        _checkInType = selection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFaceIDTab(),
                _buildQRCodeTab(),
                _buildManualTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceIDTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          const Text(
            'Face ID Check-In',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          const Text(
            'Position the child\'s face in the camera frame for biometric verification',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Camera Preview
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                child: _cameraController?.value.isInitialized == true
                    ? Stack(
                        children: [
                          CameraPreview(_cameraController!),
                          // Face detection overlay
                          Center(
                            child: Container(
                              width: 200,
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.success, width: 2),
                                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                              ),
                              child: const Center(
                                child: Text(
                                  'Align face here',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    backgroundColor: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Capture Button
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _captureFaceID,
            icon: _isProcessing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt),
            label: Text(_isProcessing ? 'Processing...' : 'Capture & Verify'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          const Text(
            'QR Code Check-In',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          const Text(
            'Scan the child\'s QR code for quick check-in',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          // QR Scanner
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                child: QRView(
                  key: GlobalKey(debugLabel: 'QR'),
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: AppColors.success,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 250,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          if (_detectedQRCode != null) ...[
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Text(
                      'QR Code Detected: $_detectedQRCode',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            ElevatedButton.icon(
              onPressed: _processQRCheckIn,
              icon: const Icon(Icons.verified),
              label: const Text('Confirm Check-In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          const Text(
            'Manual Check-In',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          const Text(
            'Select a child from the list for manual check-in',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Children List
          Expanded(
            child: ListView.builder(
              itemCount: widget.children.length,
              itemBuilder: (context, index) {
                final child = widget.children[index];
                final isSelected = _selectedChild?.id == child.id;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: child.photoUrl != null 
                          ? NetworkImage(child.photoUrl!) 
                          : null,
                      child: child.photoUrl == null 
                          ? Text(child.name[0])
                          : null,
                    ),
                    title: Text(
                      child.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text('Grade ${child.grade} • ${child.parentName}'),
                    trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedChild = isSelected ? null : child;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          
          if (_selectedChild != null) ...[
            const SizedBox(height: AppConstants.paddingMedium),
            ElevatedButton.icon(
              onPressed: _processManualCheckIn,
              icon: const Icon(Icons.how_to_reg),
              label: Text('Check-In ${_selectedChild!.name}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Methods
  void _onQRViewCreated(QRViewController controller) {
    _qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing && scanData.code != null) {
        setState(() {
          _detectedQRCode = scanData.code;
        });
      }
    });
  }

  Future<void> _captureFaceID() async {
    if (_cameraController == null || _isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Check if biometric authentication is available
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        _showError('Biometric authentication not available on this device');
        return;
      }

      // Capture image
      final XFile image = await _cameraController!.takePicture();
      
      // Simulate face recognition processing
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real implementation, you would:
      // 1. Send the image to a face recognition service
      // 2. Compare with stored child photos
      // 3. Return the matched child
      
      final matchedChild = widget.children.isNotEmpty ? widget.children.first : null;
      
      if (matchedChild != null) {
        _completeCheckIn(matchedChild, CheckInMethod.faceId, image.path);
      } else {
        _showError('No matching child found. Please try again or use manual check-in.');
      }
    } catch (e) {
      _showError('Face ID capture failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _processQRCheckIn() {
    if (_detectedQRCode == null) return;
    
    // Find child by QR code
    final child = widget.children.firstWhere(
      (c) => c.qrCode == _detectedQRCode,
      orElse: () => throw Exception('Child not found'),
    );
    
    _completeCheckIn(child, CheckInMethod.qrCode, null);
  }

  void _processManualCheckIn() {
    if (_selectedChild == null) return;
    
    _completeCheckIn(_selectedChild!, CheckInMethod.manual, null);
  }

  void _completeCheckIn(Child child, CheckInMethod method, String? photoPath) {
    final result = CheckInResult(
      child: child,
      method: method,
      type: _checkInType,
      timestamp: DateTime.now(),
      photoPath: photoPath,
      location: 'Bus Stop A', // In real app, get GPS location
    );
    
    widget.onCheckInComplete(result);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${child.name} checked ${_checkInType.name} successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
    
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cameraController?.dispose();
    _qrController?.dispose();
    super.dispose();
  }
}

// Data Models
enum CheckInMode { driver, parent, admin }
enum CheckInType { pickup, dropoff }
enum CheckInMethod { faceId, qrCode, manual }

class Child {
  final String id;
  final String name;
  final String grade;
  final String parentName;
  final String? photoUrl;
  final String qrCode;

  Child({
    required this.id,
    required this.name,
    required this.grade,
    required this.parentName,
    this.photoUrl,
    required this.qrCode,
  });
}

class CheckInResult {
  final Child child;
  final CheckInMethod method;
  final CheckInType type;
  final DateTime timestamp;
  final String? photoPath;
  final String location;

  CheckInResult({
    required this.child,
    required this.method,
    required this.type,
    required this.timestamp,
    this.photoPath,
    required this.location,
  });
}
