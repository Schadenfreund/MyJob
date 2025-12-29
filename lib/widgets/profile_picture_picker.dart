import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// A widget for selecting and displaying a profile picture
class ProfilePicturePicker extends StatelessWidget {
  const ProfilePicturePicker({
    super.key,
    this.imagePath,
    this.size = 120,
    this.onImageSelected,
    this.onImageRemoved,
    this.placeholderInitial,
    this.backgroundColor,
    this.borderColor,
  });

  /// Path to the current profile picture
  final String? imagePath;

  /// Size of the circular avatar
  final double size;

  /// Callback when an image is selected
  final ValueChanged<String>? onImageSelected;

  /// Callback when the image is removed
  final VoidCallback? onImageRemoved;

  /// Initial letter to show when no image is selected
  final String? placeholderInitial;

  /// Background color for the placeholder
  final Color? backgroundColor;

  /// Border color for the avatar
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    final bgColor = backgroundColor ?? theme.colorScheme.primary;
    final border = borderColor ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile picture container
        Stack(
          children: [
            // Avatar
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: border,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: hasImage
                    ? Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(theme, bgColor),
                      )
                    : _buildPlaceholder(theme, bgColor),
              ),
            ),

            // Edit button
            Positioned(
              bottom: 0,
              right: 0,
              child: _buildEditButton(context, theme, hasImage),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Helper text
        Text(
          hasImage ? 'Tap to change' : 'Add photo (optional)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ThemeData theme, Color bgColor) {
    final initial = placeholderInitial ?? '?';

    return Container(
      color: bgColor,
      child: Center(
        child: Text(
          initial.isNotEmpty ? initial[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEditButton(
      BuildContext context, ThemeData theme, bool hasImage) {
    return Material(
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => _showOptions(context),
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary,
          ),
          child: Icon(
            hasImage ? Icons.edit : Icons.add_a_photo,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context);
              },
            ),
            if (hasImage)
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Remove photo',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onImageRemoved?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          onImageSelected?.call(path);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
