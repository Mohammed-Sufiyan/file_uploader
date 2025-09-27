import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../config.dart';
import '../models/file_upload_item.dart';
import '../services/file_scanner_service.dart';
import '../services/upload_service.dart';
import '../services/permission_service.dart';
import 'widgets/gradient_app_bar.dart';
import 'widgets/file_upload_card.dart';

/// Main screen of the file upload application
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<FileUploadItem> _files = [];
  bool _isScanning = false;
  bool _isUploading = false;
  bool _hasPermissions = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize the application
  Future<void> _initializeApp() async {
    await _checkPermissions();
    if (_hasPermissions) {
      await _performInitialScan();
    }
  }

  /// Check and request necessary permissions
  Future<void> _checkPermissions() async {
    final hasPermissions = await PermissionService.checkFilePermissions();

    if (!hasPermissions) {
      final granted = await PermissionService.requestFilePermissions();
      setState(() {
        _hasPermissions = granted;
      });

      if (!granted) {
        _showPermissionDialog();
      }
    } else {
      setState(() {
        _hasPermissions = true;
      });
    }
  }

  /// Perform initial file scan
  Future<void> _performInitialScan() async {
    if (!_hasPermissions) return;

    setState(() {
      _isScanning = true;
    });

    try {
      final scannedFiles = await FileScannerService.scanForFiles();
      setState(() {
        _files = scannedFiles;
      });

      if (AppConfig.debugMode) {
        print('Initial scan found ${scannedFiles.length} files');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to scan files: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: AppConfig.appName,
        actions: [
          IconButton(
            onPressed: _showConfigurationDialog,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: _hasPermissions ? _buildMainContent() : _buildPermissionScreen(),
      floatingActionButton:
          _hasPermissions ? _buildFloatingActionButton() : null,
    );
  }

  /// Build main content with tabs
  Widget _buildMainContent() {
    return Column(
      children: [
        _buildStatusCard(),
        _buildTabBar(),
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  /// Build status card showing upload progress
  Widget _buildStatusCard() {
    final stats = UploadService.getUploadStats(_files);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${stats['completed']}/${stats['totalFiles']} files completed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[700],
                      ),
                ),
                if (stats['totalFiles'] > 0)
                  LinearProgressIndicator(
                    value: stats['completed'] / stats['totalFiles'],
                    backgroundColor: Colors.blue[200],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isUploading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.cloud_upload,
                  color: Colors.blue[600],
                  size: 24,
                ),
              const SizedBox(height: 8),
              Text(
                '${stats['successRate']}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build tab bar
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('All Files', 0),
          ),
          Expanded(
            child: _buildTabButton('Queued', 1),
          ),
          Expanded(
            child: _buildTabButton('Completed', 2),
          ),
        ],
      ),
    );
  }

  /// Build individual tab button
  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    final count = _getTabCount(index);

    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$title ($count)',
            style: TextStyle(
              color: isSelected ? Colors.blue[800] : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// Get count for each tab
  int _getTabCount(int tabIndex) {
    switch (tabIndex) {
      case 0: // All files
        return _files.length;
      case 1: // Queued
        return _files
            .where((f) =>
                f.status == UploadStatus.queued ||
                f.status == UploadStatus.uploading)
            .length;
      case 2: // Completed
        return _files.where((f) => f.status == UploadStatus.completed).length;
      default:
        return 0;
    }
  }

  /// Build tab content
  Widget _buildTabContent() {
    List<FileUploadItem> filteredFiles;

    switch (_selectedTabIndex) {
      case 1: // Queued
        filteredFiles = _files
            .where((f) =>
                f.status == UploadStatus.queued ||
                f.status == UploadStatus.uploading ||
                f.status == UploadStatus.failed)
            .toList();
        break;
      case 2: // Completed
        filteredFiles =
            _files.where((f) => f.status == UploadStatus.completed).toList();
        break;
      case 0: // All files
      default:
        filteredFiles = _files;
        break;
    }

    if (filteredFiles.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: filteredFiles.length,
      itemBuilder: (context, index) {
        final file = filteredFiles[index];
        return FileUploadCard(
          fileItem: file,
          onDelete: () => _deleteFile(file),
          onRetry: file.status == UploadStatus.failed
              ? () => _retryUpload(file)
              : null,
        );
      },
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedTabIndex) {
      case 1:
        message = 'No files queued for upload';
        icon = Icons.upload_file;
        break;
      case 2:
        message = 'No files uploaded yet';
        icon = Icons.cloud_done;
        break;
      default:
        message = _isScanning ? 'Scanning for files...' : 'No files found';
        icon = Icons.folder_open;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isScanning)
            const CircularProgressIndicator()
          else
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          if (!_isScanning && _files.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.add),
              label: const Text('Pick Files'),
            ),
          ],
        ],
      ),
    );
  }

  /// Build permission screen
  Widget _buildPermissionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 64,
              color: Colors.orange[600],
            ),
            const SizedBox(height: 24),
            Text(
              'Storage Permission Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This app needs storage permissions to scan and upload files from your device.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _checkPermissions,
              icon: const Icon(Icons.security),
              label: const Text('Grant Permissions'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build floating action button
  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: _pickFiles,
          heroTag: 'pick_files',
          child: const Icon(Icons.add),
          backgroundColor: Colors.blue[600],
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: _isScanning ? null : _rescanFiles,
          heroTag: 'rescan',
          child: _isScanning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh),
          backgroundColor: Colors.green[600],
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: _isUploading ? null : _uploadPendingFiles,
          heroTag: 'upload',
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.cloud_upload),
          backgroundColor: Colors.orange[600],
        ),
      ],
    );
  }

  /// Pick files manually
  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: AppConfig.allowedExtensions.isEmpty
            ? FileType.any
            : FileType.custom,
        allowedExtensions: AppConfig.allowedExtensions.isEmpty
            ? null
            : AppConfig.allowedExtensions
                .map((e) => e.replaceFirst('.', ''))
                .toList(),
      );

      if (result != null) {
        final newFiles = result.paths
            .where((path) => path != null)
            .map((path) => FileUploadItem.fromFile(File(path!)))
            .toList();

        setState(() {
          _files.addAll(newFiles);
        });

        _showSuccessSnackBar('Added ${newFiles.length} files');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick files: $e');
    }
  }

  /// Rescan files
  Future<void> _rescanFiles() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final scannedFiles = await FileScannerService.scanForFiles();

      // Merge with existing files, avoiding duplicates
      final existingPaths = _files.map((f) => f.filePath).toSet();
      final newFiles = scannedFiles
          .where((f) => !existingPaths.contains(f.filePath))
          .toList();

      setState(() {
        _files.addAll(newFiles);
      });

      _showSuccessSnackBar('Found ${newFiles.length} new files');
    } catch (e) {
      _showErrorSnackBar('Failed to scan files: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  /// Upload pending files
  Future<void> _uploadPendingFiles() async {
    if (!UploadService.isConfigured) {
      _showConfigurationDialog();
      return;
    }

    final pendingFiles = _files
        .where((f) =>
            f.status == UploadStatus.queued || f.status == UploadStatus.failed)
        .toList();

    if (pendingFiles.isEmpty) {
      _showInfoSnackBar('No files to upload');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await UploadService.uploadFiles(
        pendingFiles,
        (file, progress) {
          // Update individual file progress
          setState(() {
            file.updateProgress(progress);
          });
        },
        (completed, total) {
          // Update batch progress
          if (AppConfig.debugMode) {
            print('Batch progress: $completed/$total');
          }
        },
      );

      _showSuccessSnackBar('Upload completed');
    } catch (e) {
      _showErrorSnackBar('Upload failed: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  /// Delete a file from the list
  void _deleteFile(FileUploadItem file) {
    setState(() {
      _files.remove(file);
    });
    _showInfoSnackBar('Removed ${file.fileName}');
  }

  /// Retry upload for a failed file
  Future<void> _retryUpload(FileUploadItem file) async {
    file.reset();

    final success = await UploadService.uploadFile(file, (progress) {
      setState(() {
        file.updateProgress(progress);
      });
    });

    if (success) {
      _showSuccessSnackBar('${file.fileName} uploaded successfully');
    } else {
      _showErrorSnackBar('Failed to upload ${file.fileName}');
    }
  }

  /// Show configuration dialog
  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Upload Mode: ${AppConfig.usePresignedUrl ? 'Presigned URL' : 'Direct Bucket'}'),
            Text('Endpoint: ${AppConfig.uploadEndpoint}'),
            Text(
                'Auto Delete: ${AppConfig.autoDeleteAfterUpload ? 'Yes' : 'No'}'),
            Text('Max Queue: ${AppConfig.maxQueuedFiles} files'),
            const SizedBox(height: 16),
            Text(
              'Configuration Status: ${AppConfig.isConfigurationValid ? 'Valid' : 'Invalid'}',
              style: TextStyle(
                color:
                    AppConfig.isConfigurationValid ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show permission dialog
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is required to scan and upload files. Please grant permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              PermissionService.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Show success snack bar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Show error snack bar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Show info snack bar
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
