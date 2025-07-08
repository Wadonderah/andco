import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Provider for storage service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

/// Upload state for tracking upload progress
class UploadState {
  final bool isUploading;
  final double progress;
  final String? downloadUrl;
  final String? error;

  const UploadState({
    this.isUploading = false,
    this.progress = 0.0,
    this.downloadUrl,
    this.error,
  });

  UploadState copyWith({
    bool? isUploading,
    double? progress,
    String? downloadUrl,
    String? error,
  }) {
    return UploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      error: error ?? this.error,
    );
  }
}

/// Upload controller for managing file uploads
class UploadController extends StateNotifier<UploadState> {
  UploadController() : super(const UploadState());

  final StorageService _storageService = StorageService.instance;

  /// Upload profile picture
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    state = const UploadState(isUploading: true);
    
    try {
      final downloadUrl = await _storageService.uploadProfilePicture(
        userId: userId,
        imageFile: imageFile,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );
      
      if (downloadUrl != null) {
        state = UploadState(downloadUrl: downloadUrl);
        return downloadUrl;
      } else {
        state = const UploadState(error: 'Failed to upload profile picture');
        return null;
      }
    } catch (e) {
      state = UploadState(error: e.toString());
      return null;
    }
  }

  /// Upload child photo
  Future<String?> uploadChildPhoto(String childId, File imageFile) async {
    state = const UploadState(isUploading: true);
    
    try {
      final downloadUrl = await _storageService.uploadChildPhoto(
        childId: childId,
        imageFile: imageFile,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );
      
      if (downloadUrl != null) {
        state = UploadState(downloadUrl: downloadUrl);
        return downloadUrl;
      } else {
        state = const UploadState(error: 'Failed to upload child photo');
        return null;
      }
    } catch (e) {
      state = UploadState(error: e.toString());
      return null;
    }
  }

  /// Upload document
  Future<String?> uploadDocument(String userId, File documentFile, String documentType) async {
    state = const UploadState(isUploading: true);
    
    try {
      final downloadUrl = await _storageService.uploadDocument(
        userId: userId,
        documentFile: documentFile,
        documentType: documentType,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );
      
      if (downloadUrl != null) {
        state = UploadState(downloadUrl: downloadUrl);
        return downloadUrl;
      } else {
        state = const UploadState(error: 'Failed to upload document');
        return null;
      }
    } catch (e) {
      state = UploadState(error: e.toString());
      return null;
    }
  }

  /// Upload bus image
  Future<String?> uploadBusImage(String busId, File imageFile) async {
    state = const UploadState(isUploading: true);
    
    try {
      final downloadUrl = await _storageService.uploadBusImage(
        busId: busId,
        imageFile: imageFile,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );
      
      if (downloadUrl != null) {
        state = UploadState(downloadUrl: downloadUrl);
        return downloadUrl;
      } else {
        state = const UploadState(error: 'Failed to upload bus image');
        return null;
      }
    } catch (e) {
      state = UploadState(error: e.toString());
      return null;
    }
  }

  /// Upload incident media
  Future<String?> uploadIncidentMedia(String incidentId, File mediaFile, String mediaType) async {
    state = const UploadState(isUploading: true);
    
    try {
      final downloadUrl = await _storageService.uploadIncidentMedia(
        incidentId: incidentId,
        mediaFile: mediaFile,
        mediaType: mediaType,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );
      
      if (downloadUrl != null) {
        state = UploadState(downloadUrl: downloadUrl);
        return downloadUrl;
      } else {
        state = const UploadState(error: 'Failed to upload incident media');
        return null;
      }
    } catch (e) {
      state = UploadState(error: e.toString());
      return null;
    }
  }

  /// Upload bytes (for web compatibility)
  Future<String?> uploadBytes({
    required String filePath,
    required Uint8List bytes,
    required String fileName,
    Map<String, String>? metadata,
  }) async {
    state = const UploadState(isUploading: true);
    
    try {
      final downloadUrl = await _storageService.uploadBytes(
        filePath: filePath,
        bytes: bytes,
        fileName: fileName,
        metadata: metadata,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );
      
      if (downloadUrl != null) {
        state = UploadState(downloadUrl: downloadUrl);
        return downloadUrl;
      } else {
        state = const UploadState(error: 'Failed to upload bytes');
        return null;
      }
    } catch (e) {
      state = UploadState(error: e.toString());
      return null;
    }
  }

  /// Reset upload state
  void reset() {
    state = const UploadState();
  }
}

