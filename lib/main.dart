import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'providers/applications_provider.dart';
import 'providers/templates_provider.dart';
import 'providers/user_data_provider.dart';
import 'providers/pdf_presets_provider.dart';
import 'providers/notes_provider.dart';
import 'services/settings_service.dart';
import 'services/log_service.dart';
import 'services/migration_service.dart';
import 'widgets/custom_titlebar.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/applications/applications_screen.dart';
import 'screens/notes/notes_screen.dart';
import 'screens/settings/settings_screen.dart';
// Added based on context of TabInfo usage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging service first
  await LogService.instance.init();
  await LogService.instance.cleanOldLogs(keepDays: 7);
  logInfo('Application starting', tag: 'App');

  // Run migration if needed (convert old user_data.json to new structure)
  final migrated = await MigrationService.instance.migrateIfNeeded();
  if (migrated) {
    logInfo('User data migrated to bilingual structure', tag: 'Migration');
  }

  // Initialize window manager
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    maximumSize: Size(2560, 1440), // Allow large screens
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setResizable(true); // Ensure window is resizable
  });

  runApp(const MyJobApp());
}

class MyJobApp extends StatelessWidget {
  const MyJobApp({super.key});

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
        ChangeNotifierProvider(
            create: (_) => PdfPresetsProvider()..loadPresets()),
        ChangeNotifierProvider(create: (_) => NotesProvider()..loadNotes()),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'MyJob',
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

  // Define tabs (3-tab structure: Profile, Job Applications, Settings)
  final List<TabInfo> _tabs = const [
    TabInfo(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
    TabInfo(
      label: 'Job Applications',
      icon: Icons.work_outline,
      activeIcon: Icons.work,
    ),
    TabInfo(
      label: 'Notes',
      icon: Icons.sticky_note_2_outlined,
      activeIcon: Icons.sticky_note_2,
    ),
    TabInfo(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
    ),
  ];

  // Screen widgets for each tab
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const ProfileScreen(),
      const ApplicationsScreen(),
      const NotesScreen(),
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
            title: 'MyJob',
            iconAssetPath: 'assets/Icon.png',
            accentColor: settings.accentColor,
            isDarkMode: settings.themeMode == ThemeMode.dark,
            onThemeToggle: settings.toggleTheme,
            tabs: _tabs,
            currentTabIndex: _currentTabIndex,
            onTabChanged: _onTabChanged,
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
