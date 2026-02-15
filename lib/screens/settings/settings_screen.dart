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
import '../../widgets/update_card.dart';
import '../../localization/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import '../../exceptions/backup_exceptions.dart';

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
                  title: context.tr('settings_title'),
                  subtitle: context.tr('settings_subtitle'),
                  icon: Icons.settings_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Accent Color Section
                AppCard(
                  title: context.tr('accent_color'),
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
                                  context.tr('current_color'),
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
                          label: context.tr('color_blue'),
                        ),
                        _ColorButton(
                          color: AppColors.lightSuccess,
                          isSelected: settings.accentColor.toARGB32() ==
                              AppColors.lightSuccess.toARGB32(),
                          onTap: () =>
                              settings.setAccentColor(AppColors.lightSuccess),
                          label: context.tr('color_green'),
                        ),
                        _ColorButton(
                          color: AppColors.lightInfo,
                          isSelected: settings.accentColor.toARGB32() ==
                              AppColors.lightInfo.toARGB32(),
                          onTap: () =>
                              settings.setAccentColor(AppColors.lightInfo),
                          label: context.tr('color_cyan'),
                        ),
                        _ColorButton(
                          color: AppColors.lightWarning,
                          isSelected: settings.accentColor.toARGB32() ==
                              AppColors.lightWarning.toARGB32(),
                          onTap: () =>
                              settings.setAccentColor(AppColors.lightWarning),
                          label: context.tr('color_orange'),
                        ),
                        _ColorButton(
                          color: AppColors.lightDanger,
                          isSelected: settings.accentColor.toARGB32() ==
                              AppColors.lightDanger.toARGB32(),
                          onTap: () =>
                              settings.setAccentColor(AppColors.lightDanger),
                          label: context.tr('color_red'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Language Selection Section
                Consumer<AppLocalizations>(
                  builder: (context, loc, _) {
                    final languages = loc.availableLanguages;
                    return AppCard(
                      title: loc.tr('language_title'),
                      icon: Icons.translate_outlined,
                      children: [
                        // Current language indicator
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
                              color:
                                  settings.accentColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: settings.accentColor
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    loc.currentLanguageCode.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: settings.accentColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.tr('current_language'),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.textTheme.bodySmall?.color
                                            ?.withValues(alpha: 0.6),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      loc.currentLanguage?.name ??
                                          loc.currentLanguageCode.toUpperCase(),
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: settings.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Language selection buttons
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: languages.map((lang) {
                            final isSelected =
                                lang.code == loc.currentLanguageCode;
                            return _LanguageButton(
                              languageCode: lang.code,
                              languageName: lang.name,
                              isSelected: isSelected,
                              accentColor: settings.accentColor,
                              onTap: () {
                                loc.setLanguage(lang.code);
                                settings.setAppLanguage(lang.code);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Data Management Section
                AppCard(
                  title: context.tr('data_management'),
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
                                context.tr('backup_destination'),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                settings.backupPath ??
                                    context.tr('no_backup_location'),
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
                          label: context.tr('select'),
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
                        label: context.tr('create_backup_zip'),
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
                                context.tr('restore_backup'),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('restore_backup_desc'),
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
                          label: context.tr('restore_zip'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Software Updates Section
                UpdateCard(),
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
                          AppCardHeader(
                            icon: Icons.work_outline,
                            title: AppInfo.appName,
                            description: context.tr('version_label',
                                {'version': AppInfo.version}),
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
                                  context.tr(totalApps == 1
                                      ? 'job_application_created'
                                      : 'job_applications_created'),
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
                            '${context.tr('made_with_love')} ',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: settings.accentColor,
                          ),
                          Text(
                            ' ${context.tr('for_you_to_enjoy')}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('support_development'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppCardActionButton(
                        onPressed: () => _openSupportLink(),
                        label: context.tr('support'),
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
      dialogTitle: context.tr('select_backup_destination'),
      initialDirectory: settings.backupPath,
    );

    if (path != null) {
      settings.setBackupPath(path);
    }
  }

  void _performBackup(BuildContext context, SettingsService settings) async {
    final backupPath = settings.backupPath;
    if (backupPath == null) return;

    // Show warning dialog to prevent race conditions
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('backup_in_progress')),
        content: Text(context.tr('backup_warning_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('continue')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final closeLoading = DialogUtils.showLoading(context,
        message: context.tr('creating_backup_please_wait'));

    try {
      final file = await BackupService.instance.createBackup(backupPath);

      if (context.mounted) {
        closeLoading();

        if (file != null) {
          context.showSuccessSnackBar(context.tr('backup_created',
              {'filename': file.path.split(Platform.pathSeparator).last}));
        } else {
          context.showErrorSnackBar(context.tr('backup_failed'));
        }
      }
    } on BackupDiskFullException catch (e) {
      if (context.mounted) {
        closeLoading();
        context.showErrorSnackBar(e.toString());
      }
    } on BackupPermissionException catch (e) {
      if (context.mounted) {
        closeLoading();
        context.showErrorSnackBar(e.toString());
      }
    } on BackupException catch (e) {
      if (context.mounted) {
        closeLoading();
        context.showErrorSnackBar(e.message);
      }
    } catch (e) {
      if (context.mounted) {
        closeLoading();
        context.showErrorSnackBar(
            context.tr('error_generic', {'error': e.toString()}));
      }
    }
  }

  void _pickRestoreFile(BuildContext context, SettingsService settings) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: context.tr('select_backup_zip'),
    );

    if (result == null || result.files.single.path == null) return;

    if (!context.mounted) return;

    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: context.tr('restore_confirm_title'),
      message: context.tr('restore_confirm_message'),
      confirmLabel: context.tr('restore_confirm_button'),
      icon: Icons.settings_backup_restore,
    );

    if (confirmed && context.mounted) {
      _performRestore(context, result.files.single.path!);
    }
  }

  void _performRestore(BuildContext context, String zipPath) async {
    final closeLoading = DialogUtils.showLoading(context,
        message: context.tr('restoring_backup'));

    try {
      final success = await BackupService.instance.restoreBackup(zipPath);

      if (context.mounted) {
        closeLoading();

        if (success) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(context.tr('restore_successful_title')),
              content: Text(context.tr('restore_successful_message')),
              actions: [
                FilledButton(
                  onPressed: () => exit(0),
                  child: Text(context.tr('close_application')),
                ),
              ],
            ),
          );
        } else {
          context.showErrorSnackBar(context.tr('restore_failed'));
        }
      }
    } on BackupValidationException catch (e) {
      if (context.mounted) {
        closeLoading();
        context.showErrorSnackBar(e.message);
      }
    } on BackupCorruptedException catch (e) {
      if (context.mounted) {
        closeLoading();
        context.showErrorSnackBar(e.toString());
      }
    } on BackupDiskFullException catch (e) {
      if (context.mounted) {
        closeLoading();
        context.showErrorSnackBar(e.toString());
      }
    } on BackupPermissionException catch (e) {
      if (context.mounted) {
        closeLoading();
        context.showErrorSnackBar(e.toString());
      }
    } on BackupException catch (e) {
      if (context.mounted) {
        closeLoading();
        context.showErrorSnackBar(e.message);
      }
    } catch (e) {
      if (context.mounted) {
        closeLoading();
        context.showErrorSnackBar(
            context.tr('error_restore', {'error': e.toString()}));
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

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.languageCode,
    required this.languageName,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final String languageCode;
  final String languageName;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

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
              ? accentColor.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accentColor
                : AppColors.getColor(
                        context, AppColors.lightBorder, AppColors.darkBorder)
                    .withValues(alpha: 0.5),
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
                color: isSelected
                    ? accentColor.withValues(alpha: 0.2)
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.6)
                      : theme.dividerColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  languageCode.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? accentColor
                        : theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              languageName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? accentColor
                    : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
