import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/app_theme.dart';

// Titlebar constants
const double _iconBoxSize = 30;
const double _iconPadding = 5;
const double _iconBorderRadius = 7;
const double _windowButtonWidth = 46;
const double _titleFontSize = 16;
const double _windowButtonIconSize = 16;
const double _themeToggleIconSize = 18;

/// Helper to toggle maximize/restore state
Future<void> _toggleMaximize() async {
  if (await windowManager.isMaximized()) {
    await windowManager.unmaximize();
  } else {
    await windowManager.maximize();
  }
}

/// Tab information model
class TabInfo {
  const TabInfo({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

/// Custom Windows titlebar with integrated tab navigation
class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({
    required this.title,
    required this.accentColor,
    required this.isDarkMode,
    required this.tabs,
    required this.currentTabIndex,
    required this.onTabChanged,
    super.key,
    this.icon,
    this.onThemeToggle,
    this.actions,
  });

  final String title;
  final Widget? icon;
  final Color accentColor;
  final bool isDarkMode;
  final VoidCallback? onThemeToggle;
  final List<Widget>? actions;
  final List<TabInfo> tabs;
  final int currentTabIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final hoverColor = isDarkMode ? AppTheme.darkHover : AppTheme.lightHover;
    final borderColor = isDarkMode ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      height: AppTheme.headerHeight,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: AppTheme.lightHeaderShadow,
      ),
      child: Row(
        children: [
          // Left: App Icon + Title
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (details) => windowManager.startDragging(),
            onDoubleTap: _toggleMaximize,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: _iconBoxSize,
                    height: _iconBoxSize,
                    padding: const EdgeInsets.all(_iconPadding),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(_iconBorderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: icon ??
                        const Icon(Icons.work, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: _titleFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Container(
            height: 24,
            width: 1,
            color: borderColor.withValues(alpha: 0.5),
          ),

          // Center: Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                return _TabButton(
                  label: tab.label,
                  icon: tab.icon,
                  isSelected: index == currentTabIndex,
                  accentColor: accentColor,
                  textColor: textColor,
                  onTap: () => onTabChanged(index),
                );
              }).toList(),
            ),
          ),

          // Drag area (flexible space)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) => windowManager.startDragging(),
              onDoubleTap: _toggleMaximize,
              child: const SizedBox.expand(),
            ),
          ),

          // Right: Actions + Window controls
          if (actions != null) ...actions!,

          if (onThemeToggle != null)
            _ThemeToggleButton(
              isDark: isDarkMode,
              onPressed: onThemeToggle!,
              hoverColor: hoverColor,
              iconColor: textColor,
            ),

          _WindowButton(
            icon: Icons.minimize,
            onPressed: windowManager.minimize,
            hoverColor: hoverColor,
            iconColor: textColor,
          ),
          _WindowButton(
            icon: Icons.crop_square,
            onPressed: _toggleMaximize,
            hoverColor: hoverColor,
            iconColor: textColor,
          ),
          _WindowButton(
            icon: Icons.close,
            onPressed: windowManager.close,
            hoverColor: hoverColor,
            iconColor: textColor,
            isClose: true,
          ),
        ],
      ),
    );
  }
}

/// Tab button widget
class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || _isHovered;
    final displayColor =
        isActive ? widget.accentColor : widget.textColor.withValues(alpha: 0.7);
    final backgroundColor = widget.isSelected
        ? widget.accentColor.withValues(alpha: 0.12)
        : _isHovered
            ? widget.accentColor.withValues(alpha: 0.08)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: displayColor,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: displayColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Window control button
class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.hoverColor,
    required this.iconColor,
    this.isClose = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color hoverColor;
  final Color iconColor;
  final bool isClose;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: _windowButtonWidth,
            height: AppTheme.headerHeight,
            decoration: BoxDecoration(
              color: _isHovered
                  ? (widget.isClose ? Colors.red : widget.hoverColor)
                  : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: _windowButtonIconSize,
              color: _isHovered && widget.isClose
                  ? Colors.white
                  : widget.iconColor,
            ),
          ),
        ),
      );
}

/// Theme toggle button with rotation animation
class _ThemeToggleButton extends StatefulWidget {
  const _ThemeToggleButton({
    required this.isDark,
    required this.onPressed,
    required this.hoverColor,
    required this.iconColor,
  });

  final bool isDark;
  final VoidCallback onPressed;
  final Color hoverColor;
  final Color iconColor;

  @override
  State<_ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<_ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_ThemeToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      _rotationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 46,
            height: AppTheme.headerHeight,
            decoration: BoxDecoration(
              color: _isHovered ? widget.hoverColor : Colors.transparent,
            ),
            child: RotationTransition(
              turns: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _rotationController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: Icon(
                widget.isDark ? Icons.dark_mode_outlined : Icons.light_mode,
                size: _themeToggleIconSize,
                color: widget.iconColor,
              ),
            ),
          ),
        ),
      );
}
