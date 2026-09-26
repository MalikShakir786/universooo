import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_system/controllers/application_controller.dart';
import 'package:university_system/models/portal_link_model.dart';
import 'package:university_system/repositories/excel_application_repository.dart';
import 'package:university_system/services/excel_database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String dbPath;
  late ExcelDatabaseService dbService;
  late ExcelApplicationRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('portal_links_test_');
    dbPath = '${tempDir.path}/test_db.xlsx';
    dbService = ExcelDatabaseService.instance;
    dbService.setCustomPath(dbPath);
    await dbService.initialize();
    repository = ExcelApplicationRepository(service: dbService);
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('PortalLinkModel Tests', () {
    test('Model serialization and deserialization', () {
      final link = PortalLinkModel(
        id: 'portal-1',
        title: 'Uni-Assist',
        url: 'https://my.uni-assist.de',
        description: 'German university application service',
        category: 'Application Portal',
        country: 'Germany',
        isPinned: true,
        createdAt: '2026-09-26T12:00:00Z',
        updatedAt: '2026-09-26T12:30:00Z',
      );

      final map = link.toMap();
      expect(map['id'], 'portal-1');
      expect(map['title'], 'Uni-Assist');
      expect(map['url'], 'https://my.uni-assist.de');
      expect(map['isPinned'], 'true');

      final deserialized = PortalLinkModel.fromMap(map);
      expect(deserialized.id, link.id);
      expect(deserialized.title, link.title);
      expect(deserialized.url, link.url);
      expect(deserialized.description, link.description);
      expect(deserialized.category, link.category);
      expect(deserialized.country, link.country);
      expect(deserialized.isPinned, isTrue);
    });

    test('copyWith works correctly', () {
      const link = PortalLinkModel(
        id: 'portal-1',
        title: 'Uni-Assist',
        url: 'https://my.uni-assist.de',
      );

      final updated = link.copyWith(
        title: 'Uni-Assist Portal Updated',
        isPinned: true,
        description: 'Updated description',
      );

      expect(updated.id, 'portal-1');
      expect(updated.title, 'Uni-Assist Portal Updated');
      expect(updated.isPinned, isTrue);
      expect(updated.description, 'Updated description');
      expect(updated.url, 'https://my.uni-assist.de');
    });
  });

  group('ExcelDatabaseService Portal CRUD Tests', () {
    test('Can save and reload portal links from Excel database', () async {
      final link1 = PortalLinkModel(
        id: 'p1',
        title: 'UCAS Portal',
        url: 'https://www.ucas.com',
        description: 'UK admissions portal',
        category: 'Application Portal',
        country: 'United Kingdom',
        isPinned: true,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final link2 = PortalLinkModel(
        id: 'p2',
        title: 'DAAD Scholarships',
        url: 'https://www.daad.de',
        description: 'German scholarship database',
        category: 'Scholarship Portal',
        country: 'Germany',
        isPinned: false,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await dbService.saveAllPortalLinks([link1, link2]);

      final loaded = await dbService.loadPortalLinks();
      expect(loaded.length, 2);
      expect(loaded.any((l) => l.id == 'p1' && l.title == 'UCAS Portal' && l.isPinned), isTrue);
      expect(loaded.any((l) => l.id == 'p2' && l.title == 'DAAD Scholarships' && !l.isPinned), isTrue);
    });
  });

  group('ApplicationController Portal Links Tests', () {
    test('Seeds default portals on first launch if empty and allows CRUD and pin toggling', () async {
      final controller = ApplicationController(repository: repository);
      await controller.loadData();

      // Controller should have seeded default portals
      expect(controller.portalLinks.isNotEmpty, isTrue);
      final initialCount = controller.portalLinks.length;

      // Add a custom link
      final customLink = PortalLinkModel(
        id: 'custom-link-99',
        title: 'My Custom Portal',
        url: 'https://myportal.example.edu',
        description: 'Direct portal notes',
        category: 'University Official',
        country: 'Canada',
        isPinned: false,
      );

      await controller.addPortalLink(customLink);
      expect(controller.portalLinks.length, initialCount + 1);
      expect(controller.portalLinks.any((l) => l.id == 'custom-link-99'), isTrue);

      // Toggle pin
      await controller.togglePinPortalLink('custom-link-99');
      final pinnedItem = controller.portalLinks.firstWhere((l) => l.id == 'custom-link-99');
      expect(pinnedItem.isPinned, isTrue);

      // Update link
      final updatedLink = pinnedItem.copyWith(title: 'Updated Custom Portal');
      await controller.updatePortalLink(updatedLink);
      final reloadedUpdated = controller.portalLinks.firstWhere((l) => l.id == 'custom-link-99');
      expect(reloadedUpdated.title, 'Updated Custom Portal');

      // Delete link
      await controller.deletePortalLink('custom-link-99');
      expect(controller.portalLinks.any((l) => l.id == 'custom-link-99'), isFalse);
      expect(controller.portalLinks.length, initialCount);
    });
  });
}
