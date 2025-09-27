import 'package:flutter/material.dart';
import '../../models/file_upload_item.dart';

/// Card widget to display file upload information with progress
class FileUploadCard extends StatelessWidget {
  final FileUploadItem fileItem;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;
  final VoidCallback? onPause;
  final bool showActions;

  const FileUploadCard({
    Key? key,
    required this.fileItem,
    this.onDelete,
    this.onRetry,
    this.onPause,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFileHeader(context),
            const SizedBox(height: 12),
            _buildFileInfo(context),
            const SizedBox(height: 12),
            _buildProgressSection(context),
            if (showActions) ...[
              const SizedBox(height: 12),
              _buildActionButtons(context),
            ],
          ],
        ),
      ),
    );
  }

  /// Build the file header with icon and name
  Widget _buildFileHeader(BuildContext context) {
    return Row(
      children: [
        _buildFileIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileItem.fileName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                fileItem.formattedFileSize,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        _buildStatusIcon(),
      ],
    );
  }

  /// Build file type icon
  Widget _buildFileIcon() {
    IconData iconData;
    Color iconColor;

    if (fileItem.isImage) {
      iconData = Icons.image;
      iconColor = Colors.green;
    } else if (fileItem.isDocument) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (fileItem.isVideo) {
      iconData = Icons.videocam;
      iconColor = Colors.red;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  /// Build status icon
  Widget _buildStatusIcon() {
    switch (fileItem.status) {
      case UploadStatus.completed:
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 24,
        );
      case UploadStatus.failed:
        return const Icon(
          Icons.error,
          color: Colors.red,
          size: 24,
        );
      case UploadStatus.uploading:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        );
      case UploadStatus.paused:
        return const Icon(
          Icons.pause_circle,
          color: Colors.orange,
          size: 24,
        );
      case UploadStatus.queued:
      default:
        return const Icon(
          Icons.schedule,
          color: Colors.grey,
          size: 24,
        );
    }
  }

  /// Build file information section
  Widget _buildFileInfo(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Added: ${fileItem.formattedAddedDate}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              if (fileItem.completedDate != null)
                Text(
                  'Completed: ${fileItem.formattedCompletedDate}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                      ),
                ),
              if (!fileItem.fileExists)
                Text(
                  'File no longer exists on device',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[700],
                        fontStyle: FontStyle.italic,
                      ),
                ),
            ],
          ),
        ),
        Text(
          fileItem.statusDisplayText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  /// Build progress section with progress bar
  Widget _buildProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fileItem.status == UploadStatus.uploading ||
            fileItem.status == UploadStatus.completed) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
              Text(
                '${fileItem.uploadProgressPercent}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: fileItem.uploadProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              fileItem.status == UploadStatus.completed
                  ? Colors.green
                  : Theme.of(context).primaryColor,
            ),
            minHeight: 6,
          ),
        ],
        if (fileItem.errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[700],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileItem.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red[700],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (fileItem.status == UploadStatus.failed && onRetry != null)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          ),
        if (fileItem.status == UploadStatus.uploading && onPause != null)
          TextButton.icon(
            onPressed: onPause,
            icon: const Icon(Icons.pause, size: 16),
            label: const Text('Pause'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
          ),
        if (onDelete != null) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  /// Get color based on upload status
  Color _getStatusColor() {
    switch (fileItem.status) {
      case UploadStatus.completed:
        return Colors.green;
      case UploadStatus.failed:
        return Colors.red;
      case UploadStatus.uploading:
        return Colors.blue;
      case UploadStatus.paused:
        return Colors.orange;
      case UploadStatus.queued:
      default:
        return Colors.grey;
    }
  }
}

/// Compact version of file upload card for lists
class CompactFileUploadCard extends StatelessWidget {
  final FileUploadItem fileItem;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CompactFileUploadCard({
    Key? key,
    required this.fileItem,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: onTap,
        leading: _buildLeadingIcon(),
        title: Text(
          fileItem.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${fileItem.formattedFileSize} • ${fileItem.statusDisplayText}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fileItem.status == UploadStatus.uploading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: fileItem.uploadProgress,
                  strokeWidth: 2,
                ),
              )
            else
              _buildStatusIcon(),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, size: 18),
                color: Colors.red,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    IconData iconData;
    Color iconColor;

    if (fileItem.isImage) {
      iconData = Icons.image;
      iconColor = Colors.green;
    } else if (fileItem.isDocument) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (fileItem.isVideo) {
      iconData = Icons.videocam;
      iconColor = Colors.red;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (fileItem.status) {
      case UploadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case UploadStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 20);
      case UploadStatus.paused:
        return const Icon(Icons.pause_circle, color: Colors.orange, size: 20);
      case UploadStatus.queued:
      default:
        return const Icon(Icons.schedule, color: Colors.grey, size: 20);
    }
  }
}
