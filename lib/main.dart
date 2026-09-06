import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'controllers/application_controller.dart';
import 'controllers/settings_controller.dart';
import 'repositories/excel_application_repository.dart';
import 'screens/main_layout_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop window settings on macOS/desktop
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1380, 880),
        minimumSize: Size(1100, 720),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        title: 'University Application Manager',
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (_) {
      // Window manager fallback if running in environments without native window host
    }
  }

  // Pre-initialize repository and local data before runApp to ensure
  // synchronous frame readiness and prevent lifecycle build race conditions.
  final repository = ExcelApplicationRepository();
  await repository.initialize();

  final appController = ApplicationController(repository: repository);
  final settingsController = SettingsController(repository: repository);

  await settingsController.loadSettings();
  await appController.loadData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appController),
        ChangeNotifierProvider.value(value: settingsController),
      ],
      child: const UniversityApplicationApp(),
    ),
  );
}

class UniversityApplicationApp extends StatefulWidget {
  const UniversityApplicationApp({super.key});

  @override
  State<UniversityApplicationApp> createState() => _UniversityApplicationAppState();
}

class _UniversityApplicationAppState extends State<UniversityApplicationApp> {
  @override
  void initState() {
    super.initState();
    // Safety net for hot restarts to guarantee data is refreshed from disk
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final appCtrl = Provider.of<ApplicationController>(context, listen: false);
        if (appCtrl.applications.isEmpty && !appCtrl.isLoading) {
          appCtrl.loadData();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = Provider.of<SettingsController>(context);

    return MaterialApp(
      title: 'University Application Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsCtrl.settings.themeMode,
      home: const MainLayoutScreen(),
    );
  }
}
