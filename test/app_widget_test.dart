import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:university_system/controllers/application_controller.dart';
import 'package:university_system/controllers/settings_controller.dart';
import 'package:university_system/main.dart';
import 'package:university_system/repositories/excel_application_repository.dart';
import 'package:university_system/services/excel_database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File testDbFile;
  late ExcelDatabaseService service;
  late ExcelApplicationRepository repository;
  late ApplicationController appController;
  late SettingsController settingsController;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_widget_test_');
    testDbFile = File('${tempDir.path}/test_applications.xlsx');
    service = ExcelDatabaseService.instance;
    service.setCustomPath(testDbFile.path);
    repository = ExcelApplicationRepository(service: service);
    await repository.initialize();

    appController = ApplicationController(repository: repository);
    settingsController = SettingsController(repository: repository);

    await settingsController.loadSettings();
    await appController.loadData();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('UniversityApplicationApp mounts without !_dirty assertion', (tester) async {
    tester.view.physicalSize = const Size(1380, 880);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appController),
          ChangeNotifierProvider.value(value: settingsController),
        ],
        child: const UniversityApplicationApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify main screen mounted and no exceptions thrown
    expect(find.byType(UniversityApplicationApp), findsOneWidget);
  });
}
