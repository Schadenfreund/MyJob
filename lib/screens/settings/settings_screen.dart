import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../services/settings_service.dart';
import '../../providers/applications_provider.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../constants/ui_constants.dart';
import '../../widgets/profile_section_card.dart';
import '../../utils/dialog_utils.dart';
import '../../services/backup_service.dart';
import 'package:file_picker/file_picker.dart';

/// Settings screen - Consistent card design with other tabs
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return Container(
          color: theme.colorScheme.surface,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customize your experience',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Accent Color Section
                ProfileSectionCard(
                  title: 'Accent Color',
                  icon: Icons.palette_outlined,
                  count: 1,
                  actionLabel: '',
                  onActionPressed: null,
                  initiallyExpanded: true,
                  collapsedPreview: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: settings.accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Selected color',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose your preferred accent color. This color will be used throughout the app for highlights and interactive elements.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ColorButton(
                            color: AppTheme.lightPrimary,
                            isSelected: settings.accentColor.toARGB32() ==
                                AppTheme.lightPrimary.toARGB32(),
                            onTap: () =>
                                settings.setAccentColor(AppTheme.lightPrimary),
                            label: 'Blue',
                          ),
                          _ColorButton(
                            color: AppTheme.lightSuccess,
                            isSelected: settings.accentColor.toARGB32() ==
                                AppTheme.lightSuccess.toARGB32(),
                            onTap: () =>
                                settings.setAccentColor(AppTheme.lightSuccess),
                            label: 'Green',
                          ),
                          _ColorButton(
                            color: AppTheme.lightInfo,
                            isSelected: settings.accentColor.toARGB32() ==
                                AppTheme.lightInfo.toARGB32(),
                            onTap: () =>
                                settings.setAccentColor(AppTheme.lightInfo),
                            label: 'Cyan',
                          ),
                          _ColorButton(
                            color: AppTheme.lightWarning,
                            isSelected: settings.accentColor.toARGB32() ==
                                AppTheme.lightWarning.toARGB32(),
                            onTap: () =>
                                settings.setAccentColor(AppTheme.lightWarning),
                            label: 'Orange',
                          ),
                          _ColorButton(
                            color: AppTheme.lightDanger,
                            isSelected: settings.accentColor.toARGB32() ==
                                AppTheme.lightDanger.toARGB32(),
                            onTap: () =>
                                settings.setAccentColor(AppTheme.lightDanger),
                            label: 'Red',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Data Management Section
                ProfileSectionCard(
                  title: 'Data Management',
                  icon: Icons.storage_outlined,
                  count: 1,
                  actionLabel: '',
                  onActionPressed: null,
                  initiallyExpanded: false,
                  collapsedPreview: Text(
                    'Reset settings and manage data',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                  content: Column(
                    children: [
                      // Backup Folder Selection
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: settings.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.folder_outlined,
                              color: settings.accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Backup Destination',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  settings.backupPath ??
                                      'No backup location defined',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(
                                            settings.backupPath == null
                                                ? 0.4
                                                : 0.7),
                                    fontStyle: settings.backupPath == null
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _pickBackupPath(context, settings),
                            icon: const Icon(Icons.folder_open, size: 18),
                            label: const Text('Select'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: settings.accentColor,
                              side: BorderSide(
                                color: settings.accentColor.withOpacity(0.5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: settings.backupPath == null
                              ? null
                              : () => _performBackup(context, settings),
                          icon: const Icon(Icons.archive_outlined),
                          label: const Text('Create Backup Zip'),
                          style: FilledButton.styleFrom(
                            backgroundColor: settings.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Restore
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: settings.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.settings_backup_restore,
                              color: settings.accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Restore Backup',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Restore entire UserData from a zip file',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _pickRestoreFile(context, settings),
                            icon:
                                const Icon(Icons.unarchive_outlined, size: 18),
                            label: const Text('Restore Zip'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: settings.accentColor,
                              side: BorderSide(
                                color: settings.accentColor.withOpacity(0.5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // About Section - Non-collapsible with statistics inside
                Consumer<ApplicationsProvider>(
                  builder: (context, applicationsProvider, _) {
                    final totalApps =
                        applicationsProvider.allApplications.length;

                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.work_outline,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppInfo.appName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Version ${AppInfo.version}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Statistics - Styled like mockup
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    settings.accentColor.withOpacity(0.1),
                                    settings.accentColor.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: settings.accentColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.work,
                                    size: 32,
                                    color: settings.accentColor,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    totalApps.toString(),
                                    style:
                                        theme.textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: settings.accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Job Application${totalApps == 1 ? '' : 's'} Created',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Support message and button - Outside the card, centered
                Center(
                  child: Column(
                    children: [
                      // Footer message with heart icon - single line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Made with ',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          Icon(
                            Icons.favorite,
                            size: 18,
                            color: settings.accentColor,
                          ),
                          Text(
                            ' for you to enjoy. Please consider supporting the development.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Support button (no icon)
                      FilledButton(
                        onPressed: () => _openSupportLink(),
                        style:
                            UIConstants.getPrimaryButtonStyle(context).copyWith(
                          backgroundColor:
                              WidgetStateProperty.all(settings.accentColor),
                          foregroundColor:
                              WidgetStateProperty.all(Colors.white),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                          ),
                        ),
                        child: const Text('Support'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSupportLink() async {
    const url = 'https://www.paypal.com/paypalme/ivburic';
    try {
      // On Windows, use cmd to open the URL
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      debugPrint('Failed to open support link: $e');
    }
  }

  void _pickBackupPath(BuildContext context, SettingsService settings) async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Backup Destination',
      initialDirectory: settings.backupPath,
    );

    if (path != null) {
      settings.setBackupPath(path);
    }
  }

  void _performBackup(BuildContext context, SettingsService settings) async {
    final backupPath = settings.backupPath;
    if (backupPath == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Creating backup zip...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final file = await BackupService.instance.createBackup(backupPath);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (file != null) {
          context.showSuccessSnackBar(
              'Backup created successfully: ${file.path.split(Platform.pathSeparator).last}');
        } else {
          context.showErrorSnackBar('Failed to create backup');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        context.showErrorSnackBar('Error: $e');
      }
    }
  }

  void _pickRestoreFile(BuildContext context, SettingsService settings) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'Select Backup Zip to Restore',
    );

    if (result == null || result.files.single.path == null) return;

    if (!context.mounted) return;

    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Restore Backup?',
      message:
          'This will overwrite ALL current profile data, job applications, and presets with the data from the backup. This action cannot be undone.',
      confirmLabel: 'Restore & Restart',
      icon: Icons.settings_backup_restore,
    );

    if (confirmed && context.mounted) {
      _performRestore(context, result.files.single.path!);
    }
  }

  void _performRestore(BuildContext context, String zipPath) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Restoring backup...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final success = await BackupService.instance.restoreBackup(zipPath);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          // Since we overwritten everything, the app state is now invalid
          // Most robust thing is to tell the user to restart
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Restore Successful'),
              content: const Text(
                  'Your data has been restored. The application needs to be restarted to load the new data.'),
              actions: [
                FilledButton(
                  onPressed: () => exit(0),
                  child: const Text('Close Application'),
                ),
              ],
            ),
          );
        } else {
          context.showErrorSnackBar('Failed to restore backup');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        context.showErrorSnackBar('Error during restore: $e');
      }
    }
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.label,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : theme.dividerColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? color
                    : theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
