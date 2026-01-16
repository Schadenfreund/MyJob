import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/update_info.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../dialogs/changelog_dialog.dart';
import 'app_card.dart';

/// Card widget for checking and installing app updates
class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updateService, _) {
        return AppCard(
          title: 'Software Updates',
          icon: Icons.system_update_outlined,
          description: 'Check for new versions',
          children: [
            _buildContent(context, updateService),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, UpdateService updateService) {
    switch (updateService.state) {
      case UpdateState.idle:
        return _IdleState(updateService: updateService);
      case UpdateState.checking:
        return const _CheckingState();
      case UpdateState.upToDate:
        return _UpToDateState(updateService: updateService);
      case UpdateState.available:
        return _UpdateAvailableState(updateService: updateService);
      case UpdateState.downloading:
        return _DownloadingState(updateService: updateService);
      case UpdateState.extracting:
        return const _ExtractingState();
      case UpdateState.readyToInstall:
        return _ReadyToInstallState(updateService: updateService);
      case UpdateState.installing:
        return const _InstallingState();
      case UpdateState.error:
        return _ErrorState(updateService: updateService);
    }
  }
}

class _IdleState extends StatelessWidget {
  final UpdateService updateService;

  const _IdleState({required this.updateService});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VersionInfo(version: updateService.currentVersion),
        const SizedBox(height: AppSpacing.md),
        AppCardActionButton(
          label: 'Check for Updates',
          icon: Icons.refresh,
          onPressed: () => updateService.checkForUpdates(),
        ),
      ],
    );
  }
}

class _CheckingState extends StatelessWidget {
  const _CheckingState();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(settings.accentColor),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Checking for updates...',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _UpToDateState extends StatelessWidget {
  final UpdateService updateService;

  const _UpToDateState({required this.updateService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'You\'re up to date!',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _VersionInfo(version: updateService.currentVersion),
        if (updateService.lastCheckTime != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Last checked: ${_formatTime(updateService.lastCheckTime!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        AppCardActionButton(
          label: 'Check Again',
          icon: Icons.refresh,
          onPressed: () => updateService.checkForUpdates(force: true),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${time.day}.${time.month}.${time.year}';
  }
}

class _UpdateAvailableState extends StatelessWidget {
  final UpdateService updateService;

  const _UpdateAvailableState({required this.updateService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsService>();
    final updateInfo = updateService.updateInfo!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // New version badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: settings.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
            border: Border.all(
              color: settings.accentColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.new_releases_outlined,
                size: 16,
                color: settings.accentColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'New version available: v${updateInfo.version}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: settings.accentColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Update details
        AppCardInfoRow(
          label: 'Current version',
          value: 'v${updateService.currentVersion}',
        ),
        AppCardInfoRow(
          label: 'New version',
          value: 'v${updateInfo.version}',
        ),
        AppCardInfoRow(
          label: 'Download size',
          value: updateInfo.formattedSize,
        ),
        AppCardInfoRow(
          label: 'Released',
          value: updateInfo.formattedDate,
        ),

        // Changelog preview
        if (updateInfo.changelog.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _ChangelogPreview(
            changelog: updateInfo.changelog,
            version: updateInfo.version,
          ),
        ],

        const SizedBox(height: AppSpacing.md),

        // Action buttons
        Row(
          children: [
            AppCardActionButton(
              label: 'Download Update',
              icon: Icons.download,
              isFilled: true,
              onPressed: () => updateService.downloadUpdate(),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppCardActionButton(
              label: 'Later',
              onPressed: () => updateService.reset(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChangelogPreview extends StatelessWidget {
  final String changelog;
  final String version;

  const _ChangelogPreview({
    required this.changelog,
    required this.version,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Show first 3 lines of changelog
    final lines = changelog.split('\n').where((l) => l.trim().isNotEmpty).take(3);
    final preview = lines.join('\n');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's new:",
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            preview,
            style: theme.textTheme.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: () => _showFullChangelog(context),
            child: Text(
              'View full changelog',
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.read<SettingsService>().accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullChangelog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ChangelogDialog(
        changelog: changelog,
        version: version,
      ),
    );
  }
}

class _DownloadingState extends StatelessWidget {
  final UpdateService updateService;

  const _DownloadingState({required this.updateService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsService>();
    final progress = updateService.downloadProgress;
    final percentage = (progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Downloading update... $percentage%',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () => updateService.cancelDownload(),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: settings.accentColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(settings.accentColor),
            minHeight: 8,
          ),
        ),
        if (updateService.updateInfo != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            updateService.updateInfo!.formattedSize,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ExtractingState extends StatelessWidget {
  const _ExtractingState();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(settings.accentColor),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Preparing update...',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ReadyToInstallState extends StatelessWidget {
  final UpdateService updateService;

  const _ReadyToInstallState({required this.updateService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Update ready to install!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'The app will close and restart automatically.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            AppCardActionButton(
              label: 'Install & Restart',
              icon: Icons.system_update,
              isFilled: true,
              onPressed: () => _confirmAndInstall(context, updateService),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppCardActionButton(
              label: 'Later',
              onPressed: () => updateService.reset(),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmAndInstall(BuildContext context, UpdateService updateService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Install Update?'),
        content: const Text(
          'The application will close and restart with the new version. '
          'Your data will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              updateService.installUpdate();
            },
            child: const Text('Install Now'),
          ),
        ],
      ),
    );
  }
}

class _InstallingState extends StatelessWidget {
  const _InstallingState();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(settings.accentColor),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Installing update...',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final UpdateService updateService;

  const _ErrorState({required this.updateService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
            border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  updateService.errorMessage ?? 'An error occurred',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            AppCardActionButton(
              label: 'Try Again',
              icon: Icons.refresh,
              onPressed: () {
                updateService.reset();
                updateService.checkForUpdates(force: true);
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            AppCardActionButton(
              label: 'Manual Download',
              icon: Icons.open_in_new,
              onPressed: () => updateService.openReleasesPage(),
            ),
          ],
        ),
      ],
    );
  }
}

class _VersionInfo extends StatelessWidget {
  final String version;

  const _VersionInfo({required this.version});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Text(
      'Current version: v$version',
      style: theme.textTheme.bodySmall?.copyWith(
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      ),
    );
  }
}
