import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/face_detection_service.dart';
import '../../core/theme/app_colors.dart';

/// Widget for face detection and student verification
class FaceDetectionWidget extends ConsumerStatefulWidget {
  final Function(FaceAnalysisResult)? onFaceDetected;
  final Function(File)? onPhotoTaken;
  final VoidCallback? onCancel;
  final bool showInstructions;
  final String? instructionText;

  const FaceDetectionWidget({
    super.key,
    this.onFaceDetected,
    this.onPhotoTaken,
    this.onCancel,
    this.showInstructions = true,
    this.instructionText,
  });

  @override
  ConsumerState<FaceDetectionWidget> createState() =>
      _FaceDetectionWidgetState();
}

class _FaceDetectionWidgetState extends ConsumerState<FaceDetectionWidget> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  Timer? _detectionTimer;

  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _isCapturing = false;

  List<Face> _detectedFaces = [];
  FaceAnalysisResult? _lastAnalysis;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Stack(
          children: [
            // Camera preview
            if (_isInitialized && _cameraController != null)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else
              Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

            // Face detection overlay
            if (_detectedFaces.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: FaceDetectionPainter(_detectedFaces, _lastAnalysis),
                ),
              ),

            // Instructions overlay
            if (widget.showInstructions)
              Positioned(
                top: AppConstants.paddingMedium,
                left: AppConstants.paddingMedium,
                right: AppConstants.paddingMedium,
                child: _buildInstructionsPanel(),
              ),

            // Error message
            if (_errorMessage != null)
              Positioned(
                top: AppConstants.paddingMedium,
                left: AppConstants.paddingMedium,
                right: AppConstants.paddingMedium,
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.9),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Controls
            Positioned(
              bottom: AppConstants.paddingMedium,
              left: AppConstants.paddingMedium,
              right: AppConstants.paddingMedium,
              child: _buildControlsPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsPanel() {
    String instruction =
        widget.instructionText ?? 'Position your face in the frame';
    Color backgroundColor = Colors.blue.withOpacity(0.8);
    IconData icon = Icons.face;

    if (_lastAnalysis != null) {
      if (!_lastAnalysis!.isGoodQuality) {
        instruction = 'Keep your eyes open and look at the camera';
        backgroundColor = Colors.orange.withOpacity(0.8);
        icon = Icons.visibility;
      } else if (!_lastAnalysis!.isFacingCamera) {
        instruction = 'Face the camera directly';
        backgroundColor = Colors.orange.withOpacity(0.8);
        icon = Icons.rotate_left;
      } else {
        instruction = 'Perfect! Hold still...';
        backgroundColor = Colors.green.withOpacity(0.8);
        icon = Icons.check_circle;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsPanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Cancel button
        FloatingActionButton(
          heroTag: 'cancel',
          backgroundColor: Colors.red,
          onPressed: widget.onCancel,
          child: const Icon(Icons.close, color: Colors.white),
        ),

        // Capture button
        FloatingActionButton(
          heroTag: 'capture',
          backgroundColor: _canCapture() ? AppColors.primary : Colors.grey,
          onPressed: _canCapture() ? _capturePhoto : null,
          child: _isCapturing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.camera_alt, color: Colors.white),
        ),

        // Switch camera button
        FloatingActionButton(
          heroTag: 'switch',
          backgroundColor: Colors.grey[700],
          onPressed: _switchCamera,
          child: const Icon(Icons.flip_camera_ios, color: Colors.white),
        ),
      ],
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
        });
        return;
      }

      // Use front camera if available, otherwise use first camera
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        _startFaceDetection();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  void _startFaceDetection() {
    _detectionTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isDetecting &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        _detectFaces();
      }
    });
  }

  Future<void> _detectFaces() async {
    if (_isDetecting || _cameraController == null) return;

    setState(() {
      _isDetecting = true;
    });

    try {
      final image = await _cameraController!.takePicture();

      final faces = await FaceDetectionService.instance
          .detectFacesFromFile(File(image.path));

      if (mounted) {
        setState(() {
          _detectedFaces = faces;
        });

        if (faces.isNotEmpty) {
          final analysis = await FaceDetectionService.instance
              .analyzeFaceForVerification(faces.first);

          if (mounted) {
            setState(() {
              _lastAnalysis = analysis;
            });

            widget.onFaceDetected?.call(analysis);
          }
        }
      }

      // Clean up temporary image
      await File(image.path).delete();
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _cameraController!.takePicture();
      final imageFile = File(image.path);

      widget.onPhotoTaken?.call(imageFile);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture photo: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentCamera = _cameraController?.description;
    final newCamera = _cameras!.firstWhere(
      (camera) => camera != currentCamera,
      orElse: () => _cameras!.first,
    );

    await _cameraController?.dispose();

    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to switch camera: $e';
      });
    }
  }

  bool _canCapture() {
    return _isInitialized &&
        !_isCapturing &&
        _lastAnalysis != null &&
        _lastAnalysis!.isGoodQuality &&
        _lastAnalysis!.isFacingCamera;
  }
}

/// Custom painter for face detection overlay
class FaceDetectionPainter extends CustomPainter {
  final List<Face> faces;
  final FaceAnalysisResult? analysis;

  FaceDetectionPainter(this.faces, this.analysis);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final face in faces) {
      // Determine color based on analysis
      Color color = Colors.red;
      if (analysis != null) {
        if (analysis!.isGoodQuality && analysis!.isFacingCamera) {
          color = Colors.green;
        } else if (analysis!.isGoodQuality || analysis!.isFacingCamera) {
          color = Colors.orange;
        }
      }

      paint.color = color;

      // Draw bounding box
      canvas.drawRect(face.boundingBox, paint);

      // Draw landmarks
      for (final landmark in face.landmarks.values) {
        if (landmark != null) {
          canvas.drawCircle(
            Offset(
                landmark.position.x.toDouble(), landmark.position.y.toDouble()),
            3,
            Paint()..color = color,
          );
        }
      }

      // Draw confidence text
      if (analysis != null) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${(analysis!.confidence * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            face.boundingBox.left,
            face.boundingBox.top - 25,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
