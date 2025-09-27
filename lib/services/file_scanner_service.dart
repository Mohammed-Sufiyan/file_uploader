import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../config.dart';
import '../models/file_upload_item.dart';

/// Service to automatically scan directories for files to upload
class FileScannerService {
  static const List<String> _commonDirectoryNames = [
    'Download',
    'Downloads',
    'DCIM',
    'Camera',
    'Pictures',
    'Images',
    'Documents',
    'Files',
    'Movies',
    'Videos',
    'Music',
    'Audio',
  ];

  /// Scan all configured directories for files
  static Future<List<FileUploadItem>> scanForFiles() async {
    final List<FileUploadItem> foundFiles = [];

    try {
      if (Platform.isAndroid) {
        foundFiles.addAll(await _scanAndroidDirectories());
      } else if (Platform.isIOS) {
        foundFiles.addAll(await _scanIOSDirectories());
      }

      // Remove duplicates and sort by date
      final uniqueFiles = _removeDuplicates(foundFiles);
      uniqueFiles.sort((a, b) => b.addedDate.compareTo(a.addedDate));

      if (AppConfig.debugMode) {
        print('FileScannerService: Found ${uniqueFiles.length} files');
      }

      return uniqueFiles;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Error scanning files: $e');
      }
      return [];
    }
  }

  /// Scan specific directory for files
  static Future<List<FileUploadItem>> scanDirectory(
      String directoryPath) async {
    final List<FileUploadItem> files = [];

    try {
      final directory = Directory(directoryPath);

      if (!await directory.exists()) {
        if (AppConfig.debugMode) {
          print('Directory does not exist: $directoryPath');
        }
        return files;
      }

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && await _shouldIncludeFile(entity)) {
          try {
            final fileItem = FileUploadItem.fromFile(entity);
            files.add(fileItem);
          } catch (e) {
            if (AppConfig.debugMode) {
              print('Error processing file ${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Error scanning directory $directoryPath: $e');
      }
    }

    return files;
  }

  /// Scan Android external storage directories
  static Future<List<FileUploadItem>> _scanAndroidDirectories() async {
    final List<FileUploadItem> files = [];

    try {
      // Get external storage directory
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        if (AppConfig.debugMode) {
          print('External storage directory not available');
        }
        return files;
      }

      // Get the root of external storage (usually /storage/emulated/0/)
      final String externalPath = externalDir.path.split('/Android').first;

      // Scan configured directories
      for (final dirName in AppConfig.autoScanDirectories) {
        final scanPaths = _getAndroidDirectoryPaths(externalPath, dirName);

        for (final scanPath in scanPaths) {
          final dirFiles = await scanDirectory(scanPath);
          files.addAll(dirFiles);
        }
      }

      // Also scan app's document directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final appFiles = await scanDirectory(appDocDir.path);
      files.addAll(appFiles);
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Error scanning Android directories: $e');
      }
    }

    return files;
  }

  /// Scan iOS directories
  static Future<List<FileUploadItem>> _scanIOSDirectories() async {
    final List<FileUploadItem> files = [];

    try {
      // iOS apps can only access their own sandbox
      // Scan document directory
      final docDir = await getApplicationDocumentsDirectory();
      files.addAll(await scanDirectory(docDir.path));

      // Scan temporary directory
      final tempDir = await getTemporaryDirectory();
      files.addAll(await scanDirectory(tempDir.path));

      // Note: iOS apps cannot access system directories like Photos
      // without using specific APIs like PHPhotoLibrary
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Error scanning iOS directories: $e');
      }
    }

    return files;
  }

  /// Get possible Android directory paths for a given directory name
  static List<String> _getAndroidDirectoryPaths(
      String externalPath, String dirName) {
    final paths = <String>[];

    // Common Android directory structures
    paths.add(path.join(externalPath, dirName));
    paths.add(path.join(externalPath, dirName.toLowerCase()));
    paths.add(path.join(externalPath, dirName.toUpperCase()));

    // Handle special cases
    switch (dirName.toLowerCase()) {
      case 'download':
        paths.add(path.join(externalPath, 'Download'));
        paths.add(path.join(externalPath, 'Downloads'));
        break;
      case 'dcim':
        paths.add(path.join(externalPath, 'DCIM', 'Camera'));
        paths.add(path.join(externalPath, 'DCIM', '100MEDIA'));
        break;
      case 'pictures':
        paths.add(path.join(externalPath, 'Pictures'));
        paths.add(path.join(externalPath, 'Images'));
        paths.add(path.join(externalPath, 'Photos'));
        break;
    }

    return paths;
  }

  /// Check if a file should be included in the scan
  static Future<bool> _shouldIncludeFile(File file) async {
    try {
      // Check if file exists and is readable
      if (!await file.exists()) {
        return false;
      }

      final stat = await file.stat();

      // Skip directories
      if (stat.type == FileSystemEntityType.directory) {
        return false;
      }

      // Skip very large files (over 1GB) to prevent memory issues
      if (stat.size > 1024 * 1024 * 1024) {
        return false;
      }

      // Skip very small files (under 1 byte)
      if (stat.size < 1) {
        return false;
      }

      // Check file extension if filter is specified
      if (AppConfig.allowedExtensions.isNotEmpty) {
        final fileName = path.basename(file.path);
        final fileExt = path.extension(fileName).toLowerCase();

        if (!AppConfig.allowedExtensions.contains(fileExt)) {
          return false;
        }
      }

      // Skip hidden files and system files
      final fileName = path.basename(file.path);
      if (fileName.startsWith('.') || fileName.startsWith('~')) {
        return false;
      }

      // Skip files in system directories
      final filePath = file.path.toLowerCase();
      final systemDirs = [
        'android_secure',
        'android/data',
        'android/obb',
        '.trash'
      ];
      if (systemDirs.any((dir) => filePath.contains(dir))) {
        return false;
      }

      return true;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Error checking file ${file.path}: $e');
      }
      return false;
    }
  }

  /// Remove duplicate files based on path and size
  static List<FileUploadItem> _removeDuplicates(List<FileUploadItem> files) {
    final seen = <String>{};
    final uniqueFiles = <FileUploadItem>[];

    for (final file in files) {
      final key = '${file.filePath}_${file.fileSize}';
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueFiles.add(file);
      }
    }

    return uniqueFiles;
  }

  /// Get storage usage information
  static Future<Map<String, dynamic>> getStorageInfo() async {
    final info = <String, dynamic>{};

    try {
      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final stat = await externalDir.stat();
          info['externalStoragePath'] = externalDir.path;
          info['lastModified'] = stat.modified;
        }
      }

      final tempDir = await getTemporaryDirectory();
      final docDir = await getApplicationDocumentsDirectory();

      info['temporaryDirectory'] = tempDir.path;
      info['documentsDirectory'] = docDir.path;

      // Get app directories sizes
      info['tempDirectorySize'] = await _getDirectorySize(tempDir);
      info['docsDirectorySize'] = await _getDirectorySize(docDir);
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Error getting storage info: $e');
      }
    }

    return info;
  }

  /// Get total size of files in a directory
  static Future<int> _getDirectorySize(Directory directory) async {
    int totalSize = 0;

    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
    } catch (e) {
      if (AppConfig.debugMode) {
        print('Error calculating directory size: $e');
      }
    }

    return totalSize;
  }

  /// Get scan summary
  static Future<String> getScanSummary() async {
    final buffer = StringBuffer('File Scanner Summary:\n');

    try {
      final files = await scanForFiles();
      final storageInfo = await getStorageInfo();

      buffer.writeln('Total files found: ${files.length}');
      buffer.writeln(
          'Configured directories: ${AppConfig.autoScanDirectories.join(', ')}');

      if (AppConfig.allowedExtensions.isNotEmpty) {
        buffer.writeln(
            'Allowed extensions: ${AppConfig.allowedExtensions.join(', ')}');
      } else {
        buffer.writeln('Allowed extensions: All files');
      }

      // Group files by type
      final imageFiles = files.where((f) => f.isImage).length;
      final docFiles = files.where((f) => f.isDocument).length;
      final videoFiles = files.where((f) => f.isVideo).length;
      final otherFiles = files.length - imageFiles - docFiles - videoFiles;

      buffer.writeln('Images: $imageFiles');
      buffer.writeln('Documents: $docFiles');
      buffer.writeln('Videos: $videoFiles');
      buffer.writeln('Other: $otherFiles');

      if (storageInfo.isNotEmpty) {
        buffer.writeln('Storage info: ${storageInfo.keys.join(', ')}');
      }
    } catch (e) {
      buffer.writeln('Error: $e');
    }

    return buffer.toString();
  }
}
