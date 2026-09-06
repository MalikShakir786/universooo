import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../models/application_model.dart';
import '../models/country_stat_model.dart';
import '../theme/app_theme.dart';
import 'application_form_dialog.dart';

/// Shows a dialog to duplicate an existing application with customizable options.
Future<ApplicationModel?> showDuplicateApplicationDialog(
  BuildContext context,
  ApplicationModel sourceApp, {
  Function(ApplicationModel newApp)? onDuplicated,
}) {
  return showDialog<ApplicationModel>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _DuplicateApplicationDialogContent(
      sourceApp: sourceApp,
      onDuplicated: onDuplicated,
    ),
  );
}

class _DuplicateApplicationDialogContent extends StatefulWidget {
  final ApplicationModel sourceApp;
  final Function(ApplicationModel)? onDuplicated;

  const _DuplicateApplicationDialogContent({
    required this.sourceApp,
    this.onDuplicated,
  });

  @override
  State<_DuplicateApplicationDialogContent> createState() =>
      _DuplicateApplicationDialogContentState();
}

class _DuplicateApplicationDialogContentState
    extends State<_DuplicateApplicationDialogContent> {
  late TextEditingController _courseCtrl;
  late TextEditingController _semesterYearCtrl;
  late String _selectedIntake;
  late String _selectedStatus;

  bool _copyDocuments = true;
  bool _copyContacts = true;
  bool _copyScholarships = true;
  bool _isDuplicating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final source = widget.sourceApp;
    _courseCtrl = TextEditingController(text: '${source.courseName} (Copy)');
    _semesterYearCtrl = TextEditingController(text: source.semesterYear);
    _selectedIntake = source.intake;
    _selectedStatus = 'Researching';
  }

  @override
  void dispose() {
    _courseCtrl.dispose();
    _semesterYearCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleDuplicate() async {
    final newCourse = _courseCtrl.text.trim();
    if (newCourse.isEmpty) {
      setState(() => _errorMessage = 'Please enter a course name');
      return;
    }

    final newSemester = _semesterYearCtrl.text.trim();
    final appCtrl = Provider.of<ApplicationController>(context, listen: false);

    // Check duplicate
    final duplicate = appCtrl.checkDuplicate(
      widget.sourceApp.universityName,
      newCourse,
      newSemester,
    );
    if (duplicate != null) {
      setState(() {
        _errorMessage =
            'An application for "$newCourse" at ${widget.sourceApp.universityName} ($newSemester) already exists.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isDuplicating = true;
    });

    try {
      final newApp = await appCtrl.duplicateApplication(
        widget.sourceApp.id,
        newCourseName: newCourse,
        newSemesterYear: newSemester,
        newIntake: _selectedIntake,
        newStatus: _selectedStatus,
        copyDocuments: _copyDocuments,
        copyScholarships: _copyScholarships,
        copyContacts: _copyContacts,
      );

      if (mounted) {
        widget.onDuplicated?.call(newApp);
        Navigator.of(context).pop(newApp);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Duplicated to "${newApp.courseName}" at ${newApp.universityName}',
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            width: 440,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to duplicate: $e';
          _isDuplicating = false;
        });
      }
    }
  }

  void _openFullForm() {
    Navigator.of(context).pop();
    ApplicationFormDialog.show(
      context,
      application: widget.sourceApp,
      isDuplicate: true,
      onOpenExisting: (app) {
        widget.onDuplicated?.call(app);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final source = widget.sourceApp;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E2129) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 24,
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.macosBlue.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.copy_all_outlined,
                    color: AppTheme.macosBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Duplicate Application',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Create a new application copying ${source.universityName} details',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  splashRadius: 18,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Source Application Summary Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF282B35)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3B404E)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    CountryStatModel.getFlag(source.country),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source.universityName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Source: ${source.courseName} • ${source.country} • ${source.semesterYear}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form Inputs
            Text(
              'New Course / Program Name *',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _courseCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. MSc Data Science, MSc Computer Science...',
                errorText: _errorMessage,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => _handleDuplicate(),
            ),
            const SizedBox(height: 14),

            // Intake & Semester Year
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Intake',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedIntake,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        items: const ['Fall', 'Spring', 'Summer', 'Winter']
                            .map((i) =>
                                DropdownMenuItem(value: i, child: Text(i)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedIntake = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semester / Year',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _semesterYearCtrl,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Fall 2026, 2026/2027',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Initial Status Dropdown
            Text(
              'Initial Application Status',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: <String>{
                'Researching',
                'Interested',
                'Shortlisted',
                'Preparing',
                'Ready to Apply',
                source.status,
              }
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 14),

            // Copy Options Checkboxes
            Text(
              'Copy Associated Data',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Copy Document Checklist (reset to uncompleted)',
                style: TextStyle(fontSize: 12.5),
              ),
              value: _copyDocuments,
              activeColor: AppTheme.macosBlue,
              onChanged: (v) => setState(() => _copyDocuments = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Copy University & Faculty Contacts',
                style: TextStyle(fontSize: 12.5),
              ),
              value: _copyContacts,
              activeColor: AppTheme.macosBlue,
              onChanged: (v) => setState(() => _copyContacts = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Copy Scholarship Entries (set to Considering)',
                style: TextStyle(fontSize: 12.5),
              ),
              value: _copyScholarships,
              activeColor: AppTheme.macosBlue,
              onChanged: (v) => setState(() => _copyScholarships = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 18),

            // Buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: _isDuplicating ? null : _openFullForm,
                  icon: const Icon(Icons.tune, size: 15),
                  label: const Text(
                    'Customize in Full Form...',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _isDuplicating
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isDuplicating ? null : _handleDuplicate,
                  icon: _isDuplicating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.copy, size: 15),
                  label: Text(_isDuplicating ? 'Duplicating...' : 'Duplicate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.macosBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
