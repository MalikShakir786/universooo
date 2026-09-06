import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/application_model.dart';
import '../models/status_history_model.dart';
import '../models/document_model.dart';
import '../models/scholarship_model.dart';
import '../models/contact_model.dart';
import '../models/email_account_model.dart';
import '../models/country_stat_model.dart';
import '../repositories/application_repository.dart';

class ApplicationController extends ChangeNotifier {
  final ApplicationRepository _repository;
  final Uuid _uuid = const Uuid();

  List<ApplicationModel> _applications = [];
  List<StatusHistoryModel> _statusHistories = [];
  List<DocumentModel> _documents = [];
  List<ScholarshipModel> _scholarships = [];
  List<ContactModel> _contacts = [];
  List<EmailAccountModel> _emails = [];
  List<CountryStatModel> _userCountries = [];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Filters & State
  String? _selectedCountry; // null or 'All Countries'
  String _searchQuery = '';
  String? _statusFilter;
  String? _degreeFilter;
  String? _intakeFilter;
  String? _priorityFilter;
  bool? _ieltsMetFilter;
  bool _favoritesOnly = false;
  String? _statFilter; // Filters triggered by clicking Stat Cards
  String _sortBy = 'deadline'; // deadline, university, country, status, priority, ielts, date
  bool _sortAscending = true;

  // Comparison IDs (2 to 5)
  final Set<String> _comparisonIds = {};

  ApplicationController({required ApplicationRepository repository})
      : _repository = repository;

  // Getters
  List<ApplicationModel> get applications => _applications;
  List<StatusHistoryModel> get statusHistories => _statusHistories;
  List<DocumentModel> get documents => _documents;
  List<ScholarshipModel> get scholarships => _scholarships;
  List<ContactModel> get contacts => _contacts;
  List<EmailAccountModel> get emails => _emails;
  List<CountryStatModel> get userCountries => _userCountries;

