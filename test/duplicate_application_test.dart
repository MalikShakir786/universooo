import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_system/controllers/application_controller.dart';
import 'package:university_system/models/application_model.dart';
import 'package:university_system/models/contact_model.dart';
import 'package:university_system/models/scholarship_model.dart';
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
    tempDir = await Directory.systemTemp.createTemp('dup_test_');
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

  group('Duplicate Application Feature', () {
    test('Duplicates application with new ID, custom name, and copied checklist/contacts', () async {
      // 1. Create source application
      final source = ApplicationModel(
        id: 'app-original-1',
        universityName: 'Technical University of Munich',
        country: 'Germany',
        city: 'Munich',
        courseName: 'MSc Informatics',
        degreeLevel: "Master's",
        intake: 'Fall',
        semesterYear: '2026',
        status: 'Applied',
        priority: 'High',
        tuitionFee: 0,
        ieltsRequired: true,
        ieltsOverallRequired: 6.5,
      );
      await controller.addApplication(source);

      // Add a custom contact and scholarship
      await controller.addContact(ContactModel(
        id: 'contact-1',
        applicationId: 'app-original-1',
        department: 'Informatics Department',
        contactPerson: 'Prof. Schmidt',
        email: 'schmidt@tum.de',
      ));

      await controller.addScholarship(ScholarshipModel(
        id: 'schol-1',
        applicationId: 'app-original-1',
        scholarshipName: 'DAAD Scholarship',
        amount: 10500,
        status: 'Applied',
      ));

      expect(controller.applications.length, 1);
      expect(controller.getContactsFor('app-original-1').length, 1);
      expect(controller.getScholarshipsFor('app-original-1').length, 1);
      expect(controller.getDocumentsFor('app-original-1').isNotEmpty, true);

      // 2. Duplicate application for another course (MSc Data Engineering)
      final duplicated = await controller.duplicateApplication(
        'app-original-1',
        newCourseName: 'MSc Data Engineering and Analytics',
        newSemesterYear: '2026',
        newIntake: 'Fall',
        newStatus: 'Researching',
        copyDocuments: true,
        copyScholarships: true,
        copyContacts: true,
      );

      // 3. Verify duplicated application properties
      expect(duplicated.id, isNot(equals(source.id)));
      expect(duplicated.universityName, 'Technical University of Munich');
      expect(duplicated.country, 'Germany');
      expect(duplicated.city, 'Munich');
      expect(duplicated.courseName, 'MSc Data Engineering and Analytics');
      expect(duplicated.status, 'Researching');
      expect(duplicated.ieltsOverallRequired, 6.5);

      // Verify controller lists both applications
      expect(controller.applications.length, 2);

      // 4. Verify copied documents have the new application ID
      final duplicatedDocs = controller.getDocumentsFor(duplicated.id);
      expect(duplicatedDocs.isNotEmpty, isTrue);
      expect(duplicatedDocs.every((d) => d.applicationId == duplicated.id), isTrue);
      // All checklist items should be reset to uncompleted
      expect(duplicatedDocs.every((d) => d.completed == false), isTrue);

      // 5. Verify copied scholarships and contacts
      final duplicatedScholarships = controller.getScholarshipsFor(duplicated.id);
      expect(duplicatedScholarships.length, 1);
      expect(duplicatedScholarships.first.applicationId, duplicated.id);
      expect(duplicatedScholarships.first.scholarshipName, 'DAAD Scholarship');
      expect(duplicatedScholarships.first.status, 'Considering');

      final duplicatedContacts = controller.getContactsFor(duplicated.id);
      expect(duplicatedContacts.length, 1);
      expect(duplicatedContacts.first.applicationId, duplicated.id);
      expect(duplicatedContacts.first.contactPerson, 'Prof. Schmidt');

      // 6. Verify status history has duplication event
      final history = controller.getStatusHistoriesFor(duplicated.id);
      expect(history.length, 1);
      expect(history.first.event, contains('Duplicated from MSc Informatics'));

      // 7. Verify Excel file persistence
      final reloadedApps = await service.loadApplications();
      expect(reloadedApps.length, 2);
      expect(reloadedApps.any((a) => a.courseName == 'MSc Informatics'), isTrue);
      expect(reloadedApps.any((a) => a.courseName == 'MSc Data Engineering and Analytics'), isTrue);
    });

    test('Default duplicate appends (Copy) to course name if not specified', () async {
      final source = ApplicationModel(
        id: 'app-src',
        universityName: 'Oxford University',
        country: 'United Kingdom',
        courseName: 'MSc Computer Science',
      );
      await controller.addApplication(source);

      final duplicated = await controller.duplicateApplication(source.id);
      expect(duplicated.courseName, 'MSc Computer Science (Copy)');
      expect(duplicated.status, 'Researching');
      expect(controller.applications.length, 2);
    });
  });
}
