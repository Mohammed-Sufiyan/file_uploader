import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/file_upload_item.dart';
import '../models/upload_config.dart';

/// Service to handle file uploads to S3
class UploadService {
  static final http.Client _client = http.Client();

  /// Upload a single file
  static Future<bool> uploadFile(
    FileUploadItem fileItem,
    Function(double)? onProgress,
  ) async {
    try {
      if (AppConfig.debugMode) {
        print('Starting upload for: ${fileItem.fileName}');
      }

      // Mark as uploading
      fileItem.markAsUploading();
      onProgress?.call(0.0);

      bool success = false;

      if (AppConfig.usePresignedUrl) {
        success = await _uploadWithPresignedUrl(fileItem, onProgress);
      } else {
        success = await _uploadDirectToBucket(fileItem, onProgress);
      }

      if (success) {
        fileItem.markAsCompleted();
        onProgress?.call(1.0);

        // Auto-delete file if configured
        if (AppConfig.autoDeleteAfterUpload) {
          await _deleteFileFromDevice(fileItem);
        }

        if (AppConfig.debugMode) {
          print('Upload completed for: ${fileItem.fileName}');
        }
      } else {
        fileItem.markAsFailed('Upload failed');
        if (AppConfig.debugMode) {
          print('Upload failed for: ${fileItem.fileName}');
        }
      }

      return success;
    } catch (e) {
      fileItem.markAsFailed(e.toString());
      if (AppConfig.debugMode) {
        print('Upload error for ${fileItem.fileName}: $e');
      }
      return false;
    }
  }

