import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../controllers/application_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/scholarship_model.dart';
import '../theme/app_theme.dart';

/// Shows the modal dialog to create or edit a scholarship.
/// Set [initialApplicationId] if creating a scholarship for a specific application.
/// Set [lockApplication] to true to prevent changing the linked application.
Future<ScholarshipModel?> showScholarshipFormDialog(
  BuildContext context, {
  ScholarshipModel? initialScholarship,
  String? initialApplicationId,
  bool lockApplication = false,
}) {
  return showDialog<ScholarshipModel>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _ScholarshipFormDialogContent(
      initialScholarship: initialScholarship,
      initialApplicationId: initialApplicationId,
      lockApplication: lockApplication,
    ),
  );
}

class _ScholarshipFormDialogContent extends StatefulWidget {
  final ScholarshipModel? initialScholarship;
  final String? initialApplicationId;
  final bool lockApplication;

  const _ScholarshipFormDialogContent({
    this.initialScholarship,
    this.initialApplicationId,
    this.lockApplication = false,
  });

  @override
  State<_ScholarshipFormDialogContent> createState() => _ScholarshipFormDialogContentState();
}

class _ScholarshipFormDialogContentState extends State<_ScholarshipFormDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _orgController;
  late final TextEditingController _amountController;
  late final TextEditingController _deadlineController;
  late final TextEditingController _eligibilityController;
  late final TextEditingController _notesController;

  late String _selectedApplicationId;
  late String _selectedStatus;
  bool _isSubmitting = false;

  final List<String> _statusOptions = [
    'Researching',
    'Eligible',
    'Preparing',
    'Applied',
    'Under Review',
    'Awarded',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.initialScholarship;

    _nameController = TextEditingController(text: s?.scholarshipName ?? '');
    _orgController = TextEditingController(text: s?.organization ?? '');
    _amountController = TextEditingController(text: s != null && s.amount > 0 ? s.amount.toStringAsFixed(0) : '');
    _deadlineController = TextEditingController(text: s?.deadline ?? '');
    _eligibilityController = TextEditingController(text: s?.eligibility ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');

    _selectedApplicationId = s?.applicationId ?? (widget.initialApplicationId ?? '');
    _selectedStatus = s?.status ?? 'Researching';
    if (!_statusOptions.contains(_selectedStatus)) {
      _selectedStatus = 'Researching';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orgController.dispose();
    _amountController.dispose();
    _deadlineController.dispose();
    _eligibilityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    DateTime initial = DateTime.now().add(const Duration(days: 30));
    if (_deadlineController.text.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(_deadlineController.text.trim());
      if (parsed != null) initial = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _deadlineController.text = formatted;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final controller = Provider.of<ApplicationController>(context, listen: false);
      final isEditing = widget.initialScholarship != null;
      final id = widget.initialScholarship?.id ?? const Uuid().v4();

      final scholarship = ScholarshipModel(
        id: id,
        applicationId: _selectedApplicationId.trim(),
        scholarshipName: _nameController.text.trim(),
        organization: _orgController.text.trim(),
        amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
        deadline: _deadlineController.text.trim(),
        eligibility: _eligibilityController.text.trim(),
        status: _selectedStatus,
        notes: _notesController.text.trim(),
      );

      if (isEditing) {
        await controller.updateScholarship(scholarship);
      } else {
        await controller.addScholarship(scholarship);
      }

      if (mounted) {
        Navigator.of(context).pop(scholarship);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'awarded':
        return AppTheme.macosGreen;
      case 'applied':
      case 'under review':
        return AppTheme.macosBlue;
      case 'preparing':
      case 'eligible':
        return AppTheme.macosOrange;
      case 'rejected':
        return AppTheme.macosRed;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialScholarship != null;
    final controller = Provider.of<ApplicationController>(context);
    final settings = Provider.of<SettingsController>(context).settings;
    final applications = controller.applications;

    final isIndependent = _selectedApplicationId.trim().isEmpty;
    final selectedApp = applications.where((a) => a.id == _selectedApplicationId).firstOrNull;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E2129) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 780),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isIndependent
                            ? AppTheme.macosPurple.withAlpha(30)
                            : AppTheme.macosBlue.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isIndependent ? Icons.workspace_premium_outlined : Icons.school_outlined,
                        color: isIndependent ? AppTheme.macosPurple : AppTheme.macosBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Scholarship' : 'Add Scholarship Opportunity',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isIndependent
                                ? 'Track independent grants, government awards, or foundation funding'
                                : 'Track funding linked to your university applications',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
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
              ),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Application Association Dropdown
                      _buildSectionLabel('Application Association', isDark),
                      const SizedBox(height: 6),
                      if (widget.lockApplication && selectedApp != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF252A36) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF3B404E) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link, size: 18, color: AppTheme.macosBlue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${selectedApp.universityName} • ${selectedApp.courseName}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: applications.any((a) => a.id == _selectedApplicationId)
                              ? _selectedApplicationId
                              : '',
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF3B404E) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            prefixIcon: Icon(
                              isIndependent ? Icons.public : Icons.account_balance_outlined,
                              size: 18,
                              color: isIndependent ? AppTheme.macosPurple : AppTheme.macosBlue,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text(
                                '✨ Independent Scholarship (No Application)',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            ...applications.map((app) {
                              return DropdownMenuItem<String>(
                                value: app.id,
                                child: Text(
                                  '${app.universityName} — ${app.courseName}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedApplicationId = val);
                            }
                          },
                        ),
                      const SizedBox(height: 6),
                      // Info badge explaining association
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (isIndependent ? AppTheme.macosPurple : AppTheme.macosBlue).withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isIndependent ? Icons.info_outline : Icons.link,
                              size: 15,
                              color: isIndependent ? AppTheme.macosPurple : AppTheme.macosBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isIndependent
                                    ? 'Independent: Kept independently from applications (e.g. Fulbright, DAAD, Rotary).'
                                    : 'Linked: Associated with the selected university and course.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isIndependent ? AppTheme.macosPurple : AppTheme.macosBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Scholarship Name & Organization
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('Scholarship Name *', isDark),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Merit Fellowship, DAAD Grant',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: isDark ? const Color(0xFF3B404E) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter scholarship name';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('Provider / Org', isDark),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _orgController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. DAAD, Fulbright',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: isDark ? const Color(0xFF3B404E) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Amount & Deadline
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('Funding Amount', isDark),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    prefixText: '${settings.currencySymbol} ',
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: isDark ? const Color(0xFF3B404E) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('Deadline', isDark),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _deadlineController,
                                  decoration: InputDecoration(
                                    hintText: 'YYYY-MM-DD',
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_today, size: 18),
                                      onPressed: _pickDeadline,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: isDark ? const Color(0xFF3B404E) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status Dropdown
                      _buildSectionLabel('Tracking Status', isDark),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF3B404E) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 8),
                            child: Icon(
                              Icons.circle,
                              size: 14,
                              color: _getStatusColor(_selectedStatus),
                            ),
                          ),
                        ),
                        items: _statusOptions.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatus = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Eligibility
                      _buildSectionLabel('Eligibility Criteria', isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _eligibilityController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g. Minimum GPA 3.5, TOEFL >= 100, Citizens of target countries...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF3B404E) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes / Requirements
                      _buildSectionLabel('Notes & Application Requirements', isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'e.g. Requires 2 letters of recommendation, motivation essay, certified transcripts...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF3B404E) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: isIndependent ? AppTheme.macosPurple : AppTheme.macosBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Save Changes' : (isIndependent ? 'Add Independent Scholarship' : 'Save Scholarship')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
      ),
    );
  }
}
