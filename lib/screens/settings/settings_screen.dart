import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../services/settings_service.dart';
import '../../providers/applications_provider.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../utils/dialog_utils.dart';
import '../../utils/ui_utils.dart';
import '../../services/backup_service.dart';
import '../../widgets/app_card.dart';
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                UIUtils.buildSectionHeader(
                  context,
                  title: 'Settings',
                  subtitle: 'Customize your experience',
                  icon: Icons.settings_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Accent Color Section
                AppCard(
                  title: 'Accent Color',
                  icon: Icons.palette_outlined,
                  children: [
                    // Current color hex value display
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            settings.accentColor.withValues(alpha: 0.08),
                            settings.accentColor.withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.cardBorderRadius),
                        border: Border.all(
                          color: settings.accentColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Color preview circle
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: settings.accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: settings.accentColor
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Hex value
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Color',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '#${settings.accentColor.value.toRadixString(16).substring(2).toUpperCase()}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: settings.accentColor,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Color selection buttons
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _ColorButton(
                          color: AppColors.lightPrimary,
                          isSelected: settings.accentColor.toARGB32() ==
                              AppColors.lightPrimary.toARGB32(),
                          onTap: () =>
                              settings.setAccentColor(AppColors.lightPrimary),
                          label: 'Blue',
                        ),
                        _ColorButton(
                          color: AppColors.lightSuccess,
                          isSelected: settings.accentColor.toARGB32() ==
                              AppColors.lightSuccess.toARGB32(),
                          onTap: () =>
                              settings.setAccentColor(AppColors.lightSuccess),
                          label: 'Green',
                        ),
                        _ColorButton(
                          color: AppColors.lightInfo,
                          isSelected: settings.accentColor.toARGB32() ==
                              AppColors.lightInfo.toARGB32(),
                          onTap: () =>
                              settings.setAccentColor(AppColors.lightInfo),
                          label: 'Cyan',
                        ),
                        _ColorButton(
                          color: AppColors.lightWarning,
                          isSelected: settings.accentColor.toARGB32() ==
                              AppColors.lightWarning.toARGB32(),
                          onTap: () =>
                              settings.setAccentColor(AppColors.lightWarning),
                          label: 'Orange',
                        ),
                        _ColorButton(
                          color: AppColors.lightDanger,
                          isSelected: settings.accentColor.toARGB32() ==
                              AppColors.lightDanger.toARGB32(),
                          onTap: () =>
                              settings.setAccentColor(AppColors.lightDanger),
                          label: 'Red',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Data Management Section
                AppCard(
                  title: 'Data Management',
                  icon: Icons.storage_outlined,
                  children: [
                    // Backup Folder Selection
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: settings.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.inputBorderRadius),
                          ),
                          child: Icon(
                            Icons.folder_outlined,
                            color: settings.accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
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
                                      ?.withOpacity(settings.backupPath == null
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
                        AppCardActionButton(
                          onPressed: () => _pickBackupPath(context, settings),
                          icon: Icons.folder_open,
                          label: 'Select',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: AppCardActionButton(
                        onPressed: settings.backupPath == null
                            ? () {} // Need non-null to not be disabled visually in my custom button if I didn't handle null
                            : () => _performBackup(context, settings),
                        icon: Icons.archive_outlined,
                        label: 'Create Backup Zip',
                        isFilled: settings.backupPath != null,
                        color: settings.backupPath == null
                            ? theme.disabledColor
                            : settings.accentColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Restore
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: settings.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.inputBorderRadius),
                          ),
                          child: Icon(
                            Icons.settings_backup_restore,
                            color: settings.accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
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
                        AppCardActionButton(
                          onPressed: () => _pickRestoreFile(context, settings),
                          icon: Icons.unarchive_outlined,
                          label: 'Restore Zip',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // About Section - Using AppCardContainer for premium look
                Consumer<ApplicationsProvider>(
                  builder: (context, applicationsProvider, _) {
                    final totalApps =
                        applicationsProvider.allApplications.length;

                    return AppCardContainer(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: settings.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.work_outline,
                                  color: settings.accentColor,
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
                          const SizedBox(height: AppSpacing.lg),

                          // Statistics
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  settings.accentColor.withOpacity(0.1),
                                  settings.accentColor.withOpacity(0.04),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.cardBorderRadius),
                              border: Border.all(
                                color: settings.accentColor.withOpacity(0.2),
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
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  totalApps.toString(),
                                  style:
                                      theme.textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: settings.accentColor,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
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
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Support message and button
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Made with ',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: settings.accentColor,
                          ),
                          Text(
                            ' for you to enjoy.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please consider supporting the development.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppCardActionButton(
                        onPressed: () => _openSupportLink(),
                        label: 'Support',
                        isFilled: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
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

    final closeLoading =
        DialogUtils.showLoading(context, message: 'Creating backup zip...');

    try {
      final file = await BackupService.instance.createBackup(backupPath);

      if (context.mounted) {
        closeLoading();

        if (file != null) {
          context.showSuccessSnackBar(
              'Backup created successfully: ${file.path.split(Platform.pathSeparator).last}');
        } else {
          context.showErrorSnackBar('Failed to create backup');
        }
      }
    } catch (e) {
      if (context.mounted) {
        closeLoading();
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
    final closeLoading =
        DialogUtils.showLoading(context, message: 'Restoring backup...');

    try {
      final success = await BackupService.instance.restoreBackup(zipPath);

      if (context.mounted) {
        closeLoading();

        if (success) {
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
        closeLoading();
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
      child: AnimatedContainer(
        duration: AppDurations.quick,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.12)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : AppColors.getColor(
                        context, AppColors.lightBorder, AppColors.darkBorder)
                    .withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
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
