import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_system/controllers/application_controller.dart';
import 'package:university_system/models/application_model.dart';
import 'package:university_system/repositories/excel_application_repository.dart';
import 'package:university_system/services/excel_database_service.dart';

void main() {
  group('Requirement 50: Explicit ADD -> SAVE -> CLOSE -> REOPEN -> VERIFY Lifecycle', () {
    late Directory tempDir;
    late File excelFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('persistence_verify_');
      excelFile = File('${tempDir.path}/university_applications.xlsx');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('ADD -> SAVE -> CLOSE APP -> REOPEN APP -> VERIFY DATA', () async {
      // --- PHASE 1: First Application Launch ---
      final service1 = ExcelDatabaseService.instance;
      service1.setCustomPath(excelFile.path);
      final repo1 = ExcelApplicationRepository(service: service1);
      final controller1 = ApplicationController(repository: repo1);

      await controller1.loadData();
      expect(controller1.applications, isEmpty);

      // ADD Application
      const newApp = ApplicationModel(
        id: 'imperial-001',
        universityName: 'Imperial College London',
        country: 'United Kingdom',
        city: 'London',
        courseName: 'M.Sc. Advanced Computing',
        degreeLevel: "Master's",
        intake: 'Fall',
        semesterYear: '2026',
        applicationDeadline: '2026-06-30',
        status: 'Preparing',
        priority: 'High',
        applicationEmail: 'imperial.applicant@domain.com',
        applicationFee: 90.0,
        tuitionFee: 41000.0,
        livingCost: 16000.0,
        ieltsRequired: true,
        ieltsOverallRequired: 7.0,
        myIeltsScore: 7.5,
        isFavorite: true,
        personalReview: 'Top university in engineering and AI in London.',
      );

      await controller1.addApplication(newApp);

      // Verify added in memory and file written
      expect(controller1.applications.length, 1);
      expect(await excelFile.exists(), isTrue);

      // --- PHASE 2: SIMULATE CLOSING THE APP COMPLETELY ---
      // (Discard all references and controller state)

      // --- PHASE 3: SIMULATE REOPENING THE APP FROM DISK ---
      final service2 = ExcelDatabaseService.instance;
      service2.setCustomPath(excelFile.path);
      final repo2 = ExcelApplicationRepository(service: service2);
      final controller2 = ApplicationController(repository: repo2);

      await controller2.loadData();

      // --- PHASE 4: VERIFY DATA RESTORED 100% FROM EXCEL ---
      expect(controller2.applications.length, 1, reason: 'Application must survive app close and restart');
      final restored = controller2.applications.first;

      expect(restored.id, 'imperial-001');
      expect(restored.universityName, 'Imperial College London');
      expect(restored.country, 'United Kingdom');
      expect(restored.city, 'London');
      expect(restored.courseName, 'M.Sc. Advanced Computing');
      expect(restored.status, 'Preparing');
      expect(restored.priority, 'High');
      expect(restored.applicationEmail, 'imperial.applicant@domain.com');
      expect(restored.applicationFee, 90.0);
      expect(restored.tuitionFee, 41000.0);
      expect(restored.ieltsOverallRequired, 7.0);
      expect(restored.myIeltsScore, 7.5);
      expect(restored.isFavorite, isTrue);
      expect(restored.personalReview, 'Top university in engineering and AI in London.');

      // Verify auto-created documents and history also survived restart
      final docs = controller2.getDocumentsFor('imperial-001');
      expect(docs, isNotEmpty, reason: 'Documents checklist must survive app restart');

      final history = controller2.getStatusHistoriesFor('imperial-001');
      expect(history, isNotEmpty, reason: 'Status history timeline must survive app restart');

      // --- PHASE 5: EDIT -> RESTART -> VERIFY ---
      final updated = restored.copyWith(
        status: 'Unconditional Offer',
        tuitionFee: 39000.0,
      );
      await controller2.updateApplication(updated);

      // Reopen again from disk
      final controller3 = ApplicationController(repository: repo2);
      await controller3.loadData();

      expect(controller3.applications.first.status, 'Unconditional Offer');
      expect(controller3.applications.first.tuitionFee, 39000.0);

      // --- PHASE 6: DELETE -> RESTART -> VERIFY ---
      await controller3.deleteApplication('imperial-001');
      expect(controller3.applications, isEmpty);

      // Reopen again from disk
      final controller4 = ApplicationController(repository: repo2);
      await controller4.loadData();
      expect(controller4.applications, isEmpty, reason: 'Deletion must persist across restarts');
    });
  });
}
