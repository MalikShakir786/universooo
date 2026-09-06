import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_system/controllers/application_controller.dart';
import 'package:university_system/repositories/excel_application_repository.dart';
import 'package:university_system/services/excel_database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File testDbFile;
  late ExcelDatabaseService service;
  late ExcelApplicationRepository repository;
  late ApplicationController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('country_mgr_test_');
    testDbFile = File('${tempDir.path}/test_applications.xlsx');
    service = ExcelDatabaseService.instance;
    service.setCustomPath(testDbFile.path);
    repository = ExcelApplicationRepository(service: service);
    await repository.initialize();
    controller = ApplicationController(repository: repository);
    await controller.loadData();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Dynamic Country Management', () {
    test('Initial state contains no hardcoded countries', () {
      expect(controller.userCountries, isEmpty);
      expect(controller.availableCountries, isEmpty);
      expect(controller.countryStats, isEmpty);
    });

    test('Add Country adds and persists to Excel Sheet 7', () async {
      final success = await controller.addCountry('Japan');
      expect(success, isTrue);

      expect(controller.availableCountries, contains('Japan'));
      expect(controller.userCountries.length, 1);
      expect(controller.userCountries.first.country, 'Japan');
      expect(controller.userCountries.first.flag, '🇯🇵');

      // Verify Excel file persistence
      final restoredCountries = await service.loadCountries();
      expect(restoredCountries.length, 1);
      expect(restoredCountries.first.country, 'Japan');
      expect(restoredCountries.first.flag, '🇯🇵');
    });

    test('Prevents duplicate country addition case-insensitively', () async {
      await controller.addCountry('Germany');
      final duplicate = await controller.addCountry('germany');
      expect(duplicate, isTrue);
      expect(controller.userCountries.length, 1);
      expect(controller.availableCountries.length, 1);
    });

    test('Add Country and verify persistence across controller reload', () async {
      await controller.addCountry('Canada');
      await controller.addCountry('Switzerland');

      expect(controller.availableCountries, ['Canada', 'Switzerland']);

      // Simulate app restart with fresh controller
      final newController = ApplicationController(repository: repository);
      await newController.loadData();

      expect(newController.availableCountries, ['Canada', 'Switzerland']);
      expect(newController.userCountries.length, 2);
    });

    test('Remove Country removes from list and updates persistence', () async {
      await controller.addCountry('Australia');
      await controller.addCountry('Sweden');

      expect(controller.availableCountries.length, 2);

      await controller.removeCountry('Australia');
      expect(controller.availableCountries, ['Sweden']);

      final restored = await service.loadCountries();
      expect(restored.any((c) => c.country == 'Australia'), isFalse);
      expect(restored.any((c) => c.country == 'Sweden'), isTrue);
    });
  });
}
