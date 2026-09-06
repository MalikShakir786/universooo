import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_system/controllers/application_controller.dart';
import 'package:university_system/models/application_model.dart';
import 'package:university_system/repositories/excel_application_repository.dart';
import 'package:university_system/services/excel_database_service.dart';

void main() {
  group('Excel Hot Restart & Persistence Shield Tests', () {
    late Directory tempDir;
    late File testDbFile;
    late File backupDbFile;
    late File tempDbFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('excel_hot_restart_');
      testDbFile = File('${tempDir.path}/university_applications.xlsx');
      backupDbFile = File('${tempDir.path}/university_applications_backup.xlsx');
      tempDbFile = File('${tempDir.path}/university_applications.xlsx.tmp');
    });

    tearDown(() async {
      ExcelDatabaseService.instance.setCustomPath('');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Data survives repeated simulated hot restarts and app cycles', () async {
      final service = ExcelDatabaseService.instance;
      service.setCustomPath(testDbFile.path);

      // Cycle 1: Add application
      final repo1 = ExcelApplicationRepository(service: service);
      final ctrl1 = ApplicationController(repository: repo1);
      await ctrl1.loadData();
      expect(ctrl1.applications, isEmpty);

      const app1 = ApplicationModel(
        id: 'oxford-101',
        universityName: 'University of Oxford',
        country: 'United Kingdom',
        city: 'Oxford',
        courseName: 'M.Sc. Computer Science',
        degreeLevel: "Master's",
        status: 'Submitted',
        priority: 'High',
        tuitionFee: 35000.0,
      );
      await ctrl1.addApplication(app1);
      expect(ctrl1.applications.length, 1);
      expect(await testDbFile.exists(), isTrue);

      // Cycle 2: Simulated Hot Restart 1 (New isolate, new controller, re-run loadData)
      final ctrl2 = ApplicationController(repository: repo1);
      await ctrl2.loadData();
      expect(ctrl2.applications.length, 1);
      expect(ctrl2.applications.first.universityName, 'University of Oxford');

      // Add second application
      const app2 = ApplicationModel(
        id: 'cambridge-102',
        universityName: 'University of Cambridge',
        country: 'United Kingdom',
        city: 'Cambridge',
        courseName: 'M.Phil Advanced Computer Science',
        degreeLevel: "Master's",
        status: 'Under Review',
        priority: 'Top Choice',
        tuitionFee: 37000.0,
      );
      await ctrl2.addApplication(app2);
      expect(ctrl2.applications.length, 2);

      // Cycle 3: Simulated Hot Restart 2
      final ctrl3 = ApplicationController(repository: repo1);
      await ctrl3.loadData();
      expect(ctrl3.applications.length, 2);
      final names = ctrl3.applications.map((a) => a.universityName).toList();
      expect(names, containsAll(['University of Oxford', 'University of Cambridge']));

      // Cycle 4: Duplicate application and verify persistence across hot restart
      final duplicated = await ctrl3.duplicateApplication(
        app1.id,
        newCourseName: 'M.Sc. Software Engineering',
        newIntake: 'Spring',
        newStatus: 'Drafting',
      );
      expect(duplicated, isNotNull);
      expect(ctrl3.applications.length, 3);

      // Cycle 5: Simulated Hot Restart 3
      final ctrl4 = ApplicationController(repository: repo1);
      await ctrl4.loadData();
      expect(ctrl4.applications.length, 3);
      final courseNames = ctrl4.applications.map((a) => a.courseName).toList();
      expect(courseNames, contains('M.Sc. Software Engineering'));
    });

    test('Auto-recovery restores data from backup if main file is corrupted', () async {
      final service = ExcelDatabaseService.instance;
      service.setCustomPath(testDbFile.path);

      final repo = ExcelApplicationRepository(service: service);
      final ctrl = ApplicationController(repository: repo);
      await ctrl.loadData();

      // Add application
      const app = ApplicationModel(
        id: 'eth-201',
        universityName: 'ETH Zurich',
        country: 'Switzerland',
        city: 'Zurich',
        courseName: 'Master in Data Science',
        status: 'Accepted',
      );
      await ctrl.addApplication(app);
      expect(await testDbFile.exists(), isTrue);

      // Trigger a save so backup file exists
      await repo.saveApplications([app]);
      expect(await backupDbFile.exists(), isTrue, reason: 'Backup file must exist');

      // Now intentionally corrupt the main file (simulate crash or partial write)
      await testDbFile.writeAsString('CORRUPTED_NON_ZIP_BYTES_DURING_CRASH', flush: true);

      // Reload data: Should automatically detect corruption and restore from backup!
      final ctrlRecovered = ApplicationController(repository: repo);
      await ctrlRecovered.loadData();

      expect(ctrlRecovered.errorMessage, isNull);
      expect(ctrlRecovered.applications.length, 1, reason: 'Should have restored from backup');
      expect(ctrlRecovered.applications.first.universityName, 'ETH Zurich');
    });

    test('Auto-recovery restores from .tmp file if rename was interrupted', () async {
      final service = ExcelDatabaseService.instance;
      service.setCustomPath(testDbFile.path);

      final repo = ExcelApplicationRepository(service: service);
      final ctrl = ApplicationController(repository: repo);
      await ctrl.loadData();

      const app = ApplicationModel(
        id: 'tum-301',
        universityName: 'TU Munich',
        country: 'Germany',
        city: 'Munich',
        courseName: 'M.Sc. Informatics',
        status: 'Applied',
      );
      await ctrl.addApplication(app);

      // Copy valid file to .tmp and delete main file (simulating kill right before rename)
      await testDbFile.copy(tempDbFile.path);
      await testDbFile.delete();
      expect(await testDbFile.exists(), isFalse);
      expect(await tempDbFile.exists(), isTrue);

      // Reload data: Should restore from .tmp
      final ctrlRecovered = ApplicationController(repository: repo);
      await ctrlRecovered.loadData();

      expect(ctrlRecovered.applications.length, 1);
      expect(ctrlRecovered.applications.first.universityName, 'TU Munich');
      expect(await testDbFile.exists(), isTrue, reason: 'Main file should be restored from temp');
    });
  });
}
