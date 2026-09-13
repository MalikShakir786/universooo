import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/application_model.dart';
import '../models/status_history_model.dart';
import '../models/document_model.dart';
import '../models/scholarship_model.dart';
import '../models/contact_model.dart';
import '../models/email_account_model.dart';
import '../models/country_stat_model.dart';
import '../models/app_settings_model.dart';

class ExcelDatabaseService {
  static final ExcelDatabaseService instance = ExcelDatabaseService._internal();
  ExcelDatabaseService._internal();

  String? _customDatabasePath;

  // Sheet names matching Requirement 29
  static const String sheetApplications = 'Applications';
  static const String sheetStatusHistory = 'Status History';
  static const String sheetDocuments = 'Documents';
  static const String sheetScholarships = 'Scholarships';
  static const String sheetContacts = 'Contacts';
  static const String sheetEmails = 'Emails';
  static const String sheetCountries = 'Countries';
  static const String sheetSettings = 'Settings';

  void setCustomPath(String path) {
    _customDatabasePath = path.trim().isEmpty ? null : path.trim();
  }

  // Concurrency queue to serialize writes and avoid race conditions
  Future<void> _writeQueue = Future.value();

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final prev = _writeQueue;
    final completer = Completer<T>();
    _writeQueue = prev.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  /// Resolve database file location.
  /// Defaults to ~/Documents/UniversityApplications/university_applications.xlsx
  /// which is permanently accessible to the user on macOS, Windows, Linux.
  Future<File> getDatabaseFile() async {
    if (_customDatabasePath != null && _customDatabasePath!.isNotEmpty) {
      final customFile = File(_customDatabasePath!);
      if (!await customFile.parent.exists()) {
        await customFile.parent.create(recursive: true);
      }
      return customFile;
    }

    // Check .env configuration if present
    String? envDir;
    try {
      final envFile = File('.env');
      if (envFile.existsSync()) {
        for (final line in envFile.readAsLinesSync()) {
          final trimmed = line.trim();
          if (trimmed.startsWith('EXCEL_DATABASE_DIR=')) {
            final val = trimmed.substring('EXCEL_DATABASE_DIR='.length).trim();
            if (val.isNotEmpty) envDir = val;
            break;
          }
        }
      }
    } catch (_) {}

    Directory targetDir;
    if (envDir != null && envDir.isNotEmpty) {
      targetDir = Directory(envDir);
    } else {
      try {
        final home = Platform.environment['HOME'];
        if (home != null && home.isNotEmpty && (Platform.isMacOS || Platform.isLinux)) {
          targetDir = Directory(p.join(home, 'Documents', 'UniversityApplications'));
        } else {
          final appDocDir = await getApplicationDocumentsDirectory();
          targetDir = Directory(p.join(appDocDir.path, 'UniversityApplications'));
        }
      } catch (_) {
        targetDir = Directory('data');
      }
    }

    // Create directory safely; fallback to project data directory if OS permissions prevent creation
    try {
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
    } catch (_) {
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        targetDir = Directory(p.join(appDocDir.path, 'UniversityApplications'));
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      } catch (_) {
        targetDir = Directory('data');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      }
    }

    final targetFile = File(p.join(targetDir.path, 'university_applications.xlsx'));

    // Check if target file already exists; if not, check legacy migration paths
    if (!await targetFile.exists()) {
      final legacyCandidates = [
        // Project backup or root
        p.join(Directory.current.path, 'university_applications_backup.xlsx'),
        p.join(Directory.current.path, 'university_applications.xlsx'),
        // Project relative data folder
        p.join(Directory.current.path, 'data', 'university_applications.xlsx'),
        p.join(Directory.current.path, 'data', 'university_applications_backup.xlsx'),
        // Old sandbox container folder
        if (Platform.environment['HOME'] != null)
          p.join(Platform.environment['HOME']!, 'Library', 'Containers', 'com.example.universitySystem', 'Data', 'data', 'university_applications_backup.xlsx'),
        if (Platform.environment['HOME'] != null)
          p.join(Platform.environment['HOME']!, 'Library', 'Containers', 'com.example.universitySystem', 'Data', 'data', 'university_applications.xlsx'),
      ];

      for (final candPath in legacyCandidates) {
        final candFile = File(candPath);
        if (await candFile.exists() && await candFile.length() > 0) {
          try {
            final bytes = await candFile.readAsBytes();
            Excel.decodeBytes(bytes); // Validate before migrating
            await candFile.copy(targetFile.path);
            break;
          } catch (_) {}
        }
      }
    }

