import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class LiveCameraFeed extends StatefulWidget {
  final String busId;
  final String routeName;
  final bool isParentView;
  final List<String> authorizedParentIds;

  const LiveCameraFeed({
    super.key,
    required this.busId,
    required this.routeName,
    this.isParentView = true,
    required this.authorizedParentIds,
  });

  @override
  State<LiveCameraFeed> createState() => _LiveCameraFeedState();
}

class _LiveCameraFeedState extends State<LiveCameraFeed>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<CameraController> _cameraControllers = [];
  List<CameraDescription> _cameras = [];
  
  bool _isStreaming = false;
  bool _isRecording = false;
  bool _audioEnabled = false;
  bool _privacyModeEnabled = false;
  int _activeCamera = 0;
  int _viewerCount = 0;
  
  final List<CameraPosition> _cameraPositions = [
    CameraPosition.front,
    CameraPosition.middle,
    CameraPosition.rear,
    CameraPosition.driver,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeCameras();
    _startViewerCountSimulation();
  }

  Future<void> _initializeCameras() async {
    try {
      // Request camera permissions
      final cameraPermission = await Permission.camera.request();
      final microphonePermission = await Permission.microphone.request();
      
      if (cameraPermission != PermissionStatus.granted) {
        _showError('Camera permission is required for live feed');
        return;
      }

      _cameras = await availableCameras();
      
      // Initialize multiple camera controllers for different positions
      for (int i = 0; i < _cameraPositions.length && i < _cameras.length; i++) {
        final controller = CameraController(
          _cameras[i],
          ResolutionPreset.medium,
          enableAudio: microphonePermission == PermissionStatus.granted,
        );
        
        await controller.initialize();
        _cameraControllers.add(controller);
      }
      
      if (mounted) {
        setState(() {
          _isStreaming = true;
        });
      }
    } catch (e) {
      _showError('Failed to initialize cameras: $e');
    }
  }

  void _startViewerCountSimulation() {
    // Simulate real-time viewer count updates
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _viewerCount = widget.authorizedParentIds.length + (DateTime.now().second % 3);
        });
        _startViewerCountSimulation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Feed - ${widget.routeName}'),
            Text(
              'Bus ${widget.busId}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          // Viewer count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility, size: 16),
                const SizedBox(width: 4),
                Text('$_viewerCount'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Privacy mode toggle
          IconButton(
            onPressed: _togglePrivacyMode,
            icon: Icon(
              _privacyModeEnabled ? Icons.visibility_off : Icons.visibility,
              color: _privacyModeEnabled ? Colors.red : Colors.white,
            ),
          ),
        ],
        bottom: widget.isParentView ? null : TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Live Feed'),
            Tab(text: 'Controls'),
          ],
        ),
      ),
      body: widget.isParentView 
          ? _buildParentView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLiveFeedView(),
                _buildControlsView(),
              ],
            ),
    );
  }

  Widget _buildParentView() {
    return Column(
      children: [
        // Privacy notice
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          color: AppColors.info.withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(Icons.security, color: AppColors.info),
              const SizedBox(width: AppConstants.paddingSmall),
              const Expanded(
                child: Text(
                  'This feed is encrypted and only visible to authorized parents',
                  style: TextStyle(color: AppColors.info, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        
        // Main camera feed
        Expanded(
          child: _buildCameraView(),
        ),
        
        // Camera selector and controls
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          color: Colors.black87,
          child: Column(
            children: [
              // Camera position selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _cameraPositions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final position = entry.value;
                  final isActive = _activeCamera == index;
                  
                  return GestureDetector(
                    onTap: () => _switchCamera(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? AppColors.primary : Colors.white54,
                        ),
                      ),
                      child: Text(
                        position.displayName,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Audio toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _toggleAudio,
                    icon: Icon(
                      _audioEnabled ? Icons.volume_up : Icons.volume_off,
                      color: _audioEnabled ? Colors.white : Colors.white54,
                    ),
                  ),
                  Text(
                    _audioEnabled ? 'Audio On' : 'Audio Off',
                    style: TextStyle(
                      color: _audioEnabled ? Colors.white : Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveFeedView() {
    return _buildCameraView();
  }

  Widget _buildCameraView() {
    if (_privacyModeEnabled) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility_off, size: 64, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'Privacy Mode Enabled',
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
              Text(
                'Camera feed is temporarily disabled',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isStreaming || _cameraControllers.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Connecting to camera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _cameraControllers[_activeCamera];
    if (!controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.previewSize!.height,
              height: controller.value.previewSize!.width,
              child: CameraPreview(controller),
            ),
          ),
        ),
        
        // Overlay information
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Timestamp
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getCurrentTime(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsView() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Camera Controls',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Recording controls
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recording',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isRecording ? _stopRecording : _startRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
                        label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording ? Colors.red : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      if (_isRecording) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text('REC', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Privacy controls
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy & Safety',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  SwitchListTile(
                    title: const Text('Privacy Mode', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Temporarily disable camera feed', style: TextStyle(color: Colors.white70)),
                    value: _privacyModeEnabled,
                    onChanged: (value) => _togglePrivacyMode(),
                    activeColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    title: const Text('Audio Recording', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Enable audio in recordings', style: TextStyle(color: Colors.white70)),
                    value: _audioEnabled,
                    onChanged: (value) => _toggleAudio(),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          
          // Emergency controls
          Card(
            color: Colors.red[900],
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emergency',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  ElevatedButton.icon(
                    onPressed: _triggerEmergencyAlert,
                    icon: const Icon(Icons.emergency),
                    label: const Text('Emergency Alert'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Methods
  void _switchCamera(int index) {
    if (index < _cameraControllers.length) {
      setState(() {
        _activeCamera = index;
      });
    }
  }

  void _toggleAudio() {
    setState(() {
      _audioEnabled = !_audioEnabled;
    });
  }

  void _togglePrivacyMode() {
    setState(() {
      _privacyModeEnabled = !_privacyModeEnabled;
    });
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    // Implement recording logic
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    // Implement stop recording logic
  }

  void _triggerEmergencyAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert'),
        content: const Text('This will immediately notify all parents and authorities. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger emergency alert
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency alert sent to all parents and authorities'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
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
    for (final controller in _cameraControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

// Data Models
enum CameraPosition {
  front('Front'),
  middle('Middle'),
  rear('Rear'),
  driver('Driver');

  const CameraPosition(this.displayName);
  final String displayName;
}