  /// Upload file using presigned URL
  static Future<bool> _uploadWithPresignedUrl(
    FileUploadItem fileItem,
    Function(double)? onProgress,
  ) async {
    try {
      // Step 1: Get presigned URL from backend
      final presignedUrl = await _getPresignedUrl(fileItem);
      if (presignedUrl == null) {
        return false;
      }

      fileItem.uploadUrl = presignedUrl;
      onProgress?.call(0.1); // 10% progress for getting URL

      // Step 2: Upload file to presigned URL
      return await _uploadToUrl(presignedUrl, fileItem, onProgress, 0.1);
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Presigned URL upload error: $e');
      }
      return false;
    }
  }

  /// Upload file directly to bucket
  static Future<bool> _uploadDirectToBucket(
    FileUploadItem fileItem,
    Function(double)? onProgress,
  ) async {
    try {
      final uploadUrl = AppConfig.directBucketUrl + fileItem.fileName;
      return await _uploadToUrl(uploadUrl, fileItem, onProgress, 0.0);
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Direct bucket upload error: $e');
      }
      return false;
    }
  }

  /// Get presigned URL from backend
  static Future<String?> _getPresignedUrl(FileUploadItem fileItem) async {
    try {
      final request = {
        'fileName': fileItem.fileName,
        'fileSize': fileItem.fileSize,
        'contentType': _getContentType(fileItem.fileName),
      };

      final response = await _client
          .post(
            Uri.parse(AppConfig.presignedUrlEndpoint),
            headers: {
              'Content-Type': 'application/json',
              ...AppConfig.presignedUrlHeaders,
            },
            body: jsonEncode(request),
          )
          .timeout(Duration(seconds: AppConfig.uploadTimeoutSeconds));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['uploadUrl'] ?? responseData['url'];
      } else {
        if (AppConfig.debugMode) {
          print(
              'Failed to get presigned URL: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Error getting presigned URL: $e');
      }
      return null;
    }
  }

  /// Upload file to a specific URL
  static Future<bool> _uploadToUrl(
    String uploadUrl,
    FileUploadItem fileItem,
    Function(double)? onProgress,
    double startProgress,
  ) async {
    try {
      final file = fileItem.file;

      // Create multipart request
      final request = http.MultipartRequest('PUT', Uri.parse(uploadUrl));

      // Add file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileItem.fileName,
      );

      request.files.add(multipartFile);

      // Set content type
      request.headers['Content-Type'] = _getContentType(fileItem.fileName);

      // Send request with progress tracking
      final streamedResponse = await _client.send(request);

      // Track progress (simplified - in real implementation you'd track bytes)
      // Since we can't easily track upload progress with http.MultipartRequest,
      // we simulate progress updates
      _simulateProgress(onProgress, startProgress);

      // Check response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        if (AppConfig.debugMode) {
          print('Upload failed with status: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Error uploading to URL: $e');
      }
      return false;
    }
  }

  /// Simulate upload progress (since http package doesn't provide real progress)
  static void _simulateProgress(
      Function(double)? onProgress, double startProgress) {
    if (onProgress == null) return;

    // Simulate progress updates
    final steps = 9;
    final progressStep = (1.0 - startProgress) / steps;

    for (int i = 1; i <= steps; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
        onProgress(startProgress + (progressStep * i));
      });
    }
  }

  /// Get content type based on file extension
  static String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';

      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';

      // Videos
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'mkv':
        return 'video/x-matroska';

      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';

      // Archives
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';

      default:
        return 'application/octet-stream';
    }
  }

  /// Delete file from device after successful upload
  static Future<bool> _deleteFileFromDevice(FileUploadItem fileItem) async {
    try {
      if (await fileItem.file.exists()) {
        await fileItem.file.delete();

        if (AppConfig.debugMode) {
          print('Deleted file from device: ${fileItem.fileName}');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Error deleting file ${fileItem.fileName}: $e');
      }
      return false;
    }
  }

  /// Upload multiple files with batch processing
  static Future<List<FileUploadItem>> uploadFiles(
    List<FileUploadItem> files,
    Function(FileUploadItem, double)? onFileProgress,
    Function(int, int)? onBatchProgress,
  ) async {
    final completedFiles = <FileUploadItem>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];

      final success = await uploadFile(file, (progress) {
        onFileProgress?.call(file, progress);
      });

      if (success) {
        completedFiles.add(file);
      }

      onBatchProgress?.call(i + 1, files.length);

      // Small delay between uploads to prevent overwhelming the server
      await Future.delayed(Duration(milliseconds: 100));
    }

    if (AppConfig.debugMode) {
      print(
          'Batch upload completed: ${completedFiles.length}/${files.length} files uploaded');
    }

    return completedFiles;
  }

  /// Check if upload service is properly configured
  static bool get isConfigured {
    return AppConfig.isConfigurationValid;
  }

  /// Test upload configuration
  static Future<bool> testConfiguration() async {
    try {
      if (AppConfig.usePresignedUrl) {
        // Test presigned URL endpoint
        final response = await _client
            .get(
              Uri.parse(AppConfig.presignedUrlEndpoint),
              headers: AppConfig.presignedUrlHeaders,
            )
            .timeout(Duration(seconds: 10));

        // Any response (even error) indicates the endpoint is reachable
        return response.statusCode < 500;
      } else {
        // Test direct bucket URL
        final response = await _client
            .head(
              Uri.parse(AppConfig.directBucketUrl),
            )
            .timeout(Duration(seconds: 10));

        return response.statusCode < 500;
      }
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Configuration test failed: $e');
      }
      return false;
    }
  }

  /// Get upload statistics
  static Map<String, dynamic> getUploadStats(List<FileUploadItem> files) {
    final completed =
        files.where((f) => f.status == UploadStatus.completed).length;
    final failed = files.where((f) => f.status == UploadStatus.failed).length;
    final uploading =
        files.where((f) => f.status == UploadStatus.uploading).length;
    final queued = files.where((f) => f.status == UploadStatus.queued).length;

    final totalSize = files.fold<int>(0, (sum, f) => sum + f.fileSize);
    final completedSize = files
        .where((f) => f.status == UploadStatus.completed)
        .fold<int>(0, (sum, f) => sum + f.fileSize);

    return {
      'totalFiles': files.length,
      'completed': completed,
      'failed': failed,
      'uploading': uploading,
      'queued': queued,
      'totalSize': totalSize,
      'completedSize': completedSize,
      'successRate':
          files.isNotEmpty ? (completed / files.length * 100).round() : 0,
    };
  }

  /// Clean up resources
  static void dispose() {
    _client.close();
  }
}
