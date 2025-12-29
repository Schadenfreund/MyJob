import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../widgets/collapsible_card.dart';
import '../../utils/ui_utils.dart';
import '../../utils/dialog_utils.dart';

/// Settings screen - Organized with CollapsibleCard sections
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
            padding: EdgeInsets.all(UIUtils.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                UIUtils.buildSectionHeader(
                  context,
                  title: 'Settings',
                  subtitle: 'Customize your experience',
                  icon: Icons.settings,
                ),
                SizedBox(height: UIUtils.spacingXl),

                // Appearance Section
                CollapsibleCard(
                  cardDecoration: UIUtils.getCardDecoration(context),
                  title: 'Appearance',
                  subtitle: 'Theme and colors',
                  status: CollapsibleCardStatus.configured,
                  initiallyCollapsed: false,
                  collapsedSummary: Row(
                    children: [
                      Icon(
                        _getThemeModeIcon(settings.themeMode),
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: UIUtils.spacingSm),
                      Expanded(
                        child: Text(
                          _getThemeModeLabel(settings.themeMode),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
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
                    ],
                  ),
                  expandedContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Theme mode
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.dark_mode,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Theme',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getThemeModeLabel(settings.themeMode),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SegmentedButton<ThemeMode>(
                            style: SegmentedButton.styleFrom(
                              selectedBackgroundColor:
                                  theme.colorScheme.primary,
                              selectedForegroundColor: Colors.white,
                            ),
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode, size: 18),
                              ),
                              ButtonSegment(
                                value: ThemeMode.system,
                                icon: Icon(Icons.settings_suggest, size: 18),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode, size: 18),
                              ),
                            ],
                            selected: {settings.themeMode},
                            onSelectionChanged: (selection) {
                              settings.setThemeMode(selection.first);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: UIUtils.spacingMd),
                      Divider(color: theme.dividerColor),
                      SizedBox(height: UIUtils.spacingMd),

                      // Accent color
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.palette,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Accent Color',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Choose your preferred color',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              _ColorButton(
                                color: AppTheme.lightPrimary,
                                isSelected: settings.accentColor.toARGB32() ==
                                    AppTheme.lightPrimary.toARGB32(),
                                onTap: () => settings
                                    .setAccentColor(AppTheme.lightPrimary),
                              ),
                              _ColorButton(
                                color: AppTheme.lightSuccess,
                                isSelected: settings.accentColor.toARGB32() ==
                                    AppTheme.lightSuccess.toARGB32(),
                                onTap: () => settings
                                    .setAccentColor(AppTheme.lightSuccess),
                              ),
                              _ColorButton(
                                color: AppTheme.lightInfo,
                                isSelected: settings.accentColor.toARGB32() ==
                                    AppTheme.lightInfo.toARGB32(),
                                onTap: () =>
                                    settings.setAccentColor(AppTheme.lightInfo),
                              ),
                              _ColorButton(
                                color: AppTheme.lightWarning,
                                isSelected: settings.accentColor.toARGB32() ==
                                    AppTheme.lightWarning.toARGB32(),
                                onTap: () => settings
                                    .setAccentColor(AppTheme.lightWarning),
                              ),
                              _ColorButton(
                                color: AppTheme.lightDanger,
                                isSelected: settings.accentColor.toARGB32() ==
                                    AppTheme.lightDanger.toARGB32(),
                                onTap: () => settings
                                    .setAccentColor(AppTheme.lightDanger),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: UIUtils.spacingMd),

                // About Section
                CollapsibleCard(
                  cardDecoration: UIUtils.getCardDecoration(context),
                  title: 'About',
                  subtitle: 'App information',
                  status: CollapsibleCardStatus.configured,
                  initiallyCollapsed: true,
                  collapsedSummary: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: UIUtils.spacingSm),
                      Expanded(
                        child: Text(
                          '${AppInfo.appName} v${AppInfo.version}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  expandedContent: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.work,
                        title: 'App Name',
                        subtitle: AppInfo.appName,
                      ),
                      SizedBox(height: UIUtils.spacingSm),
                      Divider(color: theme.dividerColor),
                      SizedBox(height: UIUtils.spacingSm),
                      _SettingsTile(
                        icon: Icons.numbers,
                        title: 'Version',
                        subtitle: AppInfo.version,
                      ),
                      SizedBox(height: UIUtils.spacingSm),
                      Divider(color: theme.dividerColor),
                      SizedBox(height: UIUtils.spacingSm),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        title: 'Description',
                        subtitle: AppInfo.description,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: UIUtils.spacingMd),

                // Data Section
                CollapsibleCard(
                  cardDecoration: UIUtils.getCardDecoration(context),
                  title: 'Data',
                  subtitle: 'Manage your data',
                  status: CollapsibleCardStatus.needsAttention,
                  initiallyCollapsed: true,
                  collapsedSummary: Row(
                    children: [
                      Icon(
                        Icons.storage,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: UIUtils.spacingSm),
                      Expanded(
                        child: Text(
                          'Settings and data management',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  expandedContent: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.restore,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reset Settings',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reset all settings to defaults',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _confirmReset(context, settings),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_suggest;
    }
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
      case ThemeMode.system:
        return 'System default';
    }
  }

  void _confirmReset(BuildContext context, SettingsService settings) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Reset Settings?',
      message: 'This will reset all settings to their default values.',
      confirmLabel: 'Reset',
      icon: Icons.restore,
    );

    if (confirmed && context.mounted) {
      settings.resetSettings();
      context.showSuccessSnackBar('Settings reset to defaults');
    }
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}
