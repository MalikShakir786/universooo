import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../controllers/application_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/application_model.dart';
import '../models/country_stat_model.dart';
import '../theme/app_theme.dart';
import 'add_country_dialog.dart';

class ApplicationFormDialog extends StatefulWidget {
  final ApplicationModel? initialApplication;
  final bool isDuplicate;
  final Function(ApplicationModel)? onOpenExisting;

  const ApplicationFormDialog({
    super.key,
    this.initialApplication,
    this.isDuplicate = false,
    this.onOpenExisting,
  });

  static Future<void> show(
    BuildContext context, {
    ApplicationModel? application,
    bool isDuplicate = false,
    Function(ApplicationModel)? onOpenExisting,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ApplicationFormDialog(
        initialApplication: application,
        isDuplicate: isDuplicate,
        onOpenExisting: onOpenExisting,
      ),
    );
  }

  @override
  State<ApplicationFormDialog> createState() => _ApplicationFormDialogState();
}

class _ApplicationFormDialogState extends State<ApplicationFormDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Form Fields
  late String _id;
  late TextEditingController _universityController;
  late TextEditingController _cityController;
  late TextEditingController _websiteController;
  late TextEditingController _courseController;
  late TextEditingController _facultyController;
  late TextEditingController _programWebsiteController;
  late TextEditingController _durationController;
  late TextEditingController _creditsController;
  late TextEditingController _languageController;
  late TextEditingController _semesterYearController;

  // Deadlines
  late TextEditingController _appDeadlineController;
  late TextEditingController _earlyDeadlineController;
  late TextEditingController _scholarshipDeadlineController;
  late TextEditingController _housingDeadlineController;
  late TextEditingController _visaDeadlineController;
  late TextEditingController _decisionDateController;
  late TextEditingController _applicationDateController;

  // Language & Academics
  late TextEditingController _ieltsOverallController;
  late TextEditingController _ieltsListeningController;
  late TextEditingController _ieltsReadingController;
  late TextEditingController _ieltsWritingController;
  late TextEditingController _ieltsSpeakingController;
  late TextEditingController _myIeltsScoreController;
  late TextEditingController _toeflController;
  late TextEditingController _pteController;
  late TextEditingController _gpaRequiredController;
  late TextEditingController _myGpaController;
  late TextEditingController _greController;
  late TextEditingController _gmatController;

  // Costs & Finances
  late TextEditingController _appFeeController;
  late TextEditingController _tuitionFeeController;
  late TextEditingController _livingCostController;
  late TextEditingController _scholarshipAmountController;

  // Reviews & Notes
  late TextEditingController _prosController;
  late TextEditingController _consController;
  late TextEditingController _personalReviewController;
  late TextEditingController _generalNotesController;

  // Selectable Dropdowns & Toggles
  String _selectedCountry = '';
  String _degreeLevel = "Master's";
  String _studyMode = 'On Campus';
  String _intake = 'Fall';
  String _status = 'Researching';
  String _priority = 'Medium';
  String _selectedEmail = '';
  bool _isFavorite = false;

  // Requirements Toggles
  bool _ieltsRequired = false;
  bool _sopRequired = true;
  bool _cvRequired = true;
  bool _recommendationRequired = true;
  bool _portfolioRequired = false;
  bool _interviewRequired = false;

  // Ratings
  double _universityRating = 4.0;
  double _academicRating = 4.0;
  double _costRating = 3.5;
  double _locationRating = 4.0;
  double _careerRating = 4.0;
  double _studentLifeRating = 4.0;

  final List<String> _statusOptions = [
    'Researching',
    'Interested',
    'Shortlisted',
    'Preparing',
    'Documents Pending',
    'Ready to Apply',
    'Applied',
    'Under Review',
    'Interview',
    'Conditional Offer',
    'Unconditional Offer',
    'Accepted',
    'Rejected',
    'Waitlisted',
    'Withdrawn',
  ];

  final List<String> _degreeOptions = [
    "Bachelor's",
    "Master's",
    'PhD',
    'Diploma',
    'Other',
  ];

  final List<String> _intakeOptions = [
    'Fall',
    'Spring',
    'Summer',
    'Winter',
    'Other',
  ];

  final List<String> _priorityOptions = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    final app = widget.initialApplication;

    _id = widget.isDuplicate ? const Uuid().v4() : (app?.id ?? const Uuid().v4());
    _universityController = TextEditingController(text: app?.universityName ?? '');
    _cityController = TextEditingController(text: app?.city ?? '');
    _websiteController = TextEditingController(text: app?.universityWebsite ?? '');
    _courseController = TextEditingController(
      text: app != null
          ? (widget.isDuplicate
              ? (app.courseName.contains('(Copy)') ? app.courseName : '${app.courseName} (Copy)')
              : app.courseName)
          : '',
    );
    _facultyController = TextEditingController(text: app?.faculty ?? '');
    _programWebsiteController = TextEditingController(text: app?.programWebsite ?? '');
    _durationController = TextEditingController(text: app?.duration ?? '2 Years');
    _creditsController = TextEditingController(text: app?.credits ?? '120 ECTS');
    _languageController = TextEditingController(text: app?.language ?? 'English');
    _semesterYearController = TextEditingController(text: app?.semesterYear ?? '2026');

    _appDeadlineController = TextEditingController(text: app?.applicationDeadline ?? '');
    _earlyDeadlineController = TextEditingController(text: app?.earlyDeadline ?? '');
    _scholarshipDeadlineController = TextEditingController(text: app?.scholarshipDeadline ?? '');
    _housingDeadlineController = TextEditingController(text: app?.housingDeadline ?? '');
    _visaDeadlineController = TextEditingController(text: app?.visaDeadline ?? '');
    _decisionDateController = TextEditingController(text: app?.decisionDate ?? '');
    _applicationDateController = TextEditingController(text: app?.applicationDate ?? '');

    _ieltsOverallController = TextEditingController(
        text: (app?.ieltsOverallRequired ?? 0) > 0 ? app!.ieltsOverallRequired.toString() : '6.5');
    _ieltsListeningController = TextEditingController(
        text: (app?.ieltsListeningRequired ?? 0) > 0 ? app!.ieltsListeningRequired.toString() : '6.0');
    _ieltsReadingController = TextEditingController(
        text: (app?.ieltsReadingRequired ?? 0) > 0 ? app!.ieltsReadingRequired.toString() : '6.0');
    _ieltsWritingController = TextEditingController(
        text: (app?.ieltsWritingRequired ?? 0) > 0 ? app!.ieltsWritingRequired.toString() : '6.0');
    _ieltsSpeakingController = TextEditingController(
        text: (app?.ieltsSpeakingRequired ?? 0) > 0 ? app!.ieltsSpeakingRequired.toString() : '6.0');
    _myIeltsScoreController = TextEditingController(
        text: (app?.myIeltsScore ?? 0) > 0 ? app!.myIeltsScore.toString() : '7.5');
    _toeflController = TextEditingController(text: app?.toeflRequired ?? '');
    _pteController = TextEditingController(text: app?.pteRequired ?? '');

    _gpaRequiredController = TextEditingController(
        text: (app?.gpaRequired ?? 0) > 0 ? app!.gpaRequired.toString() : '3.0');
    _myGpaController = TextEditingController(
        text: (app?.myGpa ?? 0) > 0 ? app!.myGpa.toString() : '3.7');
    _greController = TextEditingController(text: app?.greRequired ?? '');
    _gmatController = TextEditingController(text: app?.gmatRequired ?? '');

    _appFeeController = TextEditingController(
        text: (app?.applicationFee ?? 0) > 0 ? app!.applicationFee.toString() : '');
    _tuitionFeeController = TextEditingController(
        text: (app?.tuitionFee ?? 0) > 0 ? app!.tuitionFee.toString() : '');
    _livingCostController = TextEditingController(
        text: (app?.livingCost ?? 0) > 0 ? app!.livingCost.toString() : '');
    _scholarshipAmountController = TextEditingController(
        text: (app?.scholarshipAmount ?? 0) > 0 ? app!.scholarshipAmount.toString() : '');

    _prosController = TextEditingController(text: app?.pros ?? '');
    _consController = TextEditingController(text: app?.cons ?? '');
    _personalReviewController = TextEditingController(text: app?.personalReview ?? '');
    _generalNotesController = TextEditingController(text: app?.generalNotes ?? '');

    if (app != null) {
      _selectedCountry = app.country;
      _degreeLevel = app.degreeLevel;
      _studyMode = app.studyMode;
      _intake = app.intake;
      _status = app.status;
      _priority = app.priority;
      _selectedEmail = app.applicationEmail;
      _isFavorite = app.isFavorite;

      _ieltsRequired = app.ieltsRequired;
      _sopRequired = app.sopRequired;
      _cvRequired = app.cvRequired;
      _recommendationRequired = app.recommendationRequired;
      _portfolioRequired = app.portfolioRequired;
      _interviewRequired = app.interviewRequired;

      _universityRating = app.universityRating;
      _academicRating = app.academicRating;
      _costRating = app.costRating;
      _locationRating = app.locationRating;
      _careerRating = app.careerRating;
      _studentLifeRating = app.studentLifeRating;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCountry.isEmpty && (widget.initialApplication == null || widget.isDuplicate)) {
      if (widget.isDuplicate && widget.initialApplication != null) {
        _selectedCountry = widget.initialApplication!.country;
      } else {
        final appCtrl = Provider.of<ApplicationController>(context, listen: false);
        if (appCtrl.availableCountries.isNotEmpty) {
          _selectedCountry = appCtrl.availableCountries.first;
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _universityController.dispose();
    _cityController.dispose();
    _websiteController.dispose();
    _courseController.dispose();
    _facultyController.dispose();
    _programWebsiteController.dispose();
    _durationController.dispose();
    _creditsController.dispose();
    _languageController.dispose();
    _semesterYearController.dispose();
    _appDeadlineController.dispose();
    _earlyDeadlineController.dispose();
    _scholarshipDeadlineController.dispose();
    _housingDeadlineController.dispose();
    _visaDeadlineController.dispose();
    _decisionDateController.dispose();
    _applicationDateController.dispose();
    _ieltsOverallController.dispose();
    _ieltsListeningController.dispose();
    _ieltsReadingController.dispose();
    _ieltsWritingController.dispose();
    _ieltsSpeakingController.dispose();
    _myIeltsScoreController.dispose();
    _toeflController.dispose();
    _pteController.dispose();
    _gpaRequiredController.dispose();
    _myGpaController.dispose();
    _greController.dispose();
    _gmatController.dispose();
    _appFeeController.dispose();
    _tuitionFeeController.dispose();
    _livingCostController.dispose();
    _scholarshipAmountController.dispose();
    _prosController.dispose();
    _consController.dispose();
    _personalReviewController.dispose();
    _generalNotesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initial = DateTime.now();
    if (controller.text.isNotEmpty) {
      try {
        initial = DateTime.parse(controller.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      controller.text = picked.toIso8601String().substring(0, 10);
    }
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appController = Provider.of<ApplicationController>(context, listen: false);

    // Duplicate Check
    final isEditing = widget.initialApplication != null && !widget.isDuplicate;
    final duplicate = appController.checkDuplicate(
      _universityController.text,
      _courseController.text,
      _semesterYearController.text,
      excludeId: isEditing ? widget.initialApplication!.id : null,
    );

    if (duplicate != null) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.macosOrange),
              SizedBox(width: 8),
              Text('Possible Duplicate Detected'),
            ],
          ),
          content: Text(
            'An application for "${_universityController.text}" - "${_courseController.text}" in ${_semesterYearController.text} already exists.\n\nWhat would you like to do?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop('open_existing'),
              child: const Text('Open Existing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('create_anyway'),
              child: const Text('Create Anyway'),
            ),
          ],
        ),
      );

      if (choice == 'cancel' || choice == null) {
        return;
      } else if (choice == 'open_existing') {
        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onOpenExisting?.call(duplicate);
        return;
      }
    }

    final application = ApplicationModel(
      id: _id,
      universityName: _universityController.text.trim(),
      country: _selectedCountry,
      city: _cityController.text.trim(),
      universityWebsite: _websiteController.text.trim(),
      courseName: _courseController.text.trim(),
      degreeLevel: _degreeLevel,
      faculty: _facultyController.text.trim(),
      programWebsite: _programWebsiteController.text.trim(),
      studyMode: _studyMode,
      duration: _durationController.text.trim(),
      credits: _creditsController.text.trim(),
      language: _languageController.text.trim(),
      intake: _intake,
      semesterYear: _semesterYearController.text.trim(),
      applicationDeadline: _appDeadlineController.text.trim(),
      earlyDeadline: _earlyDeadlineController.text.trim(),
      scholarshipDeadline: _scholarshipDeadlineController.text.trim(),
      housingDeadline: _housingDeadlineController.text.trim(),
      visaDeadline: _visaDeadlineController.text.trim(),
      decisionDate: _decisionDateController.text.trim(),
      applicationDate: _applicationDateController.text.trim(),
      status: _status,
      priority: _priority,
      applicationEmail: _selectedEmail.trim(),
      isFavorite: _isFavorite,
      applicationFee: double.tryParse(_appFeeController.text) ?? 0.0,
      tuitionFee: double.tryParse(_tuitionFeeController.text) ?? 0.0,
      livingCost: double.tryParse(_livingCostController.text) ?? 0.0,
      scholarshipAmount: double.tryParse(_scholarshipAmountController.text) ?? 0.0,
      ieltsRequired: _ieltsRequired,
      ieltsOverallRequired: double.tryParse(_ieltsOverallController.text) ?? 0.0,
      ieltsListeningRequired: double.tryParse(_ieltsListeningController.text) ?? 0.0,
      ieltsReadingRequired: double.tryParse(_ieltsReadingController.text) ?? 0.0,
      ieltsWritingRequired: double.tryParse(_ieltsWritingController.text) ?? 0.0,
      ieltsSpeakingRequired: double.tryParse(_ieltsSpeakingController.text) ?? 0.0,
      myIeltsScore: double.tryParse(_myIeltsScoreController.text) ?? 0.0,
      ieltsStatus: _ieltsRequired
          ? ((double.tryParse(_myIeltsScoreController.text) ?? 0) >=
                  (double.tryParse(_ieltsOverallController.text) ?? 0)
              ? 'Requirement Met'
              : 'Requirement Not Met')
          : 'Not Required',
      toeflRequired: _toeflController.text.trim(),
      pteRequired: _pteController.text.trim(),
      gpaRequired: double.tryParse(_gpaRequiredController.text) ?? 0.0,
      myGpa: double.tryParse(_myGpaController.text) ?? 0.0,
      greRequired: _greController.text.trim(),
      gmatRequired: _gmatController.text.trim(),
      sopRequired: _sopRequired,
      cvRequired: _cvRequired,
      recommendationRequired: _recommendationRequired,
      portfolioRequired: _portfolioRequired,
      interviewRequired: _interviewRequired,
      universityRating: _universityRating,
      academicRating: _academicRating,
      costRating: _costRating,
      locationRating: _locationRating,
      careerRating: _careerRating,
      studentLifeRating: _studentLifeRating,
      pros: _prosController.text.trim(),
      cons: _consController.text.trim(),
      personalReview: _personalReviewController.text.trim(),
      generalNotes: _generalNotesController.text.trim(),
      createdDate: widget.initialApplication?.createdDate ?? '',
      lastUpdated: widget.initialApplication?.lastUpdated ?? '',
    );

    if (isEditing) {
      await appController.updateApplication(application);
    } else {
      await appController.addApplication(application);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialApplication != null && !widget.isDuplicate;
    final appController = Provider.of<ApplicationController>(context);
    final emails = appController.emails;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E2129) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        height: 680,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.macosBlue.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.isDuplicate
                              ? Icons.copy_all_outlined
                              : (isEditing ? Icons.edit_note : Icons.add_circle_outline),
                          color: AppTheme.macosBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isDuplicate
                                ? 'Duplicate Application: ${widget.initialApplication?.universityName ?? ''}'
                                : (isEditing ? 'Edit Application' : 'Add University Application'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.isDuplicate
                                ? 'Create a new application copying details from existing record'
                                : (isEditing
                                    ? 'Update application details and requirements'
                                    : 'Track a new program, university deadlines, and requirements'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Toggle Favorite',
                        icon: Icon(
                          _isFavorite ? Icons.star : Icons.star_border,
                          color: _isFavorite ? Colors.amber : null,
                        ),
                        onPressed: () => setState(() => _isFavorite = !_isFavorite),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppTheme.macosBlue,
                unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                indicatorColor: AppTheme.macosBlue,
                tabs: const [
                  Tab(text: '1. University & Program'),
                  Tab(text: '2. Deadlines & Status'),
                  Tab(text: '3. Language & Academics'),
                  Tab(text: '4. Costs & Email'),
                  Tab(text: '5. Reviews & Notes'),
                ],
              ),
              const SizedBox(height: 16),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: University & Program
                    _buildUniversityTab(isDark),

                    // Tab 2: Deadlines & Status
                    _buildDeadlinesTab(isDark),

                    // Tab 3: Language & Academics
                    _buildLanguageAcademicTab(isDark),

                    // Tab 4: Costs & Email
                    _buildCostsTab(isDark, emails),

                    // Tab 5: Reviews & Notes
                    _buildReviewsTab(isDark),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🔒 All data saves locally to university_applications.xlsx',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.macosBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(
                          widget.isDuplicate
                              ? 'Create Duplicate'
                              : (isEditing ? 'Update Application' : 'Save Application'),
                        ),
                        onPressed: _saveForm,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: University & Program ---
  Widget _buildUniversityTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _universityController,
                  decoration: const InputDecoration(
                    labelText: 'University Name *',
                    hintText: 'e.g. Technical University of Munich',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'University name is required' : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Consumer<ApplicationController>(
                  builder: (context, appCtrl, _) {
                    final countries = <String>{
                      ...appCtrl.availableCountries,
                      if (_selectedCountry.isNotEmpty) _selectedCountry,
                    }.toList();

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: countries.contains(_selectedCountry) ? _selectedCountry : null,
                            decoration: const InputDecoration(
                              labelText: 'Country *',
                              hintText: 'Select or add country',
                            ),
                            items: [
                              ...countries.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Row(
                                    children: [
                                      Text(CountryStatModel.getFlag(c)),
                                      const SizedBox(width: 8),
                                      Text(c),
                                    ],
                                  ),
                                );
                              }),
                              const DropdownMenuItem(
                                value: '__ADD_NEW__',
                                child: Row(
                                  children: [
                                    Icon(Icons.add, size: 16, color: AppTheme.macosBlue),
                                    SizedBox(width: 6),
                                    Text(
                                      '+ Add Country...',
                                      style: TextStyle(
                                        color: AppTheme.macosBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (val) async {
                              if (val == '__ADD_NEW__') {
                                final added = await showAddCountryDialog(context);
                                if (added != null && mounted) {
                                  setState(() => _selectedCountry = added);
                                }
                              } else if (val != null) {
                                setState(() => _selectedCountry = val);
                              }
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty || val == '__ADD_NEW__') {
                                return 'Please select or add a country';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppTheme.macosBlue),
                          tooltip: 'Add New Country',
                          onPressed: () async {
                            final added = await showAddCountryDialog(context);
                            if (added != null && mounted) {
                              setState(() => _selectedCountry = added);
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    hintText: 'e.g. Munich',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'University Website',
                    hintText: 'https://...',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),
          const Text('Course & Program Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _courseController,
                  decoration: const InputDecoration(
                    labelText: 'Course / Program Name *',
                    hintText: 'e.g. M.Sc. Computer Science',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Course name is required' : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _degreeLevel,
                  decoration: const InputDecoration(labelText: 'Degree Level'),
                  items: _degreeOptions.map((d) {
                    return DropdownMenuItem(value: d, child: Text(d));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _degreeLevel = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _facultyController,
                  decoration: const InputDecoration(
                    labelText: 'Faculty / Department',
                    hintText: 'Department of Computer Science',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _programWebsiteController,
                  decoration: const InputDecoration(
                    labelText: 'Program Website',
                    hintText: 'https://...',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _studyMode,
                  decoration: const InputDecoration(labelText: 'Study Mode'),
                  items: const [
                    DropdownMenuItem(value: 'On Campus', child: Text('On Campus')),
                    DropdownMenuItem(value: 'Online', child: Text('Online')),
                    DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _studyMode = val);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    hintText: 'e.g. 2 Years',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _creditsController,
                  decoration: const InputDecoration(
                    labelText: 'Credits',
                    hintText: 'e.g. 120 ECTS',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _languageController,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    hintText: 'e.g. English',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Deadlines & Status ---
  Widget _buildDeadlinesTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Application Status'),
                  items: _statusOptions.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: _priorityOptions.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _priority = val);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _intake,
                  decoration: const InputDecoration(labelText: 'Intake'),
                  items: _intakeOptions.map((i) {
                    return DropdownMenuItem(value: i, child: Text(i));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _intake = val);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _semesterYearController,
                  decoration: const InputDecoration(
                    labelText: 'Intake Year',
                    hintText: '2026',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),
          const Text('Key Deadlines (YYYY-MM-DD)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _appDeadlineController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Application Deadline',
                    hintText: 'Select date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: () => _selectDate(context, _appDeadlineController),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _earlyDeadlineController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Early Deadline',
                    hintText: 'Select date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: () => _selectDate(context, _earlyDeadlineController),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _scholarshipDeadlineController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Scholarship Deadline',
                    hintText: 'Select date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: () => _selectDate(context, _scholarshipDeadlineController),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _housingDeadlineController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Housing Deadline',
                    hintText: 'Select date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: () => _selectDate(context, _housingDeadlineController),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _visaDeadlineController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Visa Deadline',
                    hintText: 'Select date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: () => _selectDate(context, _visaDeadlineController),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _decisionDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Decision Expected Date',
                    hintText: 'Select date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: () => _selectDate(context, _decisionDateController),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _applicationDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Application Date (When Submitted)',
                    hintText: 'Select date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: () => _selectDate(context, _applicationDateController),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 3: Language & Academics ---
  Widget _buildLanguageAcademicTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('English Language Requirements',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Row(
                children: [
                  const Text('IELTS Required?'),
                  Switch(
                    value: _ieltsRequired,
                    onChanged: (val) => setState(() => _ieltsRequired = val),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_ieltsRequired) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ieltsOverallController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Overall Min (e.g. 6.5)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _ieltsListeningController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Listening Min'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _ieltsReadingController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Reading Min'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _ieltsWritingController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Writing Min'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _ieltsSpeakingController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Speaking Min'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _myIeltsScoreController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'My Score',
                      fillColor: Color(0xFFEFF6FF),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _toeflController,
                  decoration: const InputDecoration(
                    labelText: 'TOEFL Requirement (Optional)',
                    hintText: 'e.g. 90 overall, 20 each',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _pteController,
                  decoration: const InputDecoration(
                    labelText: 'PTE Requirement (Optional)',
                    hintText: 'e.g. 65 overall',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),
          const Text('Academic & Document Requirements',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _gpaRequiredController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Required GPA'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _myGpaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'My Current GPA'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _greController,
                  decoration: const InputDecoration(labelText: 'GRE Requirement (if any)'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _gmatController,
                  decoration: const InputDecoration(labelText: 'GMAT Requirement (if any)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildCheckbox('Statement of Purpose (SOP)', _sopRequired,
                  (v) => setState(() => _sopRequired = v ?? false)),
              _buildCheckbox('Curriculum Vitae (CV)', _cvRequired,
                  (v) => setState(() => _cvRequired = v ?? false)),
              _buildCheckbox('Letters of Recommendation', _recommendationRequired,
                  (v) => setState(() => _recommendationRequired = v ?? false)),
              _buildCheckbox('Portfolio / Work Samples', _portfolioRequired,
                  (v) => setState(() => _portfolioRequired = v ?? false)),
              _buildCheckbox('Interview Required', _interviewRequired,
                  (v) => setState(() => _interviewRequired = v ?? false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(value: value, onChanged: onChanged),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  // --- TAB 4: Costs & Email ---
  Widget _buildCostsTab(bool isDark, List<dynamic> savedEmails) {
    final currencySymbol =
        Provider.of<SettingsController>(context, listen: false).settings.currencySymbol;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Application Email Account',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: TextEditingController(text: _selectedEmail),
                  decoration: const InputDecoration(
                    labelText: 'Email Address Used',
                    hintText: 'student@example.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 18),
                  ),
                  onChanged: (val) => _selectedEmail = val,
                ),
              ),
              if (savedEmails.isNotEmpty) ...[
                const SizedBox(width: 14),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Quick Pick Saved Email'),
                    items: savedEmails.map<DropdownMenuItem<String>>((e) {
                      return DropdownMenuItem(
                        value: e.emailAddress,
                        child: Text(e.emailAddress, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedEmail = val);
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),
          Text('Financial Information ($currencySymbol)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _appFeeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Application Fee',
                    prefixText: '$currencySymbol ',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _tuitionFeeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Tuition Fee (Per Year)',
                    prefixText: '$currencySymbol ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _livingCostController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Estimated Living Cost (Per Year)',
                    prefixText: '$currencySymbol ',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _scholarshipAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Scholarship / Waiver Amount',
                    prefixText: '$currencySymbol ',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 5: Reviews & Notes ---
  Widget _buildReviewsTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Star Ratings (1 to 5)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildRatingSlider('Overall Rating', _universityRating,
                      (v) => setState(() => _universityRating = v))),
              const SizedBox(width: 20),
              Expanded(
                  child: _buildRatingSlider('Academic Quality', _academicRating,
                      (v) => setState(() => _academicRating = v))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildRatingSlider('Tuition / Cost Value', _costRating,
                      (v) => setState(() => _costRating = v))),
              const SizedBox(width: 20),
              Expanded(
                  child: _buildRatingSlider('Location / Campus', _locationRating,
                      (v) => setState(() => _locationRating = v))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildRatingSlider('Career Opportunities', _careerRating,
                      (v) => setState(() => _careerRating = v))),
              const SizedBox(width: 20),
              Expanded(
                  child: _buildRatingSlider('Student Life', _studentLifeRating,
                      (v) => setState(() => _studentLifeRating = v))),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _prosController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Pros',
                    hintText: 'Top faculty, low tuition, strong alumni network...',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _consController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Cons',
                    hintText: 'High living cost, harsh winter...',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _personalReviewController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Personal Impression / Opinion',
              hintText: 'My personal thoughts after researching and talking to seniors...',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _generalNotesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'General Application Notes',
              hintText: 'Application portal credentials, portal instructions, follow-up notes...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSlider(String label, double val, Function(double) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label (${val.toStringAsFixed(1)})',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Slider(
            value: val,
            min: 1.0,
            max: 5.0,
            divisions: 8,
            label: val.toStringAsFixed(1),
            activeColor: AppTheme.macosBlue,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
