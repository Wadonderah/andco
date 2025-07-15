import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'firebase_service.dart';

/// Face detection service using Google ML Kit
class FaceDetectionService {
  static FaceDetectionService? _instance;
  static FaceDetectionService get instance =>
      _instance ??= FaceDetectionService._();

  FaceDetectionService._();

  late FaceDetector _faceDetector;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize face detection service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableLandmarks: true,
          enableClassification: true,
          enableTracking: true,
          minFaceSize: 0.1,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      _isInitialized = true;
      debugPrint('✅ Face detection service initialized successfully');

      await FirebaseService.instance.logEvent('face_detection_initialized', {});
    } catch (e) {
      debugPrint('❌ Failed to initialize face detection service: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Face detection service initialization failed');
      rethrow;
    }
  }

  /// Detect faces in camera image
  Future<List<Face>> detectFacesFromCamera(CameraImage cameraImage) async {
    if (!_isInitialized) {
      throw FaceDetectionException('Face detection service not initialized');
    }

    try {
      final inputImage = _convertCameraImage(cameraImage);
      final faces = await _faceDetector.processImage(inputImage);

      await FirebaseService.instance.logEvent('faces_detected_camera', {
        'face_count': faces.length,
      });

      return faces;
    } catch (e) {
      debugPrint('❌ Face detection from camera failed: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Face detection from camera failed');
      return [];
    }
  }

  /// Detect faces in image file
  Future<List<Face>> detectFacesFromFile(File imageFile) async {
    if (!_isInitialized) {
      throw FaceDetectionException('Face detection service not initialized');
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);

      await FirebaseService.instance.logEvent('faces_detected_file', {
        'face_count': faces.length,
        'file_path': imageFile.path,
      });

      return faces;
    } catch (e) {
      debugPrint('❌ Face detection from file failed: $e');
      await FirebaseService.instance.logError(e, StackTrace.current,
          reason: 'Face detection from file failed');
      return [];
    }
  }

  /// Detect faces from bytes
  Future<List<Face>> detectFacesFromBytes(
    Uint8List bytes,
    int width,
    int height,
    InputImageFormat format,
  ) async {
    if (!_isInitialized) {
      throw FaceDetectionException('Face detection service not initialized');
    }

    try {
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: format,
          bytesPerRow: width * 4, // Assuming RGBA format
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);

      await FirebaseService.instance.logEvent('faces_detected_bytes', {
        'face_count': faces.length,
      });

      return faces;
    } catch (e) {
      debugPrint('❌ Face detection from bytes failed: $e');
      return [];
    }
  }

  /// Analyze face for student verification
  Future<FaceAnalysisResult> analyzeFaceForVerification(Face face) async {
    try {
      final result = FaceAnalysisResult(
        confidence: _calculateConfidence(face),
        isSmiling:
            face.smilingProbability != null && face.smilingProbability! > 0.5,
        leftEyeOpen: face.leftEyeOpenProbability != null &&
            face.leftEyeOpenProbability! > 0.5,
        rightEyeOpen: face.rightEyeOpenProbability != null &&
            face.rightEyeOpenProbability! > 0.5,
        headEulerAngleY: face.headEulerAngleY ?? 0,
        headEulerAngleZ: face.headEulerAngleZ ?? 0,
        boundingBox: face.boundingBox,
        landmarks: _extractLandmarks(face),
        trackingId: face.trackingId,
      );

      await FirebaseService.instance.logEvent('face_analyzed', {
        'confidence': result.confidence,
        'is_smiling': result.isSmiling,
        'eyes_open': result.leftEyeOpen && result.rightEyeOpen,
      });

      return result;
    } catch (e) {
      debugPrint('❌ Face analysis failed: $e');
      throw FaceDetectionException('Face analysis failed: $e');
    }
  }

  /// Compare two faces for similarity
  Future<double> compareFaces(Face face1, Face face2) async {
    try {
      // This is a simplified comparison based on landmarks and contours
      // In a production app, you'd use a more sophisticated face recognition model

      final landmarks1 = _extractLandmarks(face1);
      final landmarks2 = _extractLandmarks(face2);

      if (landmarks1.isEmpty || landmarks2.isEmpty) {
        return 0.0;
      }

      double similarity = _calculateLandmarkSimilarity(landmarks1, landmarks2);

      // Factor in bounding box similarity
      final boxSimilarity = _calculateBoundingBoxSimilarity(
        face1.boundingBox,
        face2.boundingBox,
      );

      // Weighted average
      similarity = (similarity * 0.7) + (boxSimilarity * 0.3);

      await FirebaseService.instance.logEvent('faces_compared', {
        'similarity': similarity,
      });

      return similarity;
    } catch (e) {
      debugPrint('❌ Face comparison failed: $e');
      return 0.0;
    }
  }

  /// Convert camera image to InputImage
  InputImage _convertCameraImage(CameraImage cameraImage) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      cameraImage.width.toDouble(),
      cameraImage.height.toDouble(),
    );

    final InputImageRotation imageRotation = InputImageRotation.rotation0deg;

    final InputImageFormat inputImageFormat = InputImageFormat.nv21;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: cameraImage.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );
  }

  /// Calculate face confidence score
  double _calculateConfidence(Face face) {
    double confidence = 0.5; // Base confidence

    // Factor in bounding box size (larger faces are generally more reliable)
    final boxArea = face.boundingBox.width * face.boundingBox.height;
    if (boxArea > 10000) {
      confidence += 0.2;
    } else if (boxArea > 5000) {
      confidence += 0.1;
    }

    // Factor in landmark availability
    if (face.landmarks.isNotEmpty) confidence += 0.2;

    // Factor in contour availability
    if (face.contours.isNotEmpty) confidence += 0.1;

    return confidence.clamp(0.0, 1.0);
  }

  /// Extract landmarks from face
  Map<FaceLandmarkType, Point<int>> _extractLandmarks(Face face) {
    final landmarks = <FaceLandmarkType, Point<int>>{};

    for (final landmark in face.landmarks.values) {
      if (landmark != null) {
        landmarks[landmark.type] = landmark.position;
      }
    }

    return landmarks;
  }

  /// Calculate similarity between landmarks
  double _calculateLandmarkSimilarity(
    Map<FaceLandmarkType, Point<int>> landmarks1,
    Map<FaceLandmarkType, Point<int>> landmarks2,
  ) {
    if (landmarks1.isEmpty || landmarks2.isEmpty) return 0.0;

    double totalDistance = 0.0;
    int commonLandmarks = 0;

    for (final type in landmarks1.keys) {
      if (landmarks2.containsKey(type)) {
        final point1 = landmarks1[type]!;
        final point2 = landmarks2[type]!;

        final distance = _calculateDistance(point1, point2);
        totalDistance += distance;
        commonLandmarks++;
      }
    }

    if (commonLandmarks == 0) return 0.0;

    final averageDistance = totalDistance / commonLandmarks;

    // Convert distance to similarity (inverse relationship)
    // This is a simplified approach - in production, use proper face recognition models
    return (1.0 / (1.0 + averageDistance / 100)).clamp(0.0, 1.0);
  }

  /// Calculate bounding box similarity
  double _calculateBoundingBoxSimilarity(Rect box1, Rect box2) {
    final intersection = box1.intersect(box2);
    if (intersection.isEmpty) return 0.0;

    final union = box1.width * box1.height +
        box2.width * box2.height -
        intersection.width * intersection.height;

    return intersection.width * intersection.height / union;
  }

  /// Calculate distance between two points
  double _calculateDistance(Point<int> point1, Point<int> point2) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    return (dx * dx + dy * dy).toDouble();
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _faceDetector.close();
      _isInitialized = false;
      debugPrint('✅ Face detection service disposed');
    }
  }
}

/// Face analysis result model
class FaceAnalysisResult {
  final double confidence;
  final bool isSmiling;
  final bool leftEyeOpen;
  final bool rightEyeOpen;
  final double headEulerAngleY;
  final double headEulerAngleZ;
  final Rect boundingBox;
  final Map<FaceLandmarkType, Point<int>> landmarks;
  final int? trackingId;

  FaceAnalysisResult({
    required this.confidence,
    required this.isSmiling,
    required this.leftEyeOpen,
    required this.rightEyeOpen,
    required this.headEulerAngleY,
    required this.headEulerAngleZ,
    required this.boundingBox,
    required this.landmarks,
    this.trackingId,
  });

  bool get isGoodQuality => confidence > 0.7 && leftEyeOpen && rightEyeOpen;
  bool get isFacingCamera =>
      headEulerAngleY.abs() < 15 && headEulerAngleZ.abs() < 15;
}

/// Face detection exception
class FaceDetectionException implements Exception {
  final String message;
  FaceDetectionException(this.message);

  @override
  String toString() => 'FaceDetectionException: $message';
}
