import 'dart:io';
import '../models/application_model.dart';
import '../models/status_history_model.dart';
import '../models/document_model.dart';
import '../models/scholarship_model.dart';
import '../models/contact_model.dart';
import '../models/email_account_model.dart';
import '../models/country_stat_model.dart';
import '../models/app_settings_model.dart';
import '../models/portal_link_model.dart';
import '../services/excel_database_service.dart';
import 'application_repository.dart';

class ExcelApplicationRepository implements ApplicationRepository {
  final ExcelDatabaseService _service;

  ExcelApplicationRepository({ExcelDatabaseService? service})
      : _service = service ?? ExcelDatabaseService.instance;

  @override
  Future<void> initialize() => _service.initialize();

  @override
  Future<List<ApplicationModel>> loadApplications() => _service.loadApplications();

  @override
  Future<void> saveApplications(List<ApplicationModel> applications) =>
      _service.saveAllApplications(applications);

  @override
  Future<List<PortalLinkModel>> loadPortalLinks() => _service.loadPortalLinks();

  @override
  Future<void> savePortalLinks(List<PortalLinkModel> links) =>
      _service.saveAllPortalLinks(links);

  @override
  Future<void> addApplication(ApplicationModel application) async {
    final list = await loadApplications();
    list.add(application);
    await _service.saveAllApplications(list);
  }

  @override
  Future<void> updateApplication(ApplicationModel application) async {
    final list = await loadApplications();
    final index = list.indexWhere((a) => a.id == application.id);
    if (index >= 0) {
      list[index] = application;
    } else {
      list.add(application);
    }
    await _service.saveAllApplications(list);
  }

  @override
  Future<void> deleteApplication(String id) async {
    final list = await loadApplications();
    list.removeWhere((a) => a.id == id);
    await _service.saveAllApplications(list);

    // Also remove associated status history, docs, scholarships, contacts
    final history = await loadStatusHistory();
    history.removeWhere((h) => h.applicationId == id);
    await _service.saveAllStatusHistory(history);

    final docs = await loadDocuments();
    docs.removeWhere((d) => d.applicationId == id);
    await _service.saveAllDocuments(docs);

    final scholarships = await loadScholarships();
    scholarships.removeWhere((s) => s.applicationId == id);
    await _service.saveAllScholarships(scholarships);

    final contacts = await loadContacts();
    contacts.removeWhere((c) => c.applicationId == id);
    await _service.saveAllContacts(contacts);
  }

  @override
  Future<List<StatusHistoryModel>> loadStatusHistory([String? applicationId]) =>
      _service.loadStatusHistory(applicationId);

  @override
  Future<void> saveStatusHistory(List<StatusHistoryModel> history) =>
      _service.saveAllStatusHistory(history);

  @override
  Future<List<DocumentModel>> loadDocuments([String? applicationId]) =>
      _service.loadDocuments(applicationId);

  @override
  Future<void> saveDocuments(List<DocumentModel> documents) =>
      _service.saveAllDocuments(documents);

  @override
  Future<List<ScholarshipModel>> loadScholarships([String? applicationId]) =>
      _service.loadScholarships(applicationId);

  @override
  Future<void> saveScholarships(List<ScholarshipModel> scholarships) =>
      _service.saveAllScholarships(scholarships);

  @override
  Future<List<ContactModel>> loadContacts([String? applicationId]) =>
      _service.loadContacts(applicationId);

  @override
  Future<void> saveContacts(List<ContactModel> contacts) =>
      _service.saveAllContacts(contacts);

  @override
  Future<List<EmailAccountModel>> loadEmails() => _service.loadEmails();

  @override
  Future<void> saveEmails(List<EmailAccountModel> emails) =>
      _service.saveAllEmails(emails);

  @override
  Future<List<CountryStatModel>> loadCountries() =>
      _service.loadCountries();

  @override
  Future<void> syncCountries(List<CountryStatModel> countries) =>
      _service.syncCountries(countries);

  @override
  Future<AppSettingsModel> loadSettings() => _service.loadSettings();

  @override
  Future<void> saveSettings(AppSettingsModel settings) =>
      _service.saveSettings(settings);

  @override
  Future<File> createBackup([String? directoryPath]) =>
      _service.createTimestampedBackup(directoryPath);

  @override
  Future<void> restoreBackup(File backupFile) =>
      _service.restoreBackup(backupFile);

  @override
  Future<void> importExcel(File sourceFile) =>
      _service.importDatabase(sourceFile);

  @override
  Future<void> exportExcel(File destinationFile) =>
      _service.exportDatabase(destinationFile);

  @override
  Future<String> exportCsv(List<ApplicationModel> applications) =>
      _service.exportApplicationsCsv(applications);

  @override
  Future<File> getDatabaseFile() => _service.getDatabaseFile();

  @override
  Future<bool> revealInFinder() => _service.revealInFinder();

  @override
  Future<bool> openInExcel() => _service.openInExcel();

  @override
  void setCustomPath(String path) => _service.setCustomPath(path);
}
