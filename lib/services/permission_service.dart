import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../config.dart';

/// Service to handle permission requests for file access
class PermissionService {
  /// Request necessary permissions for file access
  static Future<bool> requestFilePermissions() async {
    try {
      if (Platform.isAndroid) {
        // For Android, we need different permissions based on Android version
        final androidInfo = await _getAndroidVersion();

        if (androidInfo >= 33) {
          // Android 13+ requires granular media permissions
          return await _requestAndroid13Permissions();
        } else if (androidInfo >= 30) {
          // Android 11-12 requires manage external storage for full access
          return await _requestAndroid11Permissions();
        } else {
          // Android 10 and below use legacy storage permissions
          return await _requestLegacyPermissions();
        }
      } else if (Platform.isIOS) {
        // iOS permissions are handled automatically by file_picker
        return true;
      }

      return false;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Error requesting permissions: $e');
      }
      return false;
    }
  }

  /// Check if file permissions are granted
  static Future<bool> checkFilePermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _getAndroidVersion();

        if (androidInfo >= 33) {
          return await _checkAndroid13Permissions();
        } else if (androidInfo >= 30) {
          return await _checkAndroid11Permissions();
        } else {
          return await _checkLegacyPermissions();
        }
      } else if (Platform.isIOS) {
        return true; // iOS handles this automatically
      }

      return false;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Error checking permissions: $e');
      }
      return false;
    }
  }

  /// Request permissions for Android 13+
  static Future<bool> _requestAndroid13Permissions() async {
    // Request granular media permissions
    final permissions = <Permission>[];

    // Add permissions based on file extensions we support
    if (_needsImagePermission()) {
      permissions.add(Permission.photos);
    }

    if (_needsVideoPermission()) {
      permissions.add(Permission.videos);
    }

    if (_needsAudioPermission()) {
      permissions.add(Permission.audio);
    }

    // For documents and other files, we don't need special permissions
    // File picker will handle access through SAF (Storage Access Framework)

    if (permissions.isEmpty) {
      return true; // No media permissions needed
    }

    final statuses = await permissions.request();

    // Check if at least one permission was granted
    bool hasPermission = false;
    for (final status in statuses.values) {
      if (status.isGranted) {
        hasPermission = true;
        break;
      }
    }

    if (!hasPermission) {
      // If denied, guide user to app settings
      await _showPermissionDialog();
    }

    return hasPermission;
  }

  /// Request permissions for Android 11-12
  static Future<bool> _requestAndroid11Permissions() async {
    // Try to get manage external storage permission for full access
    final status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      return true;
    }

    // If manage external storage is denied, try regular storage permission
    final storageStatus = await Permission.storage.request();

    if (!storageStatus.isGranted) {
      await _showPermissionDialog();
    }

    return storageStatus.isGranted;
  }

  /// Request legacy permissions for Android 10 and below
  static Future<bool> _requestLegacyPermissions() async {
    final status = await Permission.storage.request();

    if (!status.isGranted) {
      await _showPermissionDialog();
    }

    return status.isGranted;
  }

  /// Check permissions for Android 13+
  static Future<bool> _checkAndroid13Permissions() async {
    if (_needsImagePermission()) {
      final status = await Permission.photos.status;
      if (status.isGranted) return true;
    }

    if (_needsVideoPermission()) {
      final status = await Permission.videos.status;
      if (status.isGranted) return true;
    }

    if (_needsAudioPermission()) {
      final status = await Permission.audio.status;
      if (status.isGranted) return true;
    }

    // For documents, no permission needed (handled by SAF)
    return true;
  }

  /// Check permissions for Android 11-12
  static Future<bool> _checkAndroid11Permissions() async {
    final manageStatus = await Permission.manageExternalStorage.status;
    if (manageStatus.isGranted) {
      return true;
    }

    final storageStatus = await Permission.storage.status;
    return storageStatus.isGranted;
  }

  /// Check legacy permissions for Android 10 and below
  static Future<bool> _checkLegacyPermissions() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  /// Get Android version
  static Future<int> _getAndroidVersion() async {
    // This is a simplified version. In a real app, you might want to use
    // device_info_plus package for more accurate version detection
    return 33; // Assume Android 13+ for this example
  }

  /// Check if we need image permission based on supported extensions
  static bool _needsImagePermission() {
    final imageExts = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return AppConfig.allowedExtensions.isEmpty ||
        AppConfig.allowedExtensions
            .any((ext) => imageExts.contains(ext.toLowerCase()));
  }

  /// Check if we need video permission based on supported extensions
  static bool _needsVideoPermission() {
    final videoExts = ['.mp4', '.avi', '.mov', '.mkv', '.wmv', '.flv'];
    return AppConfig.allowedExtensions.isEmpty ||
        AppConfig.allowedExtensions
            .any((ext) => videoExts.contains(ext.toLowerCase()));
  }

  /// Check if we need audio permission based on supported extensions
  static bool _needsAudioPermission() {
    final audioExts = ['.mp3', '.wav', '.aac', '.flac', '.ogg'];
    return AppConfig.allowedExtensions.isEmpty ||
        AppConfig.allowedExtensions
            .any((ext) => audioExts.contains(ext.toLowerCase()));
  }

  /// Show permission explanation dialog (to be implemented in UI)
  static Future<void> _showPermissionDialog() async {
    // This would show a dialog explaining why permissions are needed
    // and optionally open app settings
    if (AppConfig.debugMode) {
      print(
          'Permission denied. User should grant permissions in app settings.');
    }
  }

  /// Open app settings for manual permission granting
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Get permission status summary
  static Future<String> getPermissionStatusSummary() async {
    final buffer = StringBuffer('Permission Status:\n');

    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();
      buffer.writeln('Android Version: $androidVersion');

      if (androidVersion >= 33) {
        final photos = await Permission.photos.status;
        final videos = await Permission.videos.status;
        final audio = await Permission.audio.status;

        buffer.writeln('Photos: ${photos.name}');
        buffer.writeln('Videos: ${videos.name}');
        buffer.writeln('Audio: ${audio.name}');
      } else {
        final storage = await Permission.storage.status;
        final manageStorage = await Permission.manageExternalStorage.status;

        buffer.writeln('Storage: ${storage.name}');
        buffer.writeln('Manage External Storage: ${manageStorage.name}');
      }
    } else {
      buffer.writeln('iOS: Permissions handled by system');
    }

    return buffer.toString();
  }
}
