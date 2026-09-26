import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../controllers/application_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/application_model.dart';
import '../models/contact_model.dart';
import '../models/country_stat_model.dart';
import '../models/document_model.dart';
import '../models/status_history_model.dart';
import '../theme/app_theme.dart';
import '../widgets/application_form_dialog.dart';
import '../widgets/duplicate_application_dialog.dart';
import '../widgets/scholarship_form_dialog.dart';
import '../widgets/status_badge.dart';
import '../widgets/urgency_badge.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final String applicationId;
  final VoidCallback onBack;

  const ApplicationDetailScreen({
    super.key,
    required this.applicationId,
    required this.onBack,
  });

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEventDialog(BuildContext context, ApplicationModel app) {
    final eventCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String newStatus = app.status;
    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add History Event'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: eventCtrl,
                decoration: const InputDecoration(
                  labelText: 'Event Title *',
                  hintText: 'e.g. Interview Invitation Received',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: newStatus,
                decoration: const InputDecoration(labelText: 'Status at this Event'),
                items: [
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
                ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null) newStatus = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes / Description',
                  hintText: 'Additional details...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (eventCtrl.text.trim().isEmpty) return;
              final controller = Provider.of<ApplicationController>(context, listen: false);
              controller.addStatusHistoryEvent(StatusHistoryModel(
                id: const Uuid().v4(),
                applicationId: app.id,
                date: nowStr,
                previousStatus: app.status,
                newStatus: newStatus,
                event: eventCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              ));
              if (newStatus != app.status) {
                controller.updateApplication(app.copyWith(status: newStatus));
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Event'),
          ),
        ],
      ),
    );
  }

  void _showAddDocumentDialog(BuildContext context, String applicationId) {
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isRequired = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Add Document to Checklist'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Document Name *',
                    hintText: 'e.g. Certified Degree Translation',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Requirements',
                    hintText: 'Must be notarized...',
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Required Document'),
                  value: isRequired,
                  onChanged: (v) => setDialogState(() => isRequired = v ?? true),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Provider.of<ApplicationController>(context, listen: false).addDocument(
                  DocumentModel(
                    id: const Uuid().v4(),
                    applicationId: applicationId,
                    document: nameCtrl.text.trim(),
                    required: isRequired,
                    notes: notesCtrl.text.trim(),
                  ),
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('Add Document'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddScholarshipDialog(BuildContext context, String applicationId) {
    showScholarshipFormDialog(
      context,
      initialApplicationId: applicationId,
      lockApplication: true,
    );
  }

  void _showAddContactDialog(BuildContext context, String applicationId) {
    final deptCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add University Contact'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: personCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Person Name',
                  hintText: 'e.g. Dr. Jane Smith',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deptCtrl,
                decoration: const InputDecoration(
                  labelText: 'Department / Office',
                  hintText: 'Admissions Office',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email Address'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes / Office Hours'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Provider.of<ApplicationController>(context, listen: false).addContact(
                ContactModel(
                  id: const Uuid().v4(),
                  applicationId: applicationId,
                  contactPerson: personCtrl.text.trim(),
                  department: deptCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  notes: notesCtrl.text.trim(),
                ),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Contact'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Provider.of<ApplicationController>(context);
    final settings = Provider.of<SettingsController>(context).settings;

    final appIndex = controller.applications.indexWhere((a) => a.id == widget.applicationId);
    if (appIndex < 0) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Application not found or was deleted.'),
              const SizedBox(height: 12),
              FilledButton(onPressed: widget.onBack, child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final app = controller.applications[appIndex];
    final docs = controller.getDocumentsFor(app.id);
    final completedDocs = docs.where((d) => d.completed).length;
    final readiness = app.calculateReadiness(
      documentsTotal: docs.length,
      documentsCompleted: completedDocs,
    );
    final previousApps =
        controller.getPreviousApplicationsForUniversity(app.universityName, app.id);
    final isCompared = controller.comparisonIds.contains(app.id);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121316) : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Top Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2129) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back to Applications'),
                      onPressed: widget.onBack,
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: isCompared ? 'Remove from Comparison' : 'Add to Comparison',
                          icon: Icon(
                            isCompared ? Icons.compare : Icons.compare_arrows,
                            color: isCompared ? AppTheme.macosBlue : null,
                          ),
                          onPressed: () => controller.toggleComparison(app.id),
                        ),
                        IconButton(
                          tooltip: 'Favorite',
                          icon: Icon(
                            app.isFavorite ? Icons.star : Icons.star_border,
                            color: app.isFavorite ? Colors.amber : null,
                          ),
                          onPressed: () => controller.toggleFavorite(app.id),
                        ),
                        IconButton(
                          tooltip: 'Edit Application',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => ApplicationFormDialog.show(context, application: app),
                        ),
                        IconButton(
                          tooltip: 'Duplicate Application',
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: () => showDuplicateApplicationDialog(context, app),
                        ),
                        IconButton(
                          tooltip: 'Delete Application',
                          icon: const Icon(Icons.delete_outline, color: AppTheme.macosRed),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Application?'),
                                content: Text(
                                  'Are you sure you want to delete "${app.universityName} - ${app.courseName}"? This action will safely backup and update the Excel workbook.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.macosRed),
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await controller.deleteApplication(app.id);
                              widget.onBack();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title, Country, Status & Readiness
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                CountryStatModel.getFlag(app.country),
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  app.universityName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${app.courseName} • ${app.degreeLevel} • ${app.intake} ${app.semesterYear}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.play_circle_outline, size: 13, color: AppTheme.macosBlue),
                              const SizedBox(width: 4),
                              Text(
                                'Opens: ${app.startOfApplications.isNotEmpty ? app.startOfApplications : 'Open / Rolling'}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Icon(Icons.event_available, size: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                app.applicationDeadline.isNotEmpty
                                    ? 'Deadline: ${app.applicationDeadline}'
                                    : 'No deadline set',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            StatusBadge(status: app.status, fontSize: 12),
                            const SizedBox(width: 8),
                            UrgencyBadge(
                              urgency: app.urgency,
                              customLabel: app.daysRemainingLabel,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Application Readiness: $readiness%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 90,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: readiness / 100.0,
                                  minHeight: 6,
                                  backgroundColor: isDark
                                      ? const Color(0xFF2E3340)
                                      : const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    readiness >= 80
                                        ? AppTheme.macosGreen
                                        : (readiness >= 50
                                            ? AppTheme.macosBlue
                                            : AppTheme.macosOrange),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Previous Semester Notice Banner (if any exists)
          if (previousApps.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              color: Colors.amber.withAlpha(isDark ? 40 : 25),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Previous Application History Detected: ${previousApps.length} previous record(s) exist for ${app.universityName} (e.g. ${previousApps.first.intake} ${previousApps.first.semesterYear} - ${previousApps.first.status}).',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.amber[200] : Colors.amber[900],
                    ),
                  ),
                ],
              ),
            ),

          // Tabs Navigation Bar
          Container(
            color: isDark ? const Color(0xFF181A20) : const Color(0xFFEBEFF5),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.macosBlue,
              unselectedLabelColor:
                  isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              indicatorColor: AppTheme.macosBlue,
              indicatorWeight: 2.5,
              tabs: [
                const Tab(icon: Icon(Icons.dashboard_outlined, size: 16), text: 'Overview'),
                const Tab(icon: Icon(Icons.check_circle_outline, size: 16), text: 'Requirements'),
                Tab(
                  icon: const Icon(Icons.description_outlined, size: 16),
                  text: 'Documents ($completedDocs/${docs.length})',
                ),
                const Tab(icon: Icon(Icons.calendar_today, size: 16), text: 'Deadlines'),
                const Tab(icon: Icon(Icons.timeline, size: 16), text: 'History'),
                const Tab(icon: Icon(Icons.monetization_on_outlined, size: 16), text: 'Scholarships'),
                const Tab(icon: Icon(Icons.contacts_outlined, size: 16), text: 'Contacts'),
                const Tab(icon: Icon(Icons.star_outline, size: 16), text: 'Review & Rating'),
                const Tab(icon: Icon(Icons.notes, size: 16), text: 'Notes'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, app, isDark, settings.currencySymbol),
                _buildRequirementsTab(context, app, isDark),
                _buildDocumentsTab(context, app, isDark),
                _buildDeadlinesTab(context, app, isDark),
                _buildHistoryTab(context, app, isDark),
                _buildScholarshipsTab(context, app, isDark, settings.currencySymbol),
                _buildContactsTab(context, app, isDark),
                _buildReviewTab(context, app, isDark),
                _buildNotesTab(context, app, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. OVERVIEW TAB ---
  Widget _buildOverviewTab(BuildContext context, ApplicationModel app, bool isDark, String currency) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Key Program Info
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildCard(
                      title: 'Program Specifications',
                      isDark: isDark,
                      child: Column(
                        children: [
                          _buildDetailRow('University', app.universityName),
                          _buildDetailRow('Country / City', '${app.country} ${app.city.isNotEmpty ? '• ${app.city}' : ''}'),
                          _buildDetailRow('Course', app.courseName),
                          _buildDetailRow('Degree Level', app.degreeLevel),
                          _buildDetailRow('Faculty / Dept', app.faculty.isEmpty ? 'Not specified' : app.faculty),
                          _buildDetailRow('Study Mode', app.studyMode),
                          _buildDetailRow('Duration / Credits', '${app.duration} • ${app.credits}'),
                          _buildDetailRow('Instruction Language', app.language),
                          _buildDetailRow('Intake / Semester', '${app.intake} ${app.semesterYear}'),
                          _buildDetailRow('Start of Applications', app.startOfApplications.isEmpty ? 'Open / Rolling' : app.startOfApplications),
                          _buildDetailRow('Application Deadline', app.applicationDeadline.isEmpty ? 'No deadline set' : app.applicationDeadline, isBold: true),
                          _buildDetailRow('Application Email Used', app.applicationEmail.isEmpty ? 'None selected' : app.applicationEmail),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Websites & Admission Portals',
                      isDark: isDark,
                      child: Column(
                        children: [
                          _buildDetailRow('University Website', app.universityWebsite.isEmpty ? 'N/A' : app.universityWebsite),
                          _buildDetailRow('Program Website', app.programWebsite.isEmpty ? 'N/A' : app.programWebsite),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Right Column: Cost Tracking Summary
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildCard(
                      title: 'Cost Tracking ($currency)',
                      isDark: isDark,
                      child: Column(
                        children: [
                          _buildDetailRow('Application Fee', '$currency ${app.applicationFee.toStringAsFixed(0)}'),
                          _buildDetailRow('Tuition (Per Year)', '$currency ${app.tuitionFee.toStringAsFixed(0)}'),
                          _buildDetailRow('Estimated Living Cost', '$currency ${app.livingCost.toStringAsFixed(0)}'),
                          _buildDetailRow('Scholarship / Waiver', '- $currency ${app.scholarshipAmount.toStringAsFixed(0)}', isHighlight: true),
                          const Divider(),
                          _buildDetailRow('Estimated Total Cost', '$currency ${app.estimatedTotalCost.toStringAsFixed(0)}', isBold: true),
                          _buildDetailRow('Estimated Cost / Year', '$currency ${app.estimatedCostPerYear.toStringAsFixed(0)}', isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Personal Star Rating',
                      isDark: isDark,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                app.universityRating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.star, color: Colors.amber, size: 28),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('Academic Quality', '${app.academicRating.toStringAsFixed(1)} ★'),
                          _buildDetailRow('Cost / Value', '${app.costRating.toStringAsFixed(1)} ★'),
                          _buildDetailRow('Location', '${app.locationRating.toStringAsFixed(1)} ★'),
                          _buildDetailRow('Career Opps', '${app.careerRating.toStringAsFixed(1)} ★'),
                          _buildDetailRow('Student Life', '${app.studentLifeRating.toStringAsFixed(1)} ★'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. REQUIREMENTS TAB ---
  Widget _buildRequirementsTab(BuildContext context, ApplicationModel app, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCard(
                  title: 'Academic GPA & Scores',
                  isDark: isDark,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Required GPA', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(app.gpaRequired > 0 ? app.gpaRequired.toString() : 'None',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('My GPA', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(app.myGpa > 0 ? app.myGpa.toString() : 'Not Set',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: app.isGpaMet
                                  ? AppTheme.macosGreen.withAlpha(30)
                                  : AppTheme.macosOrange.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              app.isGpaMet ? '✓ GPA Met' : '⚠ Below Required',
                              style: TextStyle(
                                color: app.isGpaMet ? AppTheme.macosGreen : AppTheme.macosOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      _buildDetailRow('GRE Requirement', app.greRequired.isEmpty ? 'Not Required' : app.greRequired),
                      _buildDetailRow('GMAT Requirement', app.gmatRequired.isEmpty ? 'Not Required' : app.gmatRequired),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildCard(
                  title: 'Required Application Components',
                  isDark: isDark,
                  child: Column(
                    children: [
                      _buildRequirementCheckItem('Statement of Purpose (SOP)', app.sopRequired),
                      _buildRequirementCheckItem('Curriculum Vitae (CV)', app.cvRequired),
                      _buildRequirementCheckItem('Letters of Recommendation', app.recommendationRequired),
                      _buildRequirementCheckItem('Portfolio / Work Samples', app.portfolioRequired),
                      _buildRequirementCheckItem('Interview Required', app.interviewRequired),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. DOCUMENTS TAB ---
  Widget _buildDocumentsTab(BuildContext context, ApplicationModel app, bool isDark) {
    final controller = Provider.of<ApplicationController>(context);
    final docs = controller.getDocumentsFor(app.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Document Checklist (${docs.where((d) => d.completed).length} / ${docs.length} Completed)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.macosBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Document'),
                onPressed: () => _showAddDocumentDialog(context, app.id),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (docs.isEmpty)
            const Text('No documents registered yet. Click "Add Document" to start tracking.')
          else
            _buildCard(
              title: 'Required & Submitted Documents',
              isDark: isDark,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final d = docs[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: Checkbox(
                      value: d.completed,
                      activeColor: AppTheme.macosGreen,
                      onChanged: (_) => controller.toggleDocumentCompleted(d.id),
                    ),
                    title: Text(
                      d.document,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: d.completed ? TextDecoration.lineThrough : null,
                        color: d.completed
                            ? (isDark ? Colors.grey[500] : Colors.grey[600])
                            : null,
                      ),
                    ),
                    subtitle: d.notes.isNotEmpty ? Text(d.notes) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilterChip(
                          label: Text(d.submitted ? 'Submitted ✓' : 'Not Submitted'),
                          selected: d.submitted,
                          selectedColor: AppTheme.macosBlue.withAlpha(40),
                          onSelected: (_) => controller.toggleDocumentSubmitted(d.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => controller.deleteDocument(d.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // --- 4. DEADLINES TAB ---
  Widget _buildDeadlinesTab(BuildContext context, ApplicationModel app, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: 'All Key Deadlines & Application Period',
            isDark: isDark,
            child: Column(
              children: [
                _buildDeadlineRow('Start of Applications', app.startOfApplications, ApplicationUrgency.none),
                _buildDeadlineRow('Primary Application Deadline', app.applicationDeadline, app.urgency, isPrimary: true),
                _buildDeadlineRow('Scholarship Deadline', app.scholarshipDeadline, ApplicationUrgency.none),
                _buildDeadlineRow('Housing Deadline', app.housingDeadline, ApplicationUrgency.none),
                _buildDeadlineRow('Visa Application Deadline', app.visaDeadline, ApplicationUrgency.none),
                _buildDeadlineRow('Decision Expected Date', app.decisionDate, ApplicationUrgency.none),
                _buildDeadlineRow('Application Submitted Date', app.applicationDate, ApplicationUrgency.none),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. HISTORY TAB ---
  Widget _buildHistoryTab(BuildContext context, ApplicationModel app, bool isDark) {
    final controller = Provider.of<ApplicationController>(context);
    final history = controller.getStatusHistoriesFor(app.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Application Milestones & Timeline',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppTheme.macosBlue),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Milestone Event'),
                onPressed: () => _showAddEventDialog(context, app),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const Text('No events recorded yet.')
          else
            _buildCard(
              title: 'Timeline (${history.length} events)',
              isDark: isDark,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final h = history[i];
                  return ListTile(
                    leading: Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        color: AppTheme.macosBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(h.event, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(h.date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (h.newStatus.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          StatusBadge(status: h.newStatus, fontSize: 10.5),
                        ],
                        if (h.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(h.notes),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // --- 6. SCHOLARSHIPS TAB ---
  Widget _buildScholarshipsTab(BuildContext context, ApplicationModel app, bool isDark, String currency) {
    final controller = Provider.of<ApplicationController>(context);
    final scholarships = controller.getScholarshipsFor(app.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tracked Scholarships & Financial Grants',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppTheme.macosBlue),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Scholarship'),
                onPressed: () => _showAddScholarshipDialog(context, app.id),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (scholarships.isEmpty)
            const Text('No scholarships tracked for this university yet.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: scholarships.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final s = scholarships[i];
                return _buildCard(
                  title: s.scholarshipName,
                  isDark: isDark,
                  trailing: StatusBadge(status: s.status),
                  child: Column(
                    children: [
                      if (s.organization.isNotEmpty)
                        _buildDetailRow('Awarding Body', s.organization),
                      _buildDetailRow('Award Amount', '$currency ${s.amount.toStringAsFixed(0)}', isBold: true),
                      _buildDetailRow('Deadline', s.deadline.isEmpty ? 'None' : s.deadline),
                      _buildDetailRow('Eligibility', s.eligibility.isEmpty ? 'See requirements' : s.eligibility),
                      _buildDetailRow('Notes', s.notes.isEmpty ? 'None' : s.notes),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit Scholarship',
                            onPressed: () => showScholarshipFormDialog(
                              context,
                              initialScholarship: s,
                              initialApplicationId: app.id,
                              lockApplication: true,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            tooltip: 'Delete Scholarship',
                            onPressed: () => controller.deleteScholarship(s.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- 7. CONTACTS TAB ---
  Widget _buildContactsTab(BuildContext context, ApplicationModel app, bool isDark) {
    final controller = Provider.of<ApplicationController>(context);
    final contacts = controller.getContactsFor(app.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('University & Admissions Contacts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppTheme.macosBlue),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Contact'),
                onPressed: () => _showAddContactDialog(context, app.id),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (contacts.isEmpty)
            const Text('No contacts saved yet.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contacts.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final c = contacts[i];
                return _buildCard(
                  title: c.contactPerson.isNotEmpty ? c.contactPerson : (c.department.isNotEmpty ? c.department : 'Contact'),
                  isDark: isDark,
                  child: Column(
                    children: [
                      _buildDetailRow('Department', c.department),
                      _buildDetailRow('Email', c.email),
                      _buildDetailRow('Phone', c.phone),
                      _buildDetailRow('Notes', c.notes),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => controller.deleteContact(c.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- 8. REVIEW TAB ---
  Widget _buildReviewTab(BuildContext context, ApplicationModel app, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCard(
                  title: 'Pros',
                  isDark: isDark,
                  child: Text(
                    app.pros.isEmpty ? 'No pros listed.' : app.pros,
                    style: const TextStyle(fontSize: 13.5, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildCard(
                  title: 'Cons',
                  isDark: isDark,
                  child: Text(
                    app.cons.isEmpty ? 'No cons listed.' : app.cons,
                    style: const TextStyle(fontSize: 13.5, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCard(
            title: 'Personal Review & Impression',
            isDark: isDark,
            child: Text(
              app.personalReview.isEmpty
                  ? 'No personal review written yet. Click edit to add your opinions, senior feedback, or campus visit impressions.'
                  : app.personalReview,
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // --- 9. NOTES TAB ---
  Widget _buildNotesTab(BuildContext context, ApplicationModel app, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: 'General Application Notes & Credentials Instructions',
            isDark: isDark,
            child: Text(
              app.generalNotes.isEmpty
                  ? 'No general notes stored.'
                  : app.generalNotes,
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helper Widgets ---
  Widget _buildCard({
    required String title,
    required Widget child,
    required bool isDark,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2129) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? AppTheme.macosGreen : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementCheckItem(String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isRequired
                  ? AppTheme.macosBlue.withAlpha(25)
                  : Colors.grey.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isRequired ? 'Required ✓' : 'Optional',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isRequired ? AppTheme.macosBlue : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineRow(String label, String date, ApplicationUrgency urgency, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isPrimary ? Icons.star : Icons.calendar_today_outlined,
                size: 16,
                color: isPrimary ? AppTheme.macosBlue : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                date.isEmpty ? 'Not set' : date,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              if (urgency != ApplicationUrgency.none) ...[
                const SizedBox(width: 8),
                UrgencyBadge(urgency: urgency),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