/// Provider for upload controller
final uploadControllerProvider = StateNotifierProvider<UploadController, UploadState>((ref) {
  return UploadController();
});

/// Provider for downloading files
final downloadProvider = FutureProvider.family<Uint8List?, String>((ref, downloadUrl) async {
  final storageService = ref.read(storageServiceProvider);
  return await storageService.downloadFile(downloadUrl);
});

/// Provider for checking if file exists
final fileExistsProvider = FutureProvider.family<bool, String>((ref, downloadUrl) async {
  final storageService = ref.read(storageServiceProvider);
  return await storageService.fileExists(downloadUrl);
});

/// Provider for getting file size
final fileSizeProvider = FutureProvider.family<int?, String>((ref, downloadUrl) async {
  final storageService = ref.read(storageServiceProvider);
  return await storageService.getFileSize(downloadUrl);
});

/// Provider for deleting files
final deleteFileProvider = FutureProvider.family<bool, String>((ref, downloadUrl) async {
  final storageService = ref.read(storageServiceProvider);
  return await storageService.deleteFile(downloadUrl);
});

/// Provider for listing files in a directory
final listFilesProvider = FutureProvider.family<List<String>, String>((ref, directoryPath) async {
  final storageService = ref.read(storageServiceProvider);
  final references = await storageService.listFiles(directoryPath);
  
  // Get download URLs for all files
  final downloadUrls = <String>[];
  for (final ref in references) {
    try {
      final url = await ref.getDownloadURL();
      downloadUrls.add(url);
    } catch (e) {
      // Skip files that can't be accessed
      continue;
    }
  }
  
  return downloadUrls;
});

/// Multiple upload controller for handling multiple file uploads
class MultipleUploadController extends StateNotifier<Map<String, UploadState>> {
  MultipleUploadController() : super({});

  final StorageService _storageService = StorageService.instance;

  /// Upload multiple files
  Future<Map<String, String?>> uploadMultipleFiles(Map<String, File> files, String basePath) async {
    final results = <String, String?>{};
    
    for (final entry in files.entries) {
      final key = entry.key;
      final file = entry.value;
      
      // Initialize upload state for this file
      state = {
        ...state,
        key: const UploadState(isUploading: true),
      };
      
      try {
        final downloadUrl = await _storageService.uploadFile(
          filePath: basePath,
          file: file,
          onProgress: (progress) {
            state = {
              ...state,
              key: state[key]!.copyWith(progress: progress),
            };
          },
        );
        
        if (downloadUrl != null) {
          state = {
            ...state,
            key: UploadState(downloadUrl: downloadUrl),
          };
          results[key] = downloadUrl;
        } else {
          state = {
            ...state,
            key: const UploadState(error: 'Upload failed'),
          };
          results[key] = null;
        }
      } catch (e) {
        state = {
          ...state,
          key: UploadState(error: e.toString()),
        };
        results[key] = null;
      }
    }
    
    return results;
  }

  /// Reset all upload states
  void reset() {
    state = {};
  }

  /// Reset specific upload state
  void resetFile(String key) {
    final newState = Map<String, UploadState>.from(state);
    newState.remove(key);
    state = newState;
  }
}

/// Provider for multiple upload controller
final multipleUploadControllerProvider = StateNotifierProvider<MultipleUploadController, Map<String, UploadState>>((ref) {
  return MultipleUploadController();
});
