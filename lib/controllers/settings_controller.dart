import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/app_settings_model.dart';
import '../models/application_model.dart';
import '../repositories/application_repository.dart';

class SettingsController extends ChangeNotifier {
  final ApplicationRepository _repository;

  AppSettingsModel _settings = const AppSettingsModel();
  bool _isLoading = false;
  String? _statusMessage;
  String? _errorMessage;
  String _databaseFilePath = '';

  SettingsController({required ApplicationRepository repository})
      : _repository = repository;

  AppSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  String get databaseFilePath => _databaseFilePath;

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _repository.loadSettings();
      final dbFile = await _repository.getDatabaseFile();
      _databaseFilePath = dbFile.path;
    } catch (e) {
      _errorMessage = "Failed to load settings: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(AppSettingsModel newSettings) async {
    _settings = newSettings;
    notifyListeners();
    try {
      await _repository.saveSettings(_settings);
      _statusMessage = "Settings saved successfully";
    } catch (e) {
      _errorMessage = "Failed to save settings: $e";
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final updated = _settings.copyWith(themeMode: mode);
    await updateSettings(updated);
  }

  Future<void> setCurrency(String currency) async {
    final updated = _settings.copyWith(defaultCurrency: currency);
    await updateSettings(updated);
  }

  // --- Data Management Operations ---

  /// Export Backup to a user chosen path using native file picker
  Future<String?> exportBackupDialog() async {
    _isLoading = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final defaultName =
          'backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.xlsx';

      final dbFile = await _repository.getDatabaseFile();
      final bytes = await dbFile.readAsBytes();

      final outputUri = await FilePicker.saveFile(
        dialogTitle: 'Export Backup Excel Workbook',
        fileName: defaultName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputUri != null) {
        final path = outputUri.toFilePath();
        _statusMessage = "Backup exported to: $path";
        return path;
      }
      return null;
    } catch (e) {
      _errorMessage = "Failed to export backup: $e";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restore Backup from an existing Excel file
  Future<bool> restoreBackupDialog() async {
    _isLoading = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Select Backup Excel File to Restore',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result.isNotEmpty && result.first.path != null) {
        final file = File(result.first.path!);
        await _repository.restoreBackup(file);
        _statusMessage = "Database restored successfully from backup";
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = "Failed to restore backup: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Export CSV of applications
  Future<String?> exportCsvDialog(List<ApplicationModel> apps) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final csvString = await _repository.exportCsv(apps);
      final bytes = Uint8List.fromList(utf8.encode(csvString));

      final outputUri = await FilePicker.saveFile(
        dialogTitle: 'Export Applications to CSV',
        fileName: 'university_applications.csv',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputUri != null) {
        final path = outputUri.toFilePath();
        _statusMessage = "CSV exported to: $path";
        return path;
      }
      return null;
    } catch (e) {
      _errorMessage = "Failed to export CSV: $e";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> revealInFinder() => _repository.revealInFinder();
  Future<bool> openInExcel() => _repository.openInExcel();

  /// Choose a custom folder on your Mac/PC to store the Excel database
  Future<String?> changeDatabaseLocationDialog() async {
    try {
      final selectedDir = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Folder for University Applications Excel Database',
      );
      if (selectedDir != null && selectedDir.trim().isNotEmpty) {
        final targetFile = File('${selectedDir.trim()}/university_applications.xlsx');
        // If current database exists, copy current records over to new location
        final oldFile = await _repository.getDatabaseFile();
        if (await oldFile.exists() && !await targetFile.exists()) {
          await oldFile.copy(targetFile.path);
        }
        _repository.setCustomPath(targetFile.path);
        await _repository.initialize();
        final dbFile = await _repository.getDatabaseFile();
        _databaseFilePath = dbFile.path;
        _statusMessage = "Database moved to: ${dbFile.path}";
        notifyListeners();
        return dbFile.path;
      }
      return null;
    } catch (e) {
      _errorMessage = "Failed to change database location: $e";
      notifyListeners();
      return null;
    }
  }

  void clearStatus() {
    _statusMessage = null;
    _errorMessage = null;
    notifyListeners();
  }
}
