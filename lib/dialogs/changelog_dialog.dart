import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Dialog to display the full changelog for an update
class ChangelogDialog extends StatelessWidget {
  final String changelog;
  final String version;

  const ChangelogDialog({
    super.key,
    required this.changelog,
    required this.version,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsService>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: settings.accentColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.cardBorderRadius),
                  topRight: Radius.circular(AppDimensions.cardBorderRadius),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: settings.accentColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('release_notes'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Version $version',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Changelog content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _ChangelogContent(changelog: changelog),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: settings.accentColor,
                    ),
                    child: Text(context.tr('close')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parses and renders changelog content with basic markdown support
class _ChangelogContent extends StatelessWidget {
  final String changelog;

  const _ChangelogContent({required this.changelog});

  // Parses **bold** and `code` inline markers into TextSpans.
  static List<TextSpan> _parseInline(
      String text, TextStyle base, TextStyle bold, TextStyle code) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');
    int last = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start), style: base));
      }
      if (match.group(1) != null) {
        spans.add(TextSpan(text: match.group(1), style: bold));
      } else {
        spans.add(TextSpan(text: match.group(2), style: code));
      }
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsService>();

    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final baseStyle = theme.textTheme.bodyMedium ?? const TextStyle();
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w600);
    final codeStyle = baseStyle.copyWith(
      fontFamily: 'monospace',
      color: settings.accentColor,
    );

    // Parse the changelog into sections
    final lines = changelog.split('\n');
    final widgets = <Widget>[];

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      // Horizontal rule
      if (line == '---') {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Divider(),
        ));
      }
      // ## Section headers (## Fixed, ## Added, etc.)
      else if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: widgets.isEmpty ? 0 : AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              line.substring(3),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: settings.accentColor,
              ),
            ),
          ),
        );
      }
      // ### Sub-section headers
      else if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: widgets.isEmpty ? 0 : AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              line.substring(4),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
      // #### Sub-sub-section headers
      else if (line.startsWith('#### ')) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: widgets.isEmpty ? 0 : AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              line.substring(5),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: secondaryColor,
              ),
            ),
          ),
        );
      }
      // Bullet points
      else if (line.startsWith('- ') || line.startsWith('* ')) {
        final spans = _parseInline(line.substring(2), baseStyle, boldStyle, codeStyle);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: settings.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(children: spans),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Regular text
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              line,
              style: baseStyle.copyWith(color: secondaryColor),
            ),
          ),
        );
      }
    }

    if (widgets.isEmpty) {
      return Text(
        context.tr('no_release_notes'),
        style: baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: secondaryColor,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
