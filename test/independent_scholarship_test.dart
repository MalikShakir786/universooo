import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_system/controllers/application_controller.dart';
import 'package:university_system/models/application_model.dart';
import 'package:university_system/models/scholarship_model.dart';
import 'package:university_system/repositories/excel_application_repository.dart';
import 'package:university_system/services/excel_database_service.dart';

void main() {
  late Directory testDir;
  late File testDbFile;
  late ExcelDatabaseService service;
  late ExcelApplicationRepository repository;

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('indep_scholarship_test_');
    testDbFile = File('${testDir.path}/test_database.xlsx');
    service = ExcelDatabaseService.instance;
    service.setCustomPath(testDbFile.path);
    repository = ExcelApplicationRepository(service: service);
    await repository.initialize();
  });

  tearDown(() async {
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('Independent Scholarships Functionality', () {
    test('ScholarshipModel identifies independent vs linked scholarships', () {
      const independent = ScholarshipModel(
        id: 's-indep',
        scholarshipName: 'Fulbright Fellowship',
        organization: 'USEFP',
        amount: 25000.0,
      );
      expect(independent.isIndependent, isTrue);
      expect(independent.applicationId, isEmpty);
      expect(independent.organization, 'USEFP');

      const linked = ScholarshipModel(
        id: 's-linked',
        applicationId: 'app-123',
        scholarshipName: 'TUM Merit Grant',
        organization: 'TUM',
        amount: 5000.0,
      );
      expect(linked.isIndependent, isFalse);
      expect(linked.applicationId, 'app-123');
    });

    test('ApplicationController manages independent scholarships independently from applications', () async {
      final controller = ApplicationController(repository: repository);
      await controller.loadData();

      // Create an application
      const app = ApplicationModel(
        id: 'app-001',
        universityName: 'Technical University of Munich',
        country: 'Germany',
        courseName: 'M.Sc. Informatics',
      );
      await controller.addApplication(app);

      // Add a linked scholarship
      const linkedSchol = ScholarshipModel(
        id: 'schol-linked-1',
        applicationId: 'app-001',
        scholarshipName: 'DAAD TUM Support',
        amount: 4000.0,
      );
      await controller.addScholarship(linkedSchol);

      // Add an independent scholarship
      const indepSchol = ScholarshipModel(
        id: 'schol-indep-1',
        applicationId: '',
        scholarshipName: 'Rotary Peace Fellowship',
        organization: 'Rotary Foundation',
        amount: 15000.0,
        deadline: '2026-11-15',
        status: 'Preparing',
      );
      await controller.addScholarship(indepSchol);

      expect(controller.scholarships.length, 2);
      expect(controller.independentScholarships.length, 1);
      expect(controller.independentScholarships.first.scholarshipName, 'Rotary Peace Fellowship');
      expect(controller.independentScholarships.first.organization, 'Rotary Foundation');
      expect(controller.linkedScholarships.length, 1);
      expect(controller.linkedScholarships.first.scholarshipName, 'DAAD TUM Support');

      // Update independent scholarship
      final updated = indepSchol.copyWith(status: 'Awarded', amount: 16000.0);
      await controller.updateScholarship(updated);
      expect(controller.independentScholarships.first.status, 'Awarded');
      expect(controller.independentScholarships.first.amount, 16000.0);

      // Deleting the application must delete the linked scholarship but PRESERVE the independent scholarship
      await controller.deleteApplication('app-001');

      expect(controller.applications.isEmpty, isTrue);
      expect(controller.scholarships.length, 1);
      expect(controller.scholarships.first.id, 'schol-indep-1');
      expect(controller.independentScholarships.length, 1);
      expect(controller.linkedScholarships.isEmpty, isTrue);

      // Delete independent scholarship
      await controller.deleteScholarship('schol-indep-1');
      expect(controller.scholarships.isEmpty, isTrue);
      expect(controller.independentScholarships.isEmpty, isTrue);
    });

    test('Persists independent scholarships to Excel and reloads accurately', () async {
      const indep = ScholarshipModel(
        id: 'schol-excel-1',
        applicationId: '',
        scholarshipName: 'Erasmus Mundus Joint Masters Scholarship',
        organization: 'European Commission',
        amount: 35000.0,
        deadline: '2026-01-15',
        eligibility: 'Bachelor degree in relevant field',
        status: 'Applied',
        notes: 'Includes full insurance, tuition, and living allowance.',
      );

      const linked = ScholarshipModel(
        id: 'schol-excel-2',
        applicationId: 'app-002',
        scholarshipName: 'Oxford Clarendon Fund',
        organization: 'University of Oxford',
        amount: 20000.0,
        deadline: '2026-02-01',
        status: 'Under Review',
      );

      await repository.saveScholarships([indep, linked]);

      // Reload all scholarships (without filtering by application)
      final reloaded = await repository.loadScholarships();
      expect(reloaded.length, 2);

      final loadedIndep = reloaded.firstWhere((s) => s.id == 'schol-excel-1');
      expect(loadedIndep.isIndependent, isTrue);
      expect(loadedIndep.applicationId, isEmpty);
      expect(loadedIndep.scholarshipName, 'Erasmus Mundus Joint Masters Scholarship');
      expect(loadedIndep.organization, 'European Commission');
      expect(loadedIndep.amount, 35000.0);
      expect(loadedIndep.deadline, '2026-01-15');
      expect(loadedIndep.eligibility, 'Bachelor degree in relevant field');
      expect(loadedIndep.status, 'Applied');
      expect(loadedIndep.notes, 'Includes full insurance, tuition, and living allowance.');

      // Reload filtered by app-002
      final loadedLinkedOnly = await repository.loadScholarships('app-002');
      expect(loadedLinkedOnly.length, 1);
      expect(loadedLinkedOnly.first.scholarshipName, 'Oxford Clarendon Fund');
    });
  });
}
