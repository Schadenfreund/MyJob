import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'providers/applications_provider.dart';
import 'providers/templates_provider.dart';
import 'providers/user_data_provider.dart';
import 'services/settings_service.dart';
import 'widgets/custom_titlebar.dart';
import 'screens/applications/applications_screen.dart';
import 'screens/documents/documents_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyLifeApp());
}

class MyLifeApp extends StatelessWidget {
  const MyLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => SettingsService()..loadSettings()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()..loadAll()),
        ChangeNotifierProvider(create: (_) => TemplatesProvider()..loadAll()),
        ChangeNotifierProvider(
            create: (_) => ApplicationsProvider()..loadApplications()),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'MyLife',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(settings.accentColor),
            darkTheme: AppTheme.darkTheme(settings.accentColor),
            themeMode: settings.themeMode,
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0;

  // Define tabs
  final List<TabInfo> _tabs = const [
    TabInfo(label: 'Documents', icon: Icons.description_outlined),
    TabInfo(label: 'Tracking', icon: Icons.work_outline),
    TabInfo(label: 'Settings', icon: Icons.settings_outlined),
  ];

  // Screen widgets for each tab
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DocumentsScreen(),
      const ApplicationsScreen(),
      const SettingsScreen(),
    ];
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      body: Column(
        children: [
          // Custom titlebar with integrated tabs
          CustomTitleBar(
            title: 'MyLife',
            icon: const Icon(Icons.work, size: 18, color: Colors.white),
            accentColor: settings.accentColor,
            isDarkMode: settings.themeMode == ThemeMode.dark,
            onThemeToggle: settings.toggleTheme,
            tabs: _tabs,
            currentTabIndex: _currentTabIndex,
            onTabChanged: _onTabChanged,
            actions: [
              _TitleBarAction(
                icon: Icons.search,
                tooltip: 'Search',
                isDarkMode: settings.themeMode == ThemeMode.dark,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Search functionality coming soon')),
                  );
                },
              ),
              _TitleBarAction(
                icon: Icons.refresh,
                tooltip: 'Refresh',
                isDarkMode: settings.themeMode == ThemeMode.dark,
                onPressed: () {
                  context.read<ApplicationsProvider>().loadApplications();
                  context.read<TemplatesProvider>().loadAll();
                  context.read<UserDataProvider>().loadAll();
                },
              ),
            ],
          ),
          // Main content
          Expanded(
            child: _screens[_currentTabIndex],
          ),
        ],
      ),
    );
  }
}

/// Titlebar action button
class _TitleBarAction extends StatefulWidget {
  const _TitleBarAction({
    required this.icon,
    required this.tooltip,
    required this.isDarkMode,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isDarkMode;
  final VoidCallback onPressed;

  @override
  State<_TitleBarAction> createState() => _TitleBarActionState();
}

class _TitleBarActionState extends State<_TitleBarAction> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor =
        widget.isDarkMode ? AppTheme.darkHover : AppTheme.lightHover;
    final iconColor = widget.isDarkMode
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 46,
            height: AppTheme.headerHeight,
            decoration: BoxDecoration(
              color: _isHovered ? hoverColor : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