    return targetFile;
  }

  /// Reveal the database file in macOS Finder or native file explorer
  Future<bool> revealInFinder() async {
    try {
      final file = await getDatabaseFile();
      if (Platform.isMacOS) {
        final res = await Process.run('open', ['-R', file.path]);
        return res.exitCode == 0;
      } else if (Platform.isWindows) {
        final res = await Process.run('explorer.exe', ['/select,', file.path]);
        return res.exitCode == 0;
      } else if (Platform.isLinux) {
        final res = await Process.run('xdg-open', [file.parent.path]);
        return res.exitCode == 0;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Open the database file directly in Microsoft Excel, Numbers, or system spreadsheet app
  Future<bool> openInExcel() async {
    try {
      final file = await getDatabaseFile();
      if (!await file.exists()) {
        await initialize();
      }
      if (Platform.isMacOS) {
        final res = await Process.run('open', [file.path]);
        return res.exitCode == 0;
      } else if (Platform.isWindows) {
        final res = await Process.run('cmd', ['/c', 'start', '', file.path]);
        return res.exitCode == 0;
      } else if (Platform.isLinux) {
        final res = await Process.run('xdg-open', [file.path]);
        return res.exitCode == 0;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Get backup file location (university_applications_backup.xlsx)
  Future<File> getBackupFile() async {
    final dbFile = await getDatabaseFile();
    return File(p.join(dbFile.parent.path, 'university_applications_backup.xlsx'));
  }

  /// Check if database file exists
  Future<bool> databaseExists() async {
    final file = await getDatabaseFile();
    return file.exists();
  }

  // --- Helper Conversion Methods ---
  static String _cellToStr(CellValue? cell) {
    if (cell == null) return '';
    if (cell is TextCellValue) return cell.value.toString();
    if (cell is IntCellValue) return cell.value.toString();
    if (cell is DoubleCellValue) return cell.value.toString();
    if (cell is BoolCellValue) return cell.value.toString();
    if (cell is DateCellValue) {
      return '${cell.year.toString().padLeft(4, '0')}-${cell.month.toString().padLeft(2, '0')}-${cell.day.toString().padLeft(2, '0')}';
    }
    return cell.toString();
  }

  static double _cellToDouble(CellValue? cell) {
    if (cell == null) return 0.0;
    if (cell is DoubleCellValue) return cell.value;
    if (cell is IntCellValue) return cell.value.toDouble();
    if (cell is TextCellValue) return double.tryParse(cell.value.toString()) ?? 0.0;
    return 0.0;
  }

  static int cellToInt(CellValue? cell) {
    if (cell == null) return 0;
    if (cell is IntCellValue) return cell.value;
    if (cell is DoubleCellValue) return cell.value.round();
    if (cell is TextCellValue) return int.tryParse(cell.value.toString()) ?? 0;
    return 0;
  }

  static bool _cellToBool(CellValue? cell) {
    if (cell == null) return false;
    if (cell is BoolCellValue) return cell.value;
    if (cell is IntCellValue) return cell.value == 1;
    if (cell is TextCellValue) {
      final s = cell.value.toString().trim().toLowerCase();
      return s == 'true' || s == 'yes' || s == '1';
    }
    return false;
  }

  // --- Initialize Workbook ---
  Future<void> initialize() async {
    final file = await getDatabaseFile();
    final backupFile = await getBackupFile();
    final tempFile = File('${file.path}.tmp');

    if (!await file.exists() || await file.length() == 0) {
      // 1. Check if temporary file exists and is valid
      if (await tempFile.exists() && await tempFile.length() > 0) {
        try {
          final bytes = await tempFile.readAsBytes();
          Excel.decodeBytes(bytes);
          await tempFile.copy(file.path);
          return;
        } catch (_) {}
      }

      // 2. Check if backup file exists and is valid
      if (await backupFile.exists() && await backupFile.length() > 0) {
        try {
          final bytes = await backupFile.readAsBytes();
          Excel.decodeBytes(bytes);
          await backupFile.copy(file.path);
          return;
        } catch (_) {}
      }

      // 3. Truly new database: create fresh empty workbook
      await createEmptyWorkbook(file);
    }
  }

  /// Create a fresh workbook with all 8 sheets and headers
  Future<void> createEmptyWorkbook([File? targetFile]) async {
    final file = targetFile ?? await getDatabaseFile();
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    final excel = Excel.createExcel();

    // Remove default 'Sheet1' if present
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // 1. Applications Sheet Headers
    final sheetApp = excel[sheetApplications];
    final appHeaders = [
      'ID', 'University Name', 'Country', 'City', 'University Website',
      'Course Name', 'Degree Level', 'Faculty', 'Program Website', 'Study Mode',
      'Duration', 'Credits', 'Language', 'Intake', 'Semester Year',
      'Application Deadline', 'Start of Applications', 'Scholarship Deadline',
      'Housing Deadline', 'Visa Deadline', 'Decision Date', 'Application Date',
      'Status', 'Priority', 'Application Email', 'Application Fee',
      'Tuition Fee', 'Living Cost', 'Scholarship Amount', 'IELTS Required',
      'IELTS Overall Required', 'IELTS Listening Required', 'IELTS Reading Required',
      'IELTS Writing Required', 'IELTS Speaking Required', 'My IELTS Score',
      'IELTS Status', 'TOEFL Required', 'PTE Required', 'GPA Required',
      'My GPA', 'GRE Required', 'GMAT Required', 'SOP Required', 'CV Required',
      'Recommendation Required', 'Portfolio Required', 'Interview Required',
      'University Rating', 'Academic Rating', 'Cost Rating', 'Location Rating',
      'Career Rating', 'Student Life Rating', 'Pros', 'Cons', 'Personal Review',
      'General Notes', 'Created Date', 'Last Updated', 'Is Favorite'
    ];
    sheetApp.appendRow(appHeaders.map((h) => TextCellValue(h)).toList());

    // 2. Status History Sheet Headers
    final sheetHist = excel[sheetStatusHistory];
    final histHeaders = [
      'ID', 'Application ID', 'Date', 'Previous Status', 'New Status', 'Event', 'Notes'
    ];
    sheetHist.appendRow(histHeaders.map((h) => TextCellValue(h)).toList());

    // 3. Documents Sheet Headers
    final sheetDoc = excel[sheetDocuments];
    final docHeaders = [
      'ID', 'Application ID', 'Document', 'Required', 'Completed', 'Submitted', 'Notes'
    ];
    sheetDoc.appendRow(docHeaders.map((h) => TextCellValue(h)).toList());

    // 4. Scholarships Sheet Headers
    final sheetSchol = excel[sheetScholarships];
    final scholHeaders = [
      'ID', 'Application ID', 'Scholarship Name', 'Amount', 'Deadline', 'Eligibility', 'Status', 'Notes', 'Organization'
    ];
    sheetSchol.appendRow(scholHeaders.map((h) => TextCellValue(h)).toList());

    // 5. Contacts Sheet Headers
    final sheetCont = excel[sheetContacts];
    final contHeaders = [
      'ID', 'Application ID', 'Department', 'Contact Person', 'Email', 'Phone', 'Notes'
    ];
    sheetCont.appendRow(contHeaders.map((h) => TextCellValue(h)).toList());

    // 6. Emails Sheet Headers
    final sheetEm = excel[sheetEmails];
    final emHeaders = [
      'ID', 'Email Address', 'Type', 'Notes'
    ];
    sheetEm.appendRow(emHeaders.map((h) => TextCellValue(h)).toList());

    // 7. Countries Sheet Headers
    final sheetCo = excel[sheetCountries];
    final coHeaders = [
      'Country', 'Flag', 'Applications', 'Submitted', 'Accepted', 'Rejected', 'Pending'
    ];
    sheetCo.appendRow(coHeaders.map((h) => TextCellValue(h)).toList());

    // 8. Settings Sheet Headers
    final sheetSet = excel[sheetSettings];
    final setHeaders = [
      'Setting', 'Value'
    ];
    sheetSet.appendRow(setHeaders.map((h) => TextCellValue(h)).toList());

    await _atomicWriteExcel(excel, file);
  }

  /// Safe atomic write: writes to temporary file first, verifies integrity, creates backup, then atomically replaces
  Future<void> _atomicWriteExcel(Excel excel, File targetFile) async {
    return _synchronized(() async {
      final bytes = excel.save();
      if (bytes == null) {
        throw Exception("Failed to encode Excel workbook");
      }

      // Pre-write sanity verification: Ensure encoded bytes are a valid Excel archive
      try {
        Excel.decodeBytes(bytes);
      } catch (e) {
        throw Exception("Encoded Excel workbook failed verification: $e");
      }

      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }

      // Auto backup current file before overwrite if file already exists and is non-empty
      if (await targetFile.exists() && await targetFile.length() > 0) {
        try {
          final backupFile = await getBackupFile();
          await targetFile.copy(backupFile.path);
        } catch (_) {
          // Continue if backup creation fails silently
        }
      }

      final tempFile = File('${targetFile.path}.tmp');
      await tempFile.writeAsBytes(bytes, flush: true, mode: FileMode.write);

      // Atomically replace targetFile without an in-between deletion gap
      try {
        // In POSIX (macOS/Linux), rename atomically overwrites targetFile
        await tempFile.rename(targetFile.path);
      } catch (_) {
        // Fallback: write bytes directly with flush
        await targetFile.writeAsBytes(bytes, flush: true, mode: FileMode.write);
        if (await tempFile.exists()) {
          try {
            await tempFile.delete();
          } catch (_) {}
        }
      }
    });
  }

  /// Load Excel Workbook with automatic corruption recovery
  Future<Excel> _loadExcel([File? targetFile]) async {
    final file = targetFile ?? await getDatabaseFile();
    final backupFile = await getBackupFile();
    final tempFile = File('${file.path}.tmp');

    // 1. Primary: Try loading existing database file
    if (await file.exists() && await file.length() > 0) {
      try {
        final bytes = await file.readAsBytes();
        return Excel.decodeBytes(bytes);
      } catch (_) {
        // Target file corrupted or invalid zip! Proceed to auto-recovery
      }
    }

    // 2. Recovery: Try loading from .tmp file if it exists and is valid
    if (await tempFile.exists() && await tempFile.length() > 0) {
      try {
        final bytes = await tempFile.readAsBytes();
        final decoded = Excel.decodeBytes(bytes);
        // Recover target file from valid temp file
        await tempFile.copy(file.path);
        return decoded;
      } catch (_) {}
    }

    // 3. Recovery: Try loading from backup file if it exists and is valid
    if (await backupFile.exists() && await backupFile.length() > 0) {
      try {
        final bytes = await backupFile.readAsBytes();
        final decoded = Excel.decodeBytes(bytes);
        // Recover target file from valid backup
        await backupFile.copy(file.path);
        return decoded;
      } catch (_) {}
    }

    // 4. If no valid file or backup exists at all, initialize fresh workbook template
    await createEmptyWorkbook(file);
    final bytes = await file.readAsBytes();
    return Excel.decodeBytes(bytes);
  }

  // ==========================================
  // APPLICATIONS CRUD (Sheet 1)
  // ==========================================

  Future<List<ApplicationModel>> loadApplications() async {
    final excel = await _loadExcel();
    final sheet = excel[sheetApplications];
    final List<ApplicationModel> list = [];

    if (sheet.rows.length <= 1) return list; // Only header or empty

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;
      final id = _cellToStr(row.isNotEmpty ? row[0]?.value : null).trim();
      final univName = _cellToStr(row.length > 1 ? row[1]?.value : null).trim();
      if (id.isEmpty && univName.isEmpty) continue;

      list.add(ApplicationModel(
        id: id,
        universityName: univName,
        country: _cellToStr(row.length > 2 ? row[2]?.value : null),
        city: _cellToStr(row.length > 3 ? row[3]?.value : null),
        universityWebsite: _cellToStr(row.length > 4 ? row[4]?.value : null),
        courseName: _cellToStr(row.length > 5 ? row[5]?.value : null),
        degreeLevel: _cellToStr(row.length > 6 ? row[6]?.value : null),
        faculty: _cellToStr(row.length > 7 ? row[7]?.value : null),
        programWebsite: _cellToStr(row.length > 8 ? row[8]?.value : null),
        studyMode: _cellToStr(row.length > 9 ? row[9]?.value : null),
        duration: _cellToStr(row.length > 10 ? row[10]?.value : null),
        credits: _cellToStr(row.length > 11 ? row[11]?.value : null),
        language: _cellToStr(row.length > 12 ? row[12]?.value : null),
        intake: _cellToStr(row.length > 13 ? row[13]?.value : null),
        semesterYear: _cellToStr(row.length > 14 ? row[14]?.value : null),
        applicationDeadline: _cellToStr(row.length > 15 ? row[15]?.value : null),
        startOfApplications: _cellToStr(row.length > 16 ? row[16]?.value : null),
        scholarshipDeadline: _cellToStr(row.length > 17 ? row[17]?.value : null),
        housingDeadline: _cellToStr(row.length > 18 ? row[18]?.value : null),
        visaDeadline: _cellToStr(row.length > 19 ? row[19]?.value : null),
        decisionDate: _cellToStr(row.length > 20 ? row[20]?.value : null),
        applicationDate: _cellToStr(row.length > 21 ? row[21]?.value : null),
        status: _cellToStr(row.length > 22 ? row[22]?.value : null),
        priority: _cellToStr(row.length > 23 ? row[23]?.value : null),
        applicationEmail: _cellToStr(row.length > 24 ? row[24]?.value : null),
        applicationFee: _cellToDouble(row.length > 25 ? row[25]?.value : null),
        tuitionFee: _cellToDouble(row.length > 26 ? row[26]?.value : null),
        livingCost: _cellToDouble(row.length > 27 ? row[27]?.value : null),
        scholarshipAmount: _cellToDouble(row.length > 28 ? row[28]?.value : null),
        ieltsRequired: _cellToBool(row.length > 29 ? row[29]?.value : null),
        ieltsOverallRequired: _cellToDouble(row.length > 30 ? row[30]?.value : null),
        ieltsListeningRequired: _cellToDouble(row.length > 31 ? row[31]?.value : null),
        ieltsReadingRequired: _cellToDouble(row.length > 32 ? row[32]?.value : null),
        ieltsWritingRequired: _cellToDouble(row.length > 33 ? row[33]?.value : null),
        ieltsSpeakingRequired: _cellToDouble(row.length > 34 ? row[34]?.value : null),
        myIeltsScore: _cellToDouble(row.length > 35 ? row[35]?.value : null),
        ieltsStatus: _cellToStr(row.length > 36 ? row[36]?.value : null),
        toeflRequired: _cellToStr(row.length > 37 ? row[37]?.value : null),
        pteRequired: _cellToStr(row.length > 38 ? row[38]?.value : null),
        gpaRequired: _cellToDouble(row.length > 39 ? row[39]?.value : null),
        myGpa: _cellToDouble(row.length > 40 ? row[40]?.value : null),
        greRequired: _cellToStr(row.length > 41 ? row[41]?.value : null),
        gmatRequired: _cellToStr(row.length > 42 ? row[42]?.value : null),
        sopRequired: _cellToBool(row.length > 43 ? row[43]?.value : null),
        cvRequired: _cellToBool(row.length > 44 ? row[44]?.value : null),
        recommendationRequired: _cellToBool(row.length > 45 ? row[45]?.value : null),
        portfolioRequired: _cellToBool(row.length > 46 ? row[46]?.value : null),
        interviewRequired: _cellToBool(row.length > 47 ? row[47]?.value : null),
        universityRating: _cellToDouble(row.length > 48 ? row[48]?.value : null),
        academicRating: _cellToDouble(row.length > 49 ? row[49]?.value : null),
        costRating: _cellToDouble(row.length > 50 ? row[50]?.value : null),
        locationRating: _cellToDouble(row.length > 51 ? row[51]?.value : null),
        careerRating: _cellToDouble(row.length > 52 ? row[52]?.value : null),
        studentLifeRating: _cellToDouble(row.length > 53 ? row[53]?.value : null),
        pros: _cellToStr(row.length > 54 ? row[54]?.value : null),
        cons: _cellToStr(row.length > 55 ? row[55]?.value : null),
        personalReview: _cellToStr(row.length > 56 ? row[56]?.value : null),
        generalNotes: _cellToStr(row.length > 57 ? row[57]?.value : null),
        createdDate: _cellToStr(row.length > 58 ? row[58]?.value : null),
        lastUpdated: _cellToStr(row.length > 59 ? row[59]?.value : null),
        isFavorite: _cellToBool(row.length > 60 ? row[60]?.value : null),
      ));
    }
    return list;
  }

  Future<void> saveAllApplications(List<ApplicationModel> applications) async {
    final excel = await _loadExcel();
    final sheet = excel[sheetApplications];

    // Clear existing data rows (keep header row)
    final headerRow = sheet.rows.isNotEmpty
        ? sheet.rows[0].map((c) => TextCellValue(_cellToStr(c?.value))).toList()
        : <CellValue>[];

    // Reset sheet
    excel.delete(sheetApplications);
    final newSheet = excel[sheetApplications];
    if (headerRow.isNotEmpty) {
      newSheet.appendRow(headerRow);
    }

    for (final app in applications) {
      newSheet.appendRow([
        TextCellValue(app.id),
        TextCellValue(app.universityName),
        TextCellValue(app.country),
        TextCellValue(app.city),
        TextCellValue(app.universityWebsite),
        TextCellValue(app.courseName),
        TextCellValue(app.degreeLevel),
        TextCellValue(app.faculty),
        TextCellValue(app.programWebsite),
        TextCellValue(app.studyMode),
        TextCellValue(app.duration),
        TextCellValue(app.credits),
        TextCellValue(app.language),
        TextCellValue(app.intake),
        TextCellValue(app.semesterYear),
        TextCellValue(app.applicationDeadline),
        TextCellValue(app.startOfApplications),
        TextCellValue(app.scholarshipDeadline),
        TextCellValue(app.housingDeadline),
        TextCellValue(app.visaDeadline),
        TextCellValue(app.decisionDate),
        TextCellValue(app.applicationDate),
        TextCellValue(app.status),
        TextCellValue(app.priority),
        TextCellValue(app.applicationEmail),
        DoubleCellValue(app.applicationFee),
        DoubleCellValue(app.tuitionFee),
        DoubleCellValue(app.livingCost),
        DoubleCellValue(app.scholarshipAmount),
        BoolCellValue(app.ieltsRequired),
        DoubleCellValue(app.ieltsOverallRequired),
        DoubleCellValue(app.ieltsListeningRequired),
        DoubleCellValue(app.ieltsReadingRequired),
        DoubleCellValue(app.ieltsWritingRequired),
        DoubleCellValue(app.ieltsSpeakingRequired),
        DoubleCellValue(app.myIeltsScore),
        TextCellValue(app.ieltsStatus),
        TextCellValue(app.toeflRequired),
        TextCellValue(app.pteRequired),
        DoubleCellValue(app.gpaRequired),
        DoubleCellValue(app.myGpa),
        TextCellValue(app.greRequired),
        TextCellValue(app.gmatRequired),
        BoolCellValue(app.sopRequired),
        BoolCellValue(app.cvRequired),
        BoolCellValue(app.recommendationRequired),
        BoolCellValue(app.portfolioRequired),
        BoolCellValue(app.interviewRequired),
        DoubleCellValue(app.universityRating),
        DoubleCellValue(app.academicRating),
        DoubleCellValue(app.costRating),
        DoubleCellValue(app.locationRating),
        DoubleCellValue(app.careerRating),
        DoubleCellValue(app.studentLifeRating),
        TextCellValue(app.pros),
        TextCellValue(app.cons),
        TextCellValue(app.personalReview),
        TextCellValue(app.generalNotes),
        TextCellValue(app.createdDate),
        TextCellValue(app.lastUpdated),
        BoolCellValue(app.isFavorite),
      ]);
    }

    final file = await getDatabaseFile();
    await _atomicWriteExcel(excel, file);
  }

  // ==========================================
  // STATUS HISTORY CRUD (Sheet 2)
  // ==========================================

  Future<List<StatusHistoryModel>> loadStatusHistory([String? applicationId]) async {
    final excel = await _loadExcel();
    final sheet = excel[sheetStatusHistory];
    final List<StatusHistoryModel> list = [];

    if (sheet.rows.length <= 1) return list;

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;
      final id = _cellToStr(row.isNotEmpty ? row[0]?.value : null);
      final appId = _cellToStr(row.length > 1 ? row[1]?.value : null);
      if (id.isEmpty) continue;

      if (applicationId != null && appId != applicationId) continue;

      list.add(StatusHistoryModel(
        id: id,
        applicationId: appId,
        date: _cellToStr(row.length > 2 ? row[2]?.value : null),
        previousStatus: _cellToStr(row.length > 3 ? row[3]?.value : null),
        newStatus: _cellToStr(row.length > 4 ? row[4]?.value : null),
        event: _cellToStr(row.length > 5 ? row[5]?.value : null),
        notes: _cellToStr(row.length > 6 ? row[6]?.value : null),
      ));
    }
    return list;
  }

  Future<void> saveAllStatusHistory(List<StatusHistoryModel> history) async {
    final excel = await _loadExcel();
    final headerRow = excel[sheetStatusHistory].rows.isNotEmpty
        ? excel[sheetStatusHistory].rows[0].map((c) => TextCellValue(_cellToStr(c?.value))).toList()
        : <CellValue>[];

    excel.delete(sheetStatusHistory);
    final newSheet = excel[sheetStatusHistory];
    if (headerRow.isNotEmpty) {
      newSheet.appendRow(headerRow);
    }

    for (final h in history) {
      newSheet.appendRow([
        TextCellValue(h.id),
        TextCellValue(h.applicationId),
        TextCellValue(h.date),
        TextCellValue(h.previousStatus),
        TextCellValue(h.newStatus),
        TextCellValue(h.event),
        TextCellValue(h.notes),
      ]);
    }

    final file = await getDatabaseFile();
    await _atomicWriteExcel(excel, file);
  }

  // ==========================================
  // DOCUMENTS CRUD (Sheet 3)
  // ==========================================

  Future<List<DocumentModel>> loadDocuments([String? applicationId]) async {
    final excel = await _loadExcel();
    final sheet = excel[sheetDocuments];
    final List<DocumentModel> list = [];

    if (sheet.rows.length <= 1) return list;

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;
      final id = _cellToStr(row.isNotEmpty ? row[0]?.value : null);
      final appId = _cellToStr(row.length > 1 ? row[1]?.value : null);
      if (id.isEmpty) continue;

      if (applicationId != null && appId != applicationId) continue;

      list.add(DocumentModel(
        id: id,
        applicationId: appId,
        document: _cellToStr(row.length > 2 ? row[2]?.value : null),
        required: _cellToBool(row.length > 3 ? row[3]?.value : null),
        completed: _cellToBool(row.length > 4 ? row[4]?.value : null),
        submitted: _cellToBool(row.length > 5 ? row[5]?.value : null),
        notes: _cellToStr(row.length > 6 ? row[6]?.value : null),
      ));
    }
    return list;
  }

  Future<void> saveAllDocuments(List<DocumentModel> docs) async {
    final excel = await _loadExcel();
    final headerRow = excel[sheetDocuments].rows.isNotEmpty
        ? excel[sheetDocuments].rows[0].map((c) => TextCellValue(_cellToStr(c?.value))).toList()
        : <CellValue>[];

    excel.delete(sheetDocuments);
    final newSheet = excel[sheetDocuments];
    if (headerRow.isNotEmpty) {
      newSheet.appendRow(headerRow);
    }

    for (final d in docs) {
      newSheet.appendRow([
        TextCellValue(d.id),
        TextCellValue(d.applicationId),
        TextCellValue(d.document),
        BoolCellValue(d.required),
        BoolCellValue(d.completed),
        BoolCellValue(d.submitted),
        TextCellValue(d.notes),
      ]);
    }

    final file = await getDatabaseFile();
    await _atomicWriteExcel(excel, file);
  }

  // ==========================================
  // SCHOLARSHIPS CRUD (Sheet 4)
  // ==========================================

  Future<List<ScholarshipModel>> loadScholarships([String? applicationId]) async {
    final excel = await _loadExcel();
    final sheet = excel[sheetScholarships];
    final List<ScholarshipModel> list = [];

    if (sheet.rows.length <= 1) return list;

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;
      final id = _cellToStr(row.isNotEmpty ? row[0]?.value : null);
      final appId = _cellToStr(row.length > 1 ? row[1]?.value : null);
      if (id.isEmpty) continue;

      if (applicationId != null && appId != applicationId) continue;

      list.add(ScholarshipModel(
        id: id,
        applicationId: appId,
        scholarshipName: _cellToStr(row.length > 2 ? row[2]?.value : null),
        amount: _cellToDouble(row.length > 3 ? row[3]?.value : null),
        deadline: _cellToStr(row.length > 4 ? row[4]?.value : null),
        eligibility: _cellToStr(row.length > 5 ? row[5]?.value : null),
        status: _cellToStr(row.length > 6 ? row[6]?.value : null),
        notes: _cellToStr(row.length > 7 ? row[7]?.value : null),
        organization: _cellToStr(row.length > 8 ? row[8]?.value : null),
      ));
    }
    return list;
  }

  Future<void> saveAllScholarships(List<ScholarshipModel> scholarships) async {
    final excel = await _loadExcel();
    var headerRow = excel[sheetScholarships].rows.isNotEmpty
        ? excel[sheetScholarships].rows[0].map((c) => TextCellValue(_cellToStr(c?.value))).toList()
        : <CellValue>[];

    if (headerRow.isNotEmpty && headerRow.length < 9) {
      headerRow.add(TextCellValue('Organization'));
    }

    excel.delete(sheetScholarships);
    final newSheet = excel[sheetScholarships];
    if (headerRow.isNotEmpty) {
      newSheet.appendRow(headerRow);
    } else {
      newSheet.appendRow([
        'ID', 'Application ID', 'Scholarship Name', 'Amount', 'Deadline', 'Eligibility', 'Status', 'Notes', 'Organization'
      ].map((h) => TextCellValue(h)).toList());
    }

    for (final s in scholarships) {
      newSheet.appendRow([
        TextCellValue(s.id),
        TextCellValue(s.applicationId),
        TextCellValue(s.scholarshipName),
        DoubleCellValue(s.amount),
        TextCellValue(s.deadline),
        TextCellValue(s.eligibility),
        TextCellValue(s.status),
        TextCellValue(s.notes),
        TextCellValue(s.organization),
      ]);
    }

    final file = await getDatabaseFile();
    await _atomicWriteExcel(excel, file);
  }

  // ==========================================
  // CONTACTS CRUD (Sheet 5)
  // ==========================================

  Future<List<ContactModel>> loadContacts([String? applicationId]) async {
    final excel = await _loadExcel();
    final sheet = excel[sheetContacts];
    final List<ContactModel> list = [];

    if (sheet.rows.length <= 1) return list;

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;
      final id = _cellToStr(row.isNotEmpty ? row[0]?.value : null);
      final appId = _cellToStr(row.length > 1 ? row[1]?.value : null);
      if (id.isEmpty) continue;

      if (applicationId != null && appId != applicationId) continue;

      list.add(ContactModel(
        id: id,
        applicationId: appId,
        department: _cellToStr(row.length > 2 ? row[2]?.value : null),
        contactPerson: _cellToStr(row.length > 3 ? row[3]?.value : null),
        email: _cellToStr(row.length > 4 ? row[4]?.value : null),
        phone: _cellToStr(row.length > 5 ? row[5]?.value : null),
        notes: _cellToStr(row.length > 6 ? row[6]?.value : null),
      ));
    }
    return list;
  }

  Future<void> saveAllContacts(List<ContactModel> contacts) async {
    final excel = await _loadExcel();
    final headerRow = excel[sheetContacts].rows.isNotEmpty
        ? excel[sheetContacts].rows[0].map((c) => TextCellValue(_cellToStr(c?.value))).toList()
        : <CellValue>[];

    excel.delete(sheetContacts);
    final newSheet = excel[sheetContacts];
    if (headerRow.isNotEmpty) {
      newSheet.appendRow(headerRow);
    }

    for (final c in contacts) {
      newSheet.appendRow([
        TextCellValue(c.id),
        TextCellValue(c.applicationId),
        TextCellValue(c.department),
        TextCellValue(c.contactPerson),
        TextCellValue(c.email),
        TextCellValue(c.phone),
        TextCellValue(c.notes),
      ]);
    }

    final file = await getDatabaseFile();
    await _atomicWriteExcel(excel, file);
  }

  // ==========================================
  // EMAILS CRUD (Sheet 6)
  // ==========================================

  Future<List<EmailAccountModel>> loadEmails() async {
    final excel = await _loadExcel();
    final sheet = excel[sheetEmails];
    final List<EmailAccountModel> list = [];

    if (sheet.rows.length <= 1) return list;

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;
      final id = _cellToStr(row.isNotEmpty ? row[0]?.value : null);
      final email = _cellToStr(row.length > 1 ? row[1]?.value : null);
      if (id.isEmpty && email.isEmpty) continue;

      list.add(EmailAccountModel(
        id: id,
        emailAddress: email,
        type: _cellToStr(row.length > 2 ? row[2]?.value : null),
        notes: _cellToStr(row.length > 3 ? row[3]?.value : null),
      ));
    }
    return list;
  }

  Future<void> saveAllEmails(List<EmailAccountModel> emails) async {
    final excel = await _loadExcel();
    final headerRow = excel[sheetEmails].rows.isNotEmpty
        ? excel[sheetEmails].rows[0].map((c) => TextCellValue(_cellToStr(c?.value))).toList()
        : <CellValue>[];

    excel.delete(sheetEmails);
    final newSheet = excel[sheetEmails];
    if (headerRow.isNotEmpty) {
      newSheet.appendRow(headerRow);
    }

    for (final e in emails) {
      newSheet.appendRow([
        TextCellValue(e.id),
        TextCellValue(e.emailAddress),
        TextCellValue(e.type),
        TextCellValue(e.notes),
      ]);
    }

    final file = await getDatabaseFile();
    await _atomicWriteExcel(excel, file);
  }

  // ==========================================
  // COUNTRIES (Sheet 7)
  // ==========================================

  Future<List<CountryStatModel>> loadCountries() async {
    final excel = await _loadExcel();
    final sheet = excel[sheetCountries];
    final List<CountryStatModel> list = [];

    if (sheet.rows.length <= 1) return list;

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;
      final countryName = _cellToStr(row.isNotEmpty ? row[0]?.value : null).trim();
      if (countryName.isEmpty) continue;
      final flag = _cellToStr(row.length > 1 ? row[1]?.value : null);

      list.add(CountryStatModel(
        country: countryName,
        flag: flag.isNotEmpty ? flag : CountryStatModel.getFlag(countryName),
      ));
    }
    return list;
  }

  Future<void> syncCountries(List<CountryStatModel> countries) async {
    final excel = await _loadExcel();
    final headerRow = excel[sheetCountries].rows.isNotEmpty
        ? excel[sheetCountries].rows[0].map((c) => TextCellValue(_cellToStr(c?.value))).toList()
        : <CellValue>[];

    excel.delete(sheetCountries);
    final newSheet = excel[sheetCountries];
    if (headerRow.isNotEmpty) {
      newSheet.appendRow(headerRow);
    }

    for (final c in countries) {
      newSheet.appendRow([
        TextCellValue(c.country),
        TextCellValue(c.flag),
        IntCellValue(c.applicationsCount),
        IntCellValue(c.submittedCount),
        IntCellValue(c.acceptedCount),
        IntCellValue(c.rejectedCount),
        IntCellValue(c.pendingCount),
      ]);
    }

    final file = await getDatabaseFile();
    await _atomicWriteExcel(excel, file);
  }

  // ==========================================
  // SETTINGS CRUD (Sheet 8)
  // ==========================================

  Future<AppSettingsModel> loadSettings() async {
    final excel = await _loadExcel();
    final sheet = excel[sheetSettings];
    final Map<String, String> map = {};

    if (sheet.rows.length > 1) {
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.length >= 2) {
          final key = _cellToStr(row[0]?.value).trim();
          final val = _cellToStr(row[1]?.value).trim();
          if (key.isNotEmpty) {
            map[key] = val;
          }
        }
      }
    }
    return AppSettingsModel.fromMap(map);
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    final excel = await _loadExcel();
    final headerRow = excel[sheetSettings].rows.isNotEmpty
        ? excel[sheetSettings].rows[0].map((c) => TextCellValue(_cellToStr(c?.value))).toList()
        : <CellValue>[];

    excel.delete(sheetSettings);
    final newSheet = excel[sheetSettings];
    if (headerRow.isNotEmpty) {
      newSheet.appendRow(headerRow);
    }

    final map = settings.toMap();
    for (final entry in map.entries) {
      newSheet.appendRow([
        TextCellValue(entry.key),
        TextCellValue(entry.value),
      ]);
    }

    final file = await getDatabaseFile();
    await _atomicWriteExcel(excel, file);
  }

  // ==========================================
  // BACKUP, RESTORE, IMPORT, EXPORT
  // ==========================================

  /// Create timestamped backup file
  Future<File> createTimestampedBackup([String? directoryPath]) async {
    final dbFile = await getDatabaseFile();
    if (!await dbFile.exists()) {
      throw Exception("Cannot backup: Database file does not exist.");
    }
    final timestamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final parentDir = directoryPath != null ? Directory(directoryPath) : dbFile.parent;
    final backupFile = File(p.join(parentDir.path, 'backup_$timestamp.xlsx'));
    return dbFile.copy(backupFile.path);
  }

  /// Restore from a backup Excel file
  Future<void> restoreBackup(File backupSource) async {
    if (!await backupSource.exists()) {
      throw Exception("Backup file not found.");
    }
    final dbFile = await getDatabaseFile();

    // Verify it's a readable excel file
    final bytes = await backupSource.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    if (!excel.sheets.containsKey(sheetApplications)) {
      throw Exception("Invalid backup: Missing '$sheetApplications' worksheet.");
    }

    // Replace current database
    await dbFile.writeAsBytes(bytes, flush: true);
  }

  /// Export current database to a user-chosen destination
  Future<void> exportDatabase(File destinationFile) async {
    final dbFile = await getDatabaseFile();
    if (!await dbFile.exists()) {
      await initialize();
    }
    await dbFile.copy(destinationFile.path);
  }

  /// Import external Excel file and overwrite current database
  Future<void> importDatabase(File sourceFile) async {
    await restoreBackup(sourceFile);
  }

  /// Export Applications to CSV string
  Future<String> exportApplicationsCsv(List<ApplicationModel> apps) async {
    final buffer = StringBuffer();
    final headers = [
      'ID', 'University', 'Country', 'City', 'Course', 'Degree', 'Intake',
      'Year', 'Deadline', 'Status', 'Priority', 'Tuition', 'Living Cost',
      'IELTS Score', 'Rating', 'Email'
    ];
    buffer.writeln(headers.join(','));
    for (final a in apps) {
      final row = [
        a.id, a.universityName, a.country, a.city, a.courseName, a.degreeLevel,
        a.intake, a.semesterYear, a.applicationDeadline, a.status, a.priority,
        a.tuitionFee, a.livingCost, a.myIeltsScore, a.universityRating, a.applicationEmail
      ];
      buffer.writeln(row.map((val) {
        final s = val.toString();
        if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
          return '"${s.replaceAll('"', '""')}"';
        }
        return s;
      }).join(','));
    }
    return buffer.toString();
  }
}
