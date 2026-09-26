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

abstract class ApplicationRepository {
  Future<void> initialize();
  Future<List<ApplicationModel>> loadApplications();
  Future<void> saveApplications(List<ApplicationModel> applications);
  Future<void> addApplication(ApplicationModel application);
  Future<void> updateApplication(ApplicationModel application);
  Future<void> deleteApplication(String id);

  Future<List<PortalLinkModel>> loadPortalLinks();
  Future<void> savePortalLinks(List<PortalLinkModel> links);

  Future<List<StatusHistoryModel>> loadStatusHistory([String? applicationId]);
  Future<void> saveStatusHistory(List<StatusHistoryModel> history);

  Future<List<DocumentModel>> loadDocuments([String? applicationId]);
  Future<void> saveDocuments(List<DocumentModel> documents);

  Future<List<ScholarshipModel>> loadScholarships([String? applicationId]);
  Future<void> saveScholarships(List<ScholarshipModel> scholarships);

  Future<List<ContactModel>> loadContacts([String? applicationId]);
  Future<void> saveContacts(List<ContactModel> contacts);

  Future<List<EmailAccountModel>> loadEmails();
  Future<void> saveEmails(List<EmailAccountModel> emails);

  Future<List<CountryStatModel>> loadCountries();
  Future<void> syncCountries(List<CountryStatModel> countries);

  Future<AppSettingsModel> loadSettings();
  Future<void> saveSettings(AppSettingsModel settings);

  Future<File> createBackup([String? directoryPath]);
  Future<void> restoreBackup(File backupFile);
  Future<void> importExcel(File sourceFile);
  Future<void> exportExcel(File destinationFile);
  Future<String> exportCsv(List<ApplicationModel> applications);
  Future<File> getDatabaseFile();
  Future<bool> revealInFinder();
  Future<bool> openInExcel();
  void setCustomPath(String path);
}
