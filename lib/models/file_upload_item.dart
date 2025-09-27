import 'dart:io';
import 'package:intl/intl.dart';

/// Represents the status of a file upload
enum UploadStatus {
  queued, // File is waiting to be uploaded
  uploading, // File is currently being uploaded
  completed, // File uploaded successfully and deleted from device
  failed, // Upload failed
  paused, // Upload is paused
}

/// Represents a file that needs to be uploaded
class FileUploadItem {
  final String id;
  final File file;
  final String fileName;
  final String filePath;
  final int fileSize;
  final DateTime addedDate;

  UploadStatus status;
  double uploadProgress; // 0.0 to 1.0
  String? errorMessage;
  String? uploadUrl; // For presigned URL mode
  DateTime? completedDate;

  FileUploadItem({
    required this.id,
    required this.file,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.addedDate,
    this.status = UploadStatus.queued,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.uploadUrl,
    this.completedDate,
  });

  /// Create FileUploadItem from a File
  factory FileUploadItem.fromFile(File file) {
    final fileName = file.path.split('/').last;
    final fileSize = file.lengthSync();
    final now = DateTime.now();

    return FileUploadItem(
      id: '${now.millisecondsSinceEpoch}_${fileName.hashCode}',
      file: file,
      fileName: fileName,
      filePath: file.path,
      fileSize: fileSize,
      addedDate: now,
    );
  }

  /// Get formatted file size (e.g., "1.5 MB")
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get formatted added date
  String get formattedAddedDate {
    return DateFormat('MMM dd, yyyy HH:mm').format(addedDate);
  }

  /// Get formatted completed date
  String? get formattedCompletedDate {
    return completedDate != null
        ? DateFormat('MMM dd, yyyy HH:mm').format(completedDate!)
        : null;
  }

  /// Get file extension
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? '.${parts.last.toLowerCase()}' : '';
  }

  /// Check if file is an image
  bool get isImage {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return imageExtensions.contains(fileExtension);
  }

  /// Check if file is a document
  bool get isDocument {
    final docExtensions = ['.pdf', '.doc', '.docx', '.txt', '.rtf'];
    return docExtensions.contains(fileExtension);
  }

  /// Check if file is a video
  bool get isVideo {
    final videoExtensions = ['.mp4', '.avi', '.mov', '.mkv', '.wmv', '.flv'];
    return videoExtensions.contains(fileExtension);
  }

  /// Check if file still exists on device
  bool get fileExists {
    return file.existsSync();
  }

  /// Get upload progress as percentage (0-100)
  int get uploadProgressPercent {
    return (uploadProgress * 100).round();
  }

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case UploadStatus.queued:
        return 'Queued';
      case UploadStatus.uploading:
        return 'Uploading ${uploadProgressPercent}%';
      case UploadStatus.completed:
        return 'Completed';
      case UploadStatus.failed:
        return 'Failed';
      case UploadStatus.paused:
        return 'Paused';
    }
  }

  /// Update upload progress
  void updateProgress(double progress) {
    uploadProgress = progress.clamp(0.0, 1.0);
  }

  /// Mark upload as completed
  void markAsCompleted() {
    status = UploadStatus.completed;
    uploadProgress = 1.0;
    completedDate = DateTime.now();
    errorMessage = null;
  }

  /// Mark upload as failed
  void markAsFailed(String error) {
    status = UploadStatus.failed;
    errorMessage = error;
  }

  /// Mark upload as uploading
  void markAsUploading() {
    status = UploadStatus.uploading;
    errorMessage = null;
  }

  /// Reset upload status
  void reset() {
    status = UploadStatus.queued;
    uploadProgress = 0.0;
    errorMessage = null;
    uploadUrl = null;
    completedDate = null;
  }

  /// Convert to JSON for debugging
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'formattedFileSize': formattedFileSize,
      'addedDate': addedDate.toIso8601String(),
      'status': status.toString(),
      'uploadProgress': uploadProgress,
      'errorMessage': errorMessage,
      'uploadUrl': uploadUrl,
      'completedDate': completedDate?.toIso8601String(),
      'fileExtension': fileExtension,
      'isImage': isImage,
      'isDocument': isDocument,
      'isVideo': isVideo,
      'fileExists': fileExists,
    };
  }

  @override
  String toString() {
    return 'FileUploadItem{fileName: $fileName, status: $status, progress: ${uploadProgressPercent}%}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileUploadItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
