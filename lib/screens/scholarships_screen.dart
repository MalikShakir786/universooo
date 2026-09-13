import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/scholarship_model.dart';
import '../theme/app_theme.dart';
import '../widgets/scholarship_form_dialog.dart';
import '../widgets/status_badge.dart';

class ScholarshipsScreen extends StatefulWidget {
  final Function(String applicationId) onOpenApplication;

  const ScholarshipsScreen({
    super.key,
    required this.onOpenApplication,
  });

  @override
  State<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends State<ScholarshipsScreen> {
  String _scopeFilter = 'all'; // 'all', 'independent', 'linked'
  String _statusFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, ScholarshipModel scholarship) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Scholarship'),
        content: Text('Are you sure you want to delete "${scholarship.scholarshipName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.macosRed),
            onPressed: () {
              Provider.of<ApplicationController>(context, listen: false).deleteScholarship(scholarship.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
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
    final allScholarships = controller.scholarships;

    final independentCount = allScholarships.where((s) => s.isIndependent).length;
    final linkedCount = allScholarships.where((s) => !s.isIndependent).length;

    // Filter scholarships
    final filteredScholarships = allScholarships.where((s) {
      if (_scopeFilter == 'independent' && !s.isIndependent) return false;
      if (_scopeFilter == 'linked' && s.isIndependent) return false;

      if (_statusFilter != 'All' && s.status.toLowerCase() != _statusFilter.toLowerCase()) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = s.scholarshipName.toLowerCase().contains(query);
        final orgMatch = s.organization.toLowerCase().contains(query);
        final notesMatch = s.notes.toLowerCase().contains(query);
        final app = controller.applications.where((a) => a.id == s.applicationId).firstOrNull;
        final uniMatch = app != null &&
            (app.universityName.toLowerCase().contains(query) ||
                app.courseName.toLowerCase().contains(query));

        if (!nameMatch && !orgMatch && !notesMatch && !uniMatch) return false;
      }

      return true;
    }).toList();

    final totalAwarded = allScholarships
        .where((s) => s.status.toLowerCase() == 'awarded')
        .fold(0.0, (sum, s) => sum + s.amount);

    final totalPotential = allScholarships.fold(0.0, (sum, s) => sum + s.amount);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121316) : const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Title & Add Scholarship Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scholarships & Funding Hub',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track independent fellowships, government grants, and university financial awards',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.macosBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Scholarship', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => showScholarshipFormDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Statistics Banners
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Tracked Opportunities',
                    value: '${allScholarships.length}',
                    subtitle: '$independentCount independent • $linkedCount linked',
                    icon: Icons.workspace_premium_outlined,
                    iconColor: AppTheme.macosPurple,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Awarded Funding',
                    value: '${settings.currencySymbol} ${totalAwarded.toStringAsFixed(0)}',
                    subtitle: 'Confirmed scholarships received',
                    icon: Icons.check_circle_outline,
                    iconColor: AppTheme.macosGreen,
                    valueColor: AppTheme.macosGreen,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Potential Value',
                    value: '${settings.currencySymbol} ${totalPotential.toStringAsFixed(0)}',
                    subtitle: 'Across all active applications & grants',
                    icon: Icons.trending_up,
                    iconColor: AppTheme.macosBlue,
                    valueColor: AppTheme.macosBlue,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2129) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  // Scope Selector (All, Independent, Linked)
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildScopeChip('All (${allScholarships.length})', 'all', isDark),
                      _buildScopeChip('✨ Independent ($independentCount)', 'independent', isDark),
                      _buildScopeChip('🏛️ University Linked ($linkedCount)', 'linked', isDark),
                    ],
                  ),
                  const SizedBox(width: 16),
                  const Spacer(),
                  // Search Field
                  SizedBox(
                    width: 240,
                    height: 38,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search scholarships...',
                        prefixIcon: const Icon(Icons.search, size: 16),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 14),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF2E3340) : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Filter Dropdown
                  DropdownButton<String>(
                    value: _statusFilter,
                    underline: const SizedBox.shrink(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    items: [
                      'All',
                      'Researching',
                      'Eligible',
                      'Preparing',
                      'Applied',
                      'Under Review',
                      'Awarded',
                      'Rejected',
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s == 'All' ? 'Status: All' : s))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _statusFilter = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scholarships List / Table
            Expanded(
              child: allScholarships.isEmpty
                  ? _buildZeroState(isDark)
                  : filteredScholarships.isEmpty
                      ? _buildNoResultsState(isDark)
                      : Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2129) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: ListView.separated(
                            itemCount: filteredScholarships.length,
                            separatorBuilder: (ctx, i) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final s = filteredScholarships[i];
                              final app = controller.applications
                                  .where((a) => a.id == s.applicationId)
                                  .firstOrNull;

                              final isIndependent = s.isIndependent;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: (isIndependent ? AppTheme.macosPurple : AppTheme.macosBlue).withAlpha(25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isIndependent ? Icons.workspace_premium_outlined : Icons.school_outlined,
                                    color: isIndependent ? AppTheme.macosPurple : AppTheme.macosBlue,
                                    size: 20,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      s.scholarshipName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                    ),
                                    const SizedBox(width: 8),
                                    // Independent vs Linked badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isIndependent ? AppTheme.macosPurple : AppTheme.macosBlue).withAlpha(20),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isIndependent ? 'Independent' : 'Linked',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isIndependent ? AppTheme.macosPurple : AppTheme.macosBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(status: s.status, fontSize: 10.5),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (isIndependent) ...[
                                          Icon(Icons.public, size: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            s.organization.isNotEmpty
                                                ? 'Awarding Body: ${s.organization}'
                                                : 'Independent External Scholarship',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ] else if (app != null) ...[
                                          Icon(Icons.account_balance_outlined, size: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${app.universityName} • ${app.courseName}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (s.eligibility.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Eligibility: ${s.eligibility}',
                                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (s.notes.isNotEmpty) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        'Notes: ${s.notes}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${settings.currencySymbol} ${s.amount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: s.status.toLowerCase() == 'awarded'
                                                ? AppTheme.macosGreen
                                                : null,
                                          ),
                                        ),
                                        Text(
                                          s.deadline.isNotEmpty ? 'Due ${s.deadline}' : 'No deadline',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    // Action buttons: Edit
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 17),
                                      tooltip: 'Edit Scholarship',
                                      splashRadius: 18,
                                      onPressed: () => showScholarshipFormDialog(
                                        context,
                                        initialScholarship: s,
                                      ),
                                    ),
                                    // Action buttons: Delete
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 17),
                                      tooltip: 'Delete Scholarship',
                                      splashRadius: 18,
                                      onPressed: () => _showDeleteConfirmation(context, s),
                                    ),
                                    // Action button: Open Application (if linked)
                                    if (app != null)
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward, size: 17),
                                        tooltip: 'Open Application',
                                        splashRadius: 18,
                                        onPressed: () => widget.onOpenApplication(app.id),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Color? valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2129) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeChip(String label, String scope, bool isDark) {
    final isSelected = _scopeFilter == scope;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Colors.white
              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.macosBlue,
      backgroundColor: isDark ? const Color(0xFF252A36) : const Color(0xFFF1F5F9),
      side: BorderSide.none,
      onSelected: (selected) {
        if (selected) setState(() => _scopeFilter = scope);
      },
    );
  }

  Widget _buildZeroState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.macosPurple.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              size: 36,
              color: AppTheme.macosPurple,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Scholarships Tracked Yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Track independent fellowships (e.g. DAAD, Fulbright, Erasmus+) or university merit awards',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.macosPurple,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Independent Scholarship'),
            onPressed: () => showScholarshipFormDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey.withAlpha(120)),
          const SizedBox(height: 12),
          const Text('No scholarships found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Try adjusting your search query or filter criteria.', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _scopeFilter = 'all';
                _statusFilter = 'All';
              });
            },
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}
