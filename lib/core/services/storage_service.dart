import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'firebase_service.dart';

/// Service for managing Firebase Cloud Storage operations
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  
  StorageService._();

  final FirebaseStorage _storage = FirebaseService.instance.storage;

  /// Upload file to Firebase Storage
  Future<String?> uploadFile({
    required String filePath,
    required File file,
    String? customFileName,
    Map<String, String>? metadata,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = customFileName ?? path.basename(file.path);
      final ref = _storage.ref().child(filePath).child(fileName);
      
      // Set metadata if provided
      SettableMetadata? settableMetadata;
      if (metadata != null) {
        settableMetadata = SettableMetadata(
          customMetadata: metadata,
          contentType: _getContentType(fileName),
        );
      }
      
      final uploadTask = settableMetadata != null 
          ? ref.putFile(file, settableMetadata)
          : ref.putFile(file);
      
      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      await FirebaseService.instance.logEvent('file_uploaded', {
        'file_path': filePath,
        'file_name': fileName,
        'file_size': file.lengthSync(),
      });
      
      return downloadUrl;
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'File upload failed');
      debugPrint('File upload failed: $e');
      return null;
    }
  }

  /// Upload bytes to Firebase Storage (for web compatibility)
  Future<String?> uploadBytes({
    required String filePath,
    required Uint8List bytes,
    required String fileName,
    Map<String, String>? metadata,
    Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(filePath).child(fileName);
      
      // Set metadata if provided
      SettableMetadata? settableMetadata;
      if (metadata != null) {
        settableMetadata = SettableMetadata(
          customMetadata: metadata,
          contentType: _getContentType(fileName),
        );
      }
      
      final uploadTask = settableMetadata != null 
          ? ref.putData(bytes, settableMetadata)
          : ref.putData(bytes);
      
      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      await FirebaseService.instance.logEvent('bytes_uploaded', {
        'file_path': filePath,
        'file_name': fileName,
        'file_size': bytes.length,
      });
      
      return downloadUrl;
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'Bytes upload failed');
      debugPrint('Bytes upload failed: $e');
      return null;
    }
  }

  /// Upload profile picture
  Future<String?> uploadProfilePicture({
    required String userId,
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadFile(
      filePath: 'profile_pictures',
      file: imageFile,
      customFileName: fileName,
      metadata: {
        'userId': userId,
        'type': 'profile_picture',
        'uploadedAt': DateTime.now().toIso8601String(),
      },
      onProgress: onProgress,
    );
  }

  /// Upload child photo
  Future<String?> uploadChildPhoto({
    required String childId,
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    final fileName = 'child_${childId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadFile(
      filePath: 'child_photos',
      file: imageFile,
      customFileName: fileName,
      metadata: {
        'childId': childId,
        'type': 'child_photo',
        'uploadedAt': DateTime.now().toIso8601String(),
      },
      onProgress: onProgress,
    );
  }

  /// Upload document
  Future<String?> uploadDocument({
    required String userId,
    required File documentFile,
    required String documentType,
    Function(double)? onProgress,
  }) async {
    final extension = path.extension(documentFile.path);
    final fileName = '${documentType}_${userId}_${DateTime.now().millisecondsSinceEpoch}$extension';
    return uploadFile(
      filePath: 'documents',
      file: documentFile,
      customFileName: fileName,
      metadata: {
        'userId': userId,
        'type': documentType,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
      onProgress: onProgress,
    );
  }

  /// Upload bus image
  Future<String?> uploadBusImage({
    required String busId,
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    final fileName = 'bus_${busId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadFile(
      filePath: 'bus_images',
      file: imageFile,
      customFileName: fileName,
      metadata: {
        'busId': busId,
        'type': 'bus_image',
        'uploadedAt': DateTime.now().toIso8601String(),
      },
      onProgress: onProgress,
    );
  }

  /// Upload incident report media
  Future<String?> uploadIncidentMedia({
    required String incidentId,
    required File mediaFile,
    required String mediaType, // 'image' or 'video'
    Function(double)? onProgress,
  }) async {
    final extension = path.extension(mediaFile.path);
    final fileName = 'incident_${incidentId}_${DateTime.now().millisecondsSinceEpoch}$extension';
    return uploadFile(
      filePath: 'incident_media',
      file: mediaFile,
      customFileName: fileName,
      metadata: {
        'incidentId': incidentId,
        'type': mediaType,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
      onProgress: onProgress,
    );
  }

  /// Download file
  Future<Uint8List?> downloadFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      final bytes = await ref.getData();
      
      await FirebaseService.instance.logEvent('file_downloaded', {
        'download_url': downloadUrl,
      });
      
      return bytes;
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'File download failed');
      debugPrint('File download failed: $e');
      return null;
    }
  }

  /// Delete file
  Future<bool> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      
      await FirebaseService.instance.logEvent('file_deleted', {
        'download_url': downloadUrl,
      });
      
      return true;
    } catch (e) {
      await FirebaseService.instance.logError(e, StackTrace.current, 
          reason: 'File deletion failed');
      debugPrint('File deletion failed: $e');
      return false;
    }
  }

  /// Delete multiple files
  Future<List<bool>> deleteFiles(List<String> downloadUrls) async {
    final results = <bool>[];
    
    for (final url in downloadUrls) {
      final result = await deleteFile(url);
      results.add(result);
    }
    
    return results;
  }

  /// Get file metadata
  Future<FullMetadata?> getFileMetadata(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      debugPrint('Failed to get file metadata: $e');
      return null;
    }
  }

  /// List files in a directory
  Future<List<Reference>> listFiles(String directoryPath) async {
    try {
      final ref = _storage.ref().child(directoryPath);
      final result = await ref.listAll();
      return result.items;
    } catch (e) {
      debugPrint('Failed to list files: $e');
      return [];
    }
  }

  /// Get file size
  Future<int?> getFileSize(String downloadUrl) async {
    try {
      final metadata = await getFileMetadata(downloadUrl);
      return metadata?.size;
    } catch (e) {
      debugPrint('Failed to get file size: $e');
      return null;
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get content type based on file extension
  String _getContentType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.txt':
        return 'text/plain';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }

  /// Compress and upload image
  Future<String?> compressAndUploadImage({
    required String filePath,
    required File imageFile,
    String? customFileName,
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    Function(double)? onProgress,
  }) async {
    try {
      // Note: For actual image compression, you would use a package like image_picker or flutter_image_compress
      // This is a placeholder implementation
      
      return await uploadFile(
        filePath: filePath,
        file: imageFile,
        customFileName: customFileName,
        metadata: {
          'compressed': 'true',
          'quality': quality.toString(),
          'maxWidth': maxWidth?.toString() ?? 'null',
          'maxHeight': maxHeight?.toString() ?? 'null',
        },
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('Image compression and upload failed: $e');
      return null;
    }
  }
}