  List<String> get availableCountries {
    final set = <String>{};
    for (final c in _userCountries) {
      if (c.country.trim().isNotEmpty) set.add(c.country.trim());
    }
    for (final a in _applications) {
      if (a.country.trim().isNotEmpty) set.add(a.country.trim());
    }
    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  String? get selectedCountry => _selectedCountry;
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  String? get degreeFilter => _degreeFilter;
  String? get intakeFilter => _intakeFilter;
  String? get priorityFilter => _priorityFilter;
  bool? get ieltsMetFilter => _ieltsMetFilter;
  bool get favoritesOnly => _favoritesOnly;
  String? get statFilter => _statFilter;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  Set<String> get comparisonIds => _comparisonIds;

  List<ApplicationModel> get comparisonApplications =>
      _applications.where((a) => _comparisonIds.contains(a.id)).toList();

  // --- Initialization ---
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.initialize();
      _applications = await _repository.loadApplications();
      _statusHistories = await _repository.loadStatusHistory();
      _documents = await _repository.loadDocuments();
      _scholarships = await _repository.loadScholarships();
      _contacts = await _repository.loadContacts();
      _emails = await _repository.loadEmails();
      _userCountries = await _repository.loadCountries();
      await _syncCountryStats();
    } catch (e) {
      _errorMessage = "Failed to load applications: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Filtering & Sorting ---
  List<ApplicationModel> get filteredApplications {
    return _applications.where((app) {
      // 1. Country Filter
      if (_selectedCountry != null &&
          _selectedCountry != 'All Countries' &&
          _selectedCountry!.isNotEmpty) {
        if (app.country.toLowerCase() != _selectedCountry!.toLowerCase()) {
          return false;
        }
      }

      // 2. Global Search
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = app.universityName.toLowerCase().contains(q) ||
            app.courseName.toLowerCase().contains(q) ||
            app.country.toLowerCase().contains(q) ||
            app.city.toLowerCase().contains(q) ||
            app.status.toLowerCase().contains(q) ||
            app.semesterYear.toLowerCase().contains(q) ||
            app.applicationEmail.toLowerCase().contains(q) ||
            app.generalNotes.toLowerCase().contains(q);
        if (!matches) return false;
      }

      // 3. Status Filter
      if (_statusFilter != null && _statusFilter!.isNotEmpty) {
        if (app.status.toLowerCase() != _statusFilter!.toLowerCase()) {
          return false;
        }
      }

      // 4. Degree Filter
      if (_degreeFilter != null && _degreeFilter!.isNotEmpty) {
        if (app.degreeLevel.toLowerCase() != _degreeFilter!.toLowerCase()) {
          return false;
        }
      }

      // 5. Intake Filter
      if (_intakeFilter != null && _intakeFilter!.isNotEmpty) {
        if (app.intake.toLowerCase() != _intakeFilter!.toLowerCase()) {
          return false;
        }
      }

      // 6. Priority Filter
      if (_priorityFilter != null && _priorityFilter!.isNotEmpty) {
        if (app.priority.toLowerCase() != _priorityFilter!.toLowerCase()) {
          return false;
        }
      }

      // 7. IELTS Met Filter
      if (_ieltsMetFilter != null) {
        if (app.isIeltsMet != _ieltsMetFilter) return false;
      }

      // 8. Favorites Only
      if (_favoritesOnly && !app.isFavorite) return false;

      // 9. Stat Card Filters
      if (_statFilter != null) {
        switch (_statFilter) {
          case 'Submitted':
            if (app.status != 'Applied' &&
                app.status != 'Under Review' &&
                app.status != 'Interview' &&
                app.status != 'Conditional Offer' &&
                app.status != 'Unconditional Offer' &&
                app.status != 'Accepted') {
              return false;
            }
            break;
          case 'Pending':
            if (app.status != 'Researching' &&
                app.status != 'Interested' &&
                app.status != 'Shortlisted' &&
                app.status != 'Preparing' &&
                app.status != 'Documents Pending' &&
                app.status != 'Ready to Apply' &&
                app.status != 'Under Review') {
              return false;
            }
            break;
          case 'Accepted':
            if (app.status != 'Accepted' &&
                app.status != 'Unconditional Offer' &&
                app.status != 'Conditional Offer') {
              return false;
            }
            break;
          case 'Rejected':
            if (app.status != 'Rejected') return false;
            break;
          case 'Upcoming Deadlines':
            final days = app.daysRemaining;
            if (days == null || days < 0 || days > 30) return false;
            break;
          case 'Interviews':
            if (app.status != 'Interview' && !app.interviewRequired) return false;
            break;
          case 'Shortlisted':
            if (app.status != 'Shortlisted') return false;
            break;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        int comp = 0;
        switch (_sortBy) {
          case 'deadline':
            final da = a.daysRemaining ?? 999999;
            final db = b.daysRemaining ?? 999999;
            comp = da.compareTo(db);
            break;
          case 'university':
            comp = a.universityName.compareTo(b.universityName);
            break;
          case 'country':
            comp = a.country.compareTo(b.country);
            break;
          case 'status':
            comp = a.status.compareTo(b.status);
            break;
          case 'priority':
            const priorityWeight = {'High': 3, 'Medium': 2, 'Low': 1};
            final wa = priorityWeight[a.priority] ?? 0;
            final wb = priorityWeight[b.priority] ?? 0;
            comp = wb.compareTo(wa); // Default high priority first
            break;
          case 'ielts':
            comp = a.ieltsOverallRequired.compareTo(b.ieltsOverallRequired);
            break;
          case 'date':
            comp = a.createdDate.compareTo(b.createdDate);
            break;
        }
        return _sortAscending ? comp : -comp;
      });
  }

  // --- Statistics Calculations ---
  int get totalApplications => _applications.length;

  int get submittedCount => _applications.where((a) {
        final s = a.status.toLowerCase();
        return s == 'applied' ||
            s == 'under review' ||
            s == 'interview' ||
            s == 'conditional offer' ||
            s == 'unconditional offer' ||
            s == 'accepted';
      }).length;

  int get pendingCount => _applications.where((a) {
        final s = a.status.toLowerCase();
        return s == 'researching' ||
            s == 'interested' ||
            s == 'shortlisted' ||
            s == 'preparing' ||
            s == 'documents pending' ||
            s == 'ready to apply' ||
            s == 'under review';
      }).length;

  int get acceptedCount => _applications.where((a) {
        final s = a.status.toLowerCase();
        return s == 'accepted' ||
            s == 'unconditional offer' ||
            s == 'conditional offer';
      }).length;

  int get rejectedCount =>
      _applications.where((a) => a.status.toLowerCase() == 'rejected').length;

  int get upcomingDeadlinesCount => _applications.where((a) {
        final days = a.daysRemaining;
        return days != null && days >= 0 && days <= 30;
      }).length;

  int get interviewCount => _applications.where((a) {
        return a.status.toLowerCase() == 'interview' || a.interviewRequired;
      }).length;

  int get shortlistedCount => _applications
      .where((a) => a.status.toLowerCase() == 'shortlisted')
      .length;

  double get acceptanceRate =>
      totalApplications == 0 ? 0.0 : (acceptedCount / totalApplications) * 100;

  double get offerRate =>
      submittedCount == 0 ? 0.0 : (acceptedCount / submittedCount) * 100;

  double get averageApplicationFee {
    final listWithFee = _applications.where((a) => a.applicationFee > 0);
    if (listWithFee.isEmpty) return 0.0;
    final total = listWithFee.fold(0.0, (sum, a) => sum + a.applicationFee);
    return total / listWithFee.length;
  }

  double get averageTuition {
    final listWithTuition = _applications.where((a) => a.tuitionFee > 0);
    if (listWithTuition.isEmpty) return 0.0;
    final total = listWithTuition.fold(0.0, (sum, a) => sum + a.tuitionFee);
    return total / listWithTuition.length;
  }

  // --- Country Statistics ---
  List<CountryStatModel> get countryStats {
    final Set<String> allCountryNames = {
      ..._userCountries.map((c) => c.country.trim()),
      ..._applications.map((a) => a.country.trim()),
    }..removeWhere((c) => c.isEmpty);

    final stats = allCountryNames.map((country) {
      final apps = _applications
          .where((a) => a.country.trim().toLowerCase() == country.toLowerCase())
          .toList();
      final submitted = apps.where((a) {
        final s = a.status.toLowerCase();
        return s == 'applied' ||
            s == 'under review' ||
            s == 'interview' ||
            s == 'accepted' ||
            s.contains('offer');
      }).length;
      final accepted = apps.where((a) {
        final s = a.status.toLowerCase();
        return s == 'accepted' || s.contains('offer');
      }).length;
      final rejected =
          apps.where((a) => a.status.toLowerCase() == 'rejected').length;
      final pending = apps.length - submitted;
      final upcoming = apps.where((a) {
        final d = a.daysRemaining;
        return d != null && d >= 0 && d <= 30;
      }).length;
      final totalTuition = apps.fold(0.0, (sum, a) => sum + a.tuitionFee);

      final existingUserCountry = _userCountries
          .cast<CountryStatModel?>()
          .firstWhere(
            (c) => c?.country.trim().toLowerCase() == country.toLowerCase(),
            orElse: () => null,
          );
      final flag = (existingUserCountry != null && existingUserCountry.flag.isNotEmpty)
          ? existingUserCountry.flag
          : CountryStatModel.getFlag(country);

      return CountryStatModel(
        country: country,
        flag: flag,
        applicationsCount: apps.length,
        submittedCount: submitted,
        acceptedCount: accepted,
        rejectedCount: rejected,
        pendingCount: pending,
        upcomingDeadlinesCount: upcoming,
        estimatedTuition: totalTuition,
      );
    }).toList();

    stats.sort((a, b) => b.applicationsCount.compareTo(a.applicationsCount));
    return stats;
  }

  Future<void> _syncCountryStats() async {
    await _repository.syncCountries(countryStats);
  }

  Future<bool> addCountry(String countryName, {String? flag}) async {
    final trimmed = countryName.trim();
    if (trimmed.isEmpty) return false;

    final exists = _userCountries
        .any((c) => c.country.toLowerCase() == trimmed.toLowerCase());
    if (!exists) {
      final chosenFlag = (flag != null && flag.trim().isNotEmpty)
          ? flag.trim()
          : CountryStatModel.getFlag(trimmed);

      _userCountries.add(CountryStatModel(
        country: trimmed,
        flag: chosenFlag,
      ));
      await _syncCountryStats();
      notifyListeners();
    }
    return true;
  }

  Future<void> removeCountry(String countryName) async {
    _userCountries.removeWhere(
        (c) => c.country.toLowerCase() == countryName.trim().toLowerCase());
    if (_selectedCountry != null &&
        _selectedCountry!.toLowerCase() == countryName.trim().toLowerCase()) {
      _selectedCountry = null;
    }
    await _syncCountryStats();
    notifyListeners();
  }

  // --- Duplicate Detection ---
  ApplicationModel? checkDuplicate(String university, String course, String semesterYear, {String? excludeId}) {
    for (final app in _applications) {
      if (excludeId != null && app.id == excludeId) continue;
      if (app.universityName.trim().toLowerCase() == university.trim().toLowerCase() &&
          app.courseName.trim().toLowerCase() == course.trim().toLowerCase() &&
          app.semesterYear.trim() == semesterYear.trim()) {
        return app;
      }
    }
    return null;
  }

  // --- Previous Applications for University ---
  List<ApplicationModel> getPreviousApplicationsForUniversity(String universityName, String currentApplicationId) {
    return _applications
        .where((a) =>
            a.id != currentApplicationId &&
            a.universityName.trim().toLowerCase() == universityName.trim().toLowerCase())
        .toList();
  }

  // --- Filter Setters ---
  void setSelectedCountry(String? country) {
    _selectedCountry = country;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setDegreeFilter(String? degree) {
    _degreeFilter = degree;
    notifyListeners();
  }

  void setIntakeFilter(String? intake) {
    _intakeFilter = intake;
    notifyListeners();
  }

  void setPriorityFilter(String? priority) {
    _priorityFilter = priority;
    notifyListeners();
  }

  void setIeltsMetFilter(bool? met) {
    _ieltsMetFilter = met;
    notifyListeners();
  }

  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    notifyListeners();
  }

  void setStatFilter(String? stat) {
    if (_statFilter == stat) {
      _statFilter = null; // Toggle off if clicked again
    } else {
      _statFilter = stat;
    }
    notifyListeners();
  }

  void setSort(String field, {bool? ascending}) {
    if (_sortBy == field && ascending == null) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = field;
      if (ascending != null) _sortAscending = ascending;
    }
    notifyListeners();
  }

  void resetFilters() {
    _selectedCountry = null;
    _searchQuery = '';
    _statusFilter = null;
    _degreeFilter = null;
    _intakeFilter = null;
    _priorityFilter = null;
    _ieltsMetFilter = null;
    _favoritesOnly = false;
    _statFilter = null;
    _sortBy = 'deadline';
    _sortAscending = true;
    notifyListeners();
  }

  // --- Comparison Management ---
  void toggleComparison(String id) {
    if (_comparisonIds.contains(id)) {
      _comparisonIds.remove(id);
    } else {
      if (_comparisonIds.length >= 5) {
        // Max 5
        return;
      }
      _comparisonIds.add(id);
    }
    notifyListeners();
  }

  void clearComparison() {
    _comparisonIds.clear;
    _comparisonIds.clear();
    notifyListeners();
  }

  // --- CRUD Applications ---
  Future<void> addApplication(ApplicationModel application) async {
    _isSaving = true;
    notifyListeners();

    try {
      final nowStr = DateTime.now().toIso8601String().substring(0, 10);
      final newApp = application.copyWith(
        createdDate: nowStr,
        lastUpdated: nowStr,
      );
      _applications.add(newApp);
      await _repository.saveApplications(_applications);

      // Add initial Status History event
      final initialHistory = StatusHistoryModel(
        id: _uuid.v4(),
        applicationId: newApp.id,
        date: nowStr,
        previousStatus: '',
        newStatus: newApp.status,
        event: 'Application Created',
        notes: 'Application registered in tracking system.',
      );
      _statusHistories.add(initialHistory);
      await _repository.saveStatusHistory(_statusHistories);

      // Auto-create standard document checklist
      for (final docName in DocumentModel.standardDocumentNames) {
        final doc = DocumentModel(
          id: _uuid.v4(),
          applicationId: newApp.id,
          document: docName,
          required: true,
          completed: false,
          submitted: false,
        );
        _documents.add(doc);
      }
      await _repository.saveDocuments(_documents);
      await _syncCountryStats();
    } catch (e) {
      _errorMessage = "Failed to save application: $e";
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateApplication(ApplicationModel application) async {
    _isSaving = true;
    notifyListeners();

    try {
      final index = _applications.indexWhere((a) => a.id == application.id);
      if (index >= 0) {
        final oldApp = _applications[index];
        final nowStr = DateTime.now().toIso8601String().substring(0, 10);

        // Track status changes automatically in Status History
        if (oldApp.status != application.status) {
          final historyItem = StatusHistoryModel(
            id: _uuid.v4(),
            applicationId: application.id,
            date: nowStr,
            previousStatus: oldApp.status,
            newStatus: application.status,
            event: 'Status changed to ${application.status}',
            notes: 'Updated manually by user.',
          );
          _statusHistories.add(historyItem);
          await _repository.saveStatusHistory(_statusHistories);
        }

        final updated = application.copyWith(lastUpdated: nowStr);
        _applications[index] = updated;
        await _repository.saveApplications(_applications);
        await _syncCountryStats();
      }
    } catch (e) {
      _errorMessage = "Failed to update application: $e";
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<ApplicationModel> duplicateApplication(
    String sourceApplicationId, {
    String? newCourseName,
    String? newSemesterYear,
    String? newIntake,
    String? newStatus,
    bool copyDocuments = true,
    bool copyScholarships = true,
    bool copyContacts = true,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final source = _applications.firstWhere(
        (a) => a.id == sourceApplicationId,
        orElse: () => throw Exception("Source application not found"),
      );

      final nowStr = DateTime.now().toIso8601String().substring(0, 10);
      final newId = _uuid.v4();

      final targetCourse = newCourseName?.trim().isNotEmpty == true
          ? newCourseName!.trim()
          : '${source.courseName} (Copy)';

      final duplicatedApp = source.copyWith(
        id: newId,
        courseName: targetCourse,
        semesterYear: newSemesterYear?.trim().isNotEmpty == true
            ? newSemesterYear!.trim()
            : source.semesterYear,
        intake: newIntake?.trim().isNotEmpty == true
            ? newIntake!.trim()
            : source.intake,
        status: newStatus?.trim().isNotEmpty == true
            ? newStatus!.trim()
            : 'Researching',
        createdDate: nowStr,
        lastUpdated: nowStr,
        isFavorite: false,
      );

      _applications.add(duplicatedApp);
      await _repository.saveApplications(_applications);

      // 1. Initial Status History for the duplicated app
      final initialHistory = StatusHistoryModel(
        id: _uuid.v4(),
        applicationId: newId,
        date: nowStr,
        previousStatus: '',
        newStatus: duplicatedApp.status,
        event: 'Duplicated from ${source.courseName}',
        notes: 'Application duplicated from existing application record.',
      );
      _statusHistories.add(initialHistory);
      await _repository.saveStatusHistory(_statusHistories);

      // 2. Copy Documents
      if (copyDocuments) {
        final sourceDocs = getDocumentsFor(source.id);
        if (sourceDocs.isNotEmpty) {
          for (final doc in sourceDocs) {
            _documents.add(DocumentModel(
              id: _uuid.v4(),
              applicationId: newId,
              document: doc.document,
              required: doc.required,
              completed: false,
              submitted: false,
              notes: doc.notes,
            ));
          }
        } else {
          for (final docName in DocumentModel.standardDocumentNames) {
            _documents.add(DocumentModel(
              id: _uuid.v4(),
              applicationId: newId,
              document: docName,
              required: true,
              completed: false,
              submitted: false,
            ));
          }
        }
        await _repository.saveDocuments(_documents);
      }

      // 3. Copy Scholarships
      if (copyScholarships) {
        final sourceScholarships = getScholarshipsFor(source.id);
        for (final s in sourceScholarships) {
          _scholarships.add(ScholarshipModel(
            id: _uuid.v4(),
            applicationId: newId,
            scholarshipName: s.scholarshipName,
            amount: s.amount,
            deadline: s.deadline,
            eligibility: s.eligibility,
            status: 'Considering',
            notes: s.notes,
          ));
        }
        if (sourceScholarships.isNotEmpty) {
          await _repository.saveScholarships(_scholarships);
        }
      }

      // 4. Copy Contacts
      if (copyContacts) {
        final sourceContacts = getContactsFor(source.id);
        for (final c in sourceContacts) {
          _contacts.add(ContactModel(
            id: _uuid.v4(),
            applicationId: newId,
            department: c.department,
            contactPerson: c.contactPerson,
            email: c.email,
            phone: c.phone,
            notes: c.notes,
          ));
        }
        if (sourceContacts.isNotEmpty) {
          await _repository.saveContacts(_contacts);
        }
      }

      await _syncCountryStats();
      return duplicatedApp;
    } catch (e) {
      _errorMessage = "Failed to duplicate application: $e";
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteApplication(String id) async {
    _isSaving = true;
    notifyListeners();

    try {
      _applications.removeWhere((a) => a.id == id);
      _statusHistories.removeWhere((h) => h.applicationId == id);
      _documents.removeWhere((d) => d.applicationId == id);
      _scholarships.removeWhere((s) => s.applicationId == id);
      _contacts.removeWhere((c) => c.applicationId == id);
      _comparisonIds.remove(id);

      await _repository.deleteApplication(id);
      await _syncCountryStats();
    } catch (e) {
      _errorMessage = "Failed to delete application: $e";
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String id) async {
    final index = _applications.indexWhere((a) => a.id == id);
    if (index >= 0) {
      final app = _applications[index];
      final updated = app.copyWith(isFavorite: !app.isFavorite);
      _applications[index] = updated;
      notifyListeners();
      await _repository.saveApplications(_applications);
    }
  }

  // --- Sub-Entity CRUD: Documents ---
  List<DocumentModel> getDocumentsFor(String applicationId) {
    return _documents.where((d) => d.applicationId == applicationId).toList();
  }

  Future<void> toggleDocumentCompleted(String documentId) async {
    final idx = _documents.indexWhere((d) => d.id == documentId);
    if (idx >= 0) {
      final doc = _documents[idx];
      _documents[idx] = doc.copyWith(completed: !doc.completed);
      notifyListeners();
      await _repository.saveDocuments(_documents);
    }
  }

  Future<void> toggleDocumentSubmitted(String documentId) async {
    final idx = _documents.indexWhere((d) => d.id == documentId);
    if (idx >= 0) {
      final doc = _documents[idx];
      _documents[idx] = doc.copyWith(submitted: !doc.submitted);
      notifyListeners();
      await _repository.saveDocuments(_documents);
    }
  }

  Future<void> addDocument(DocumentModel doc) async {
    _documents.add(doc);
    notifyListeners();
    await _repository.saveDocuments(_documents);
  }

  Future<void> deleteDocument(String docId) async {
    _documents.removeWhere((d) => d.id == docId);
    notifyListeners();
    await _repository.saveDocuments(_documents);
  }

  // --- Sub-Entity CRUD: Status History ---
  List<StatusHistoryModel> getStatusHistoriesFor(String applicationId) {
    final list = _statusHistories.where((h) => h.applicationId == applicationId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> addStatusHistoryEvent(StatusHistoryModel item) async {
    _statusHistories.add(item);
    notifyListeners();
    await _repository.saveStatusHistory(_statusHistories);
  }

  // --- Sub-Entity CRUD: Scholarships ---
  List<ScholarshipModel> getScholarshipsFor(String applicationId) {
    return _scholarships.where((s) => s.applicationId == applicationId).toList();
  }

  Future<void> addScholarship(ScholarshipModel scholarship) async {
    _scholarships.add(scholarship);
    notifyListeners();
    await _repository.saveScholarships(_scholarships);
  }

  Future<void> updateScholarship(ScholarshipModel scholarship) async {
    final idx = _scholarships.indexWhere((s) => s.id == scholarship.id);
    if (idx >= 0) {
      _scholarships[idx] = scholarship;
      notifyListeners();
      await _repository.saveScholarships(_scholarships);
    }
  }

  Future<void> deleteScholarship(String id) async {
    _scholarships.removeWhere((s) => s.id == id);
    notifyListeners();
    await _repository.saveScholarships(_scholarships);
  }

  // --- Sub-Entity CRUD: Contacts ---
  List<ContactModel> getContactsFor(String applicationId) {
    return _contacts.where((c) => c.applicationId == applicationId).toList();
  }

  Future<void> addContact(ContactModel contact) async {
    _contacts.add(contact);
    notifyListeners();
    await _repository.saveContacts(_contacts);
  }

  Future<void> updateContact(ContactModel contact) async {
    final idx = _contacts.indexWhere((c) => c.id == contact.id);
    if (idx >= 0) {
      _contacts[idx] = contact;
      notifyListeners();
      await _repository.saveContacts(_contacts);
    }
  }

  Future<void> deleteContact(String id) async {
    _contacts.removeWhere((c) => c.id == id);
    notifyListeners();
    await _repository.saveContacts(_contacts);
  }

  // --- Sub-Entity CRUD: Emails ---
  Future<void> addEmail(EmailAccountModel email) async {
    _emails.add(email);
    notifyListeners();
    await _repository.saveEmails(_emails);
  }

  Future<void> deleteEmail(String id) async {
    _emails.removeWhere((e) => e.id == id);
    notifyListeners();
    await _repository.saveEmails(_emails);
  }
}
