// Configuration file for the S3 upload app
// IMPORTANT: Configure these settings before running the app

class AppConfig {
  // ============================================================================
  // MAIN CONFIGURATION - CHOOSE YOUR UPLOAD MODE
  // ============================================================================

  /// Set to true for presigned URL mode (recommended and secure)
  /// Set to false for direct bucket upload mode (requires bucket to be public)
  static const bool usePresignedUrl = true;

  // ============================================================================
  // PRESIGNED URL MODE CONFIGURATION
  // ============================================================================

  /// Your backend endpoint that generates presigned URLs
  /// Example: "https://your-api.com/generate-presigned-url"
  /// This endpoint should return a JSON with: {"uploadUrl": "presigned_url_here"}
  static const String presignedUrlEndpoint =
      "https://your-backend.com/api/generate-presigned-url";

  /// Headers to send with presigned URL request (e.g., authentication)
  static const Map<String, String> presignedUrlHeaders = {
    'Content-Type': 'application/json',
    // 'Authorization': 'Bearer your-token-here',
    // Add any other headers your backend requires
  };

  // ============================================================================
  // DIRECT BUCKET MODE CONFIGURATION (NOT RECOMMENDED FOR PRODUCTION)
  // ============================================================================

  /// Direct S3 bucket URL for uploads
  /// Example: "https://your-bucket.s3.region.amazonaws.com/"
  /// WARNING: This requires your bucket to be publicly writable (security risk)
  static const String directBucketUrl = "https://your-bucket.e2enetworks.net/";

  // ============================================================================
  // APP SETTINGS
  // ============================================================================

  /// App name displayed in the UI
  static const String appName = "S3 File Uploader";

  /// Maximum number of files that can be queued at once
  static const int maxQueuedFiles = 50;

  /// Directories to scan automatically (Android)
  static const List<String> autoScanDirectories = [
    'Download', // Downloads folder
    'DCIM', // Camera photos
    'Pictures', // Pictures folder
    'Documents', // Documents folder (optional)
  ];

  /// File extensions to include in auto-scan
  /// Leave empty to include all files
  static const List<String> allowedExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', // Images
    '.pdf', '.doc', '.docx', '.txt', // Documents
    '.mp4', '.avi', '.mov', '.mkv', // Videos
    '.mp3', '.wav', '.aac', '.flac', // Audio
    '.zip', '.rar', '.7z', // Archives
  ];

  /// Enable automatic deletion after successful upload
  static const bool autoDeleteAfterUpload = true;

  /// Timeout for upload requests (in seconds)
  static const int uploadTimeoutSeconds = 30;

  /// Show debug information in console
  static const bool debugMode = true;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get the upload endpoint based on current configuration
  static String get uploadEndpoint {
    return usePresignedUrl ? presignedUrlEndpoint : directBucketUrl;
  }

  /// Check if the configuration is valid
  static bool get isConfigurationValid {
    if (usePresignedUrl) {
      return presignedUrlEndpoint.isNotEmpty &&
          presignedUrlEndpoint.startsWith('http');
    } else {
      return directBucketUrl.isNotEmpty && directBucketUrl.startsWith('http');
    }
  }

  /// Get configuration summary for debugging
  static String get configSummary {
    return '''
Configuration Summary:
- Mode: ${usePresignedUrl ? 'Presigned URL' : 'Direct Bucket'}
- Endpoint: ${uploadEndpoint}
- Auto Delete: $autoDeleteAfterUpload
- Max Queue: $maxQueuedFiles files
- Scan Directories: ${autoScanDirectories.join(', ')}
- Allowed Extensions: ${allowedExtensions.isEmpty ? 'All' : allowedExtensions.join(', ')}
''';
  }
}

// ============================================================================
// SETUP INSTRUCTIONS
// ============================================================================

/// STEP 1: Choose your upload mode
/// - For production apps, use presigned URL mode (usePresignedUrl = true)
/// - Set up a backend service that generates presigned URLs
/// - Update presignedUrlEndpoint with your backend URL
/// 
/// STEP 2: If using direct bucket mode (NOT recommended for production)
/// - Set usePresignedUrl = false
/// - Update directBucketUrl with your bucket URL
/// - Make sure your bucket allows public write access
/// 
/// STEP 3: Customize app settings
/// - Update appName, autoScanDirectories, allowedExtensions as needed
/// - Set autoDeleteAfterUpload based on your requirements
/// 
/// STEP 4: Test configuration
/// - Use AppConfig.isConfigurationValid to verify setup
/// - Check AppConfig.configSummary for current settings