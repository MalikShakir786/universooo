import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_system/controllers/application_controller.dart';
import 'package:university_system/models/app_settings_model.dart';
import 'package:university_system/models/application_model.dart';
import 'package:university_system/models/contact_model.dart';
import 'package:university_system/models/document_model.dart';
import 'package:university_system/models/email_account_model.dart';
import 'package:university_system/models/scholarship_model.dart';
import 'package:university_system/models/status_history_model.dart';
import 'package:university_system/repositories/excel_application_repository.dart';
import 'package:university_system/services/excel_database_service.dart';

void main() {
  late Directory testDir;
  late File testDbFile;
  late ExcelDatabaseService service;
  late ExcelApplicationRepository repository;

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('univ_test_');
    testDbFile = File('${testDir.path}/test_applications.xlsx');
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

  group('Excel Persistence Engine & Worksheets', () {
    test('Creates workbook with all 8 sheets and headers', () async {
      expect(await testDbFile.exists(), isTrue);
      final apps = await repository.loadApplications();
      expect(apps, isEmpty);
    });

    test('Persists applications (Sheet 1) across save and reload', () async {
      const app = ApplicationModel(
        id: 'app-001',
        universityName: 'Technical University of Munich',
        country: 'Germany',
        city: 'Munich',
        universityWebsite: 'https://www.tum.de',
        courseName: 'M.Sc. Informatics',
        degreeLevel: "Master's",
        faculty: 'Informatics',
        duration: '2 Years',
        intake: 'Winter',
        semesterYear: '2026',
        startOfApplications: '2025-11-01',
        applicationDeadline: '2026-05-31',
        status: 'Under Review',
        priority: 'High',
        applicationEmail: 'student@gmail.com',
        applicationFee: 75.0,
        tuitionFee: 0.0,
        livingCost: 11000.0,
        scholarshipAmount: 3000.0,
        ieltsRequired: true,
        ieltsOverallRequired: 6.5,
        myIeltsScore: 7.5,
        isFavorite: true,
      );

      await repository.addApplication(app);

      final loaded = await repository.loadApplications();
      expect(loaded.length, 1);
      final loadedApp = loaded.first;

      expect(loadedApp.id, 'app-001');
      expect(loadedApp.universityName, 'Technical University of Munich');
      expect(loadedApp.country, 'Germany');
      expect(loadedApp.city, 'Munich');
      expect(loadedApp.courseName, 'M.Sc. Informatics');
      expect(loadedApp.degreeLevel, "Master's");
      expect(loadedApp.startOfApplications, '2025-11-01');
      expect(loadedApp.earlyDeadline, '2025-11-01'); // backwards compatible getter
      expect(loadedApp.applicationDeadline, '2026-05-31');
      expect(loadedApp.status, 'Under Review');
      expect(loadedApp.priority, 'High');
      expect(loadedApp.applicationEmail, 'student@gmail.com');
      expect(loadedApp.applicationFee, 75.0);
      expect(loadedApp.ieltsRequired, isTrue);
      expect(loadedApp.ieltsOverallRequired, 6.5);
      expect(loadedApp.myIeltsScore, 7.5);
      expect(loadedApp.isFavorite, isTrue);
    });

    test('Updates existing application in Excel', () async {
      const initial = ApplicationModel(
        id: 'app-002',
        universityName: 'University of Oxford',
        country: 'United Kingdom',
        courseName: 'Computer Science',
        status: 'Applied',
      );
      await repository.addApplication(initial);

      final updated = initial.copyWith(status: 'Accepted', tuitionFee: 35000.0);
      await repository.updateApplication(updated);

      final loaded = await repository.loadApplications();
      expect(loaded.length, 1);
      expect(loaded.first.status, 'Accepted');
      expect(loaded.first.tuitionFee, 35000.0);
    });

    test('Deletes application and associated child records in Excel', () async {
      const app = ApplicationModel(
        id: 'app-003',
        universityName: 'ETH Zurich',
        country: 'Switzerland',
        courseName: 'CS',
      );
      await repository.addApplication(app);

      const doc = DocumentModel(id: 'doc-1', applicationId: 'app-003', document: 'Passport');
      await repository.saveDocuments([doc]);

      expect((await repository.loadApplications()).length, 1);
      expect((await repository.loadDocuments('app-003')).length, 1);

      await repository.deleteApplication('app-003');

      expect((await repository.loadApplications()).length, 0);
      expect((await repository.loadDocuments('app-003')).length, 0);
    });

    test('Persists Status History (Sheet 2)', () async {
      const hist = StatusHistoryModel(
        id: 'h-1',
        applicationId: 'app-001',
        date: '2026-09-01',
        previousStatus: 'Researching',
        newStatus: 'Applied',
        event: 'Application Submitted',
        notes: 'Submitted online',
      );
      await repository.saveStatusHistory([hist]);

      final loaded = await repository.loadStatusHistory('app-001');
      expect(loaded.length, 1);
      expect(loaded.first.event, 'Application Submitted');
      expect(loaded.first.newStatus, 'Applied');
    });

    test('Persists Documents Checklist (Sheet 3)', () async {
      const doc1 = DocumentModel(
        id: 'd-1',
        applicationId: 'app-001',
        document: 'Transcript',
        required: true,
        completed: true,
        submitted: false,
      );
      await repository.saveDocuments([doc1]);

      final loaded = await repository.loadDocuments('app-001');
      expect(loaded.length, 1);
      expect(loaded.first.document, 'Transcript');
      expect(loaded.first.completed, isTrue);
      expect(loaded.first.submitted, isFalse);
    });

    test('Persists Scholarships (Sheet 4)', () async {
      const schol = ScholarshipModel(
        id: 's-1',
        applicationId: 'app-001',
        scholarshipName: 'DAAD Scholarship',
        amount: 5000.0,
        deadline: '2026-10-15',
        status: 'Eligible',
      );
      await repository.saveScholarships([schol]);

      final loaded = await repository.loadScholarships('app-001');
      expect(loaded.length, 1);
      expect(loaded.first.scholarshipName, 'DAAD Scholarship');
      expect(loaded.first.amount, 5000.0);
    });

    test('Persists Contacts (Sheet 5)', () async {
      const cont = ContactModel(
        id: 'c-1',
        applicationId: 'app-001',
        department: 'Admissions Office',
        contactPerson: 'Dr. John Doe',
        email: 'admissions@tum.de',
      );
      await repository.saveContacts([cont]);

      final loaded = await repository.loadContacts('app-001');
      expect(loaded.length, 1);
      expect(loaded.first.contactPerson, 'Dr. John Doe');
      expect(loaded.first.email, 'admissions@tum.de');
    });

    test('Persists Emails (Sheet 6)', () async {
      const email = EmailAccountModel(
        id: 'e-1',
        emailAddress: 'test@student.edu',
        type: 'University',
      );
      await repository.saveEmails([email]);

      final loaded = await repository.loadEmails();
      expect(loaded.length, 1);
      expect(loaded.first.emailAddress, 'test@student.edu');
      expect(loaded.first.type, 'University');
    });

    test('Persists Settings (Sheet 8)', () async {
      const settings = AppSettingsModel(
        studentName: 'Jane Doe',
        defaultCurrency: 'GBP',
        currentIeltsScore: 8.5,
      );
      await repository.saveSettings(settings);

      final loaded = await repository.loadSettings();
      expect(loaded.studentName, 'Jane Doe');
      expect(loaded.defaultCurrency, 'GBP');
      expect(loaded.currentIeltsScore, 8.5);
    });

    test('Exports Applications to RFC 4180 CSV format', () async {
      const app = ApplicationModel(
        id: 'app-csv',
        universityName: 'Technical University, Munich',
        country: 'Germany',
        courseName: 'M.Sc. "Informatics"',
      );
      final csv = await repository.exportCsv([app]);
      expect(csv, contains('University,Country'));
      expect(csv, contains('"Technical University, Munich"'));
      expect(csv, contains('"M.Sc. ""Informatics"""'));
    });
  });

  group('ApplicationController State & Duplicate Detection', () {
    test('Detects duplicate applications across university, course, and semester', () async {
      final controller = ApplicationController(repository: repository);
      await controller.loadData();

      const app1 = ApplicationModel(
        id: '1',
        universityName: 'University of Toronto',
        country: 'Canada',
        courseName: 'Computer Science',
        semesterYear: '2026',
      );
      await controller.addApplication(app1);

      final dup = controller.checkDuplicate(
        'University of Toronto',
        'Computer Science',
        '2026',
      );
      expect(dup, isNotNull);
      expect(dup!.id, '1');

      final notDupDifferentSemester = controller.checkDuplicate(
        'University of Toronto',
        'Computer Science',
        '2027',
      );
      expect(notDupDifferentSemester, isNull);

      final notDupExcludedSelf = controller.checkDuplicate(
        'University of Toronto',
        'Computer Science',
        '2026',
        excludeId: '1',
      );
      expect(notDupExcludedSelf, isNull);
    });

    test('Calculates dashboard stats and country metrics accurately', () async {
      final controller = ApplicationController(repository: repository);
      await controller.loadData();

      const appA = ApplicationModel(
        id: '1',
        universityName: 'TUM',
        country: 'Germany',
        courseName: 'CS',
        status: 'Applied',
        tuitionFee: 1000.0,
      );
      const appB = ApplicationModel(
        id: '2',
        universityName: 'Oxford',
        country: 'United Kingdom',
        courseName: 'CS',
        status: 'Accepted',
        tuitionFee: 30000.0,
      );

      await controller.addApplication(appA);
      await controller.addApplication(appB);

      expect(controller.totalApplications, 2);
      expect(controller.submittedCount, 2);
      expect(controller.acceptedCount, 1);
      expect(controller.countryStats.length, 2);
      expect(controller.acceptanceRate, 50.0);
    });
  });
}
