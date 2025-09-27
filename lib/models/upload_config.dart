/// Configuration for upload operations
class UploadConfig {
  final bool usePresignedUrl;
  final String endpoint;
  final Map<String, String> headers;
  final int timeoutSeconds;
  final bool autoDeleteAfterUpload;
  final bool debugMode;

  const UploadConfig({
    required this.usePresignedUrl,
    required this.endpoint,
    this.headers = const {},
    this.timeoutSeconds = 30,
    this.autoDeleteAfterUpload = true,
    this.debugMode = false,
  });

  /// Create a copy with updated values
  UploadConfig copyWith({
    bool? usePresignedUrl,
    String? endpoint,
    Map<String, String>? headers,
    int? timeoutSeconds,
    bool? autoDeleteAfterUpload,
    bool? debugMode,
  }) {
    return UploadConfig(
      usePresignedUrl: usePresignedUrl ?? this.usePresignedUrl,
      endpoint: endpoint ?? this.endpoint,
      headers: headers ?? this.headers,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      autoDeleteAfterUpload:
          autoDeleteAfterUpload ?? this.autoDeleteAfterUpload,
      debugMode: debugMode ?? this.debugMode,
    );
  }

  /// Validate the configuration
  bool get isValid {
    return endpoint.isNotEmpty && endpoint.startsWith('http');
  }

  /// Get timeout duration
  Duration get timeoutDuration {
    return Duration(seconds: timeoutSeconds);
  }

  @override
  String toString() {
    return 'UploadConfig{usePresignedUrl: $usePresignedUrl, endpoint: $endpoint, timeout: ${timeoutSeconds}s}';
  }
}
