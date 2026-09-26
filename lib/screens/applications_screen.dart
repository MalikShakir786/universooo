import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/application_model.dart';
import '../models/country_stat_model.dart';
import '../theme/app_theme.dart';
import '../widgets/application_form_dialog.dart';
import '../widgets/duplicate_application_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/status_badge.dart';
import '../widgets/urgency_badge.dart';

class ApplicationsScreen extends StatefulWidget {
  final Function(String applicationId) onOpenApplication;
  final VoidCallback onAddApplication;

  const ApplicationsScreen({
    super.key,
    required this.onOpenApplication,
    required this.onAddApplication,
  });

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  bool _isTableView = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Provider.of<ApplicationController>(context);
    final settings = Provider.of<SettingsController>(context).settings;
    final apps = controller.filteredApplications;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121316) : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Filter & Toolbar Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                // Top controls: Title, Counters, View Toggle, Add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Applications',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.macosBlue.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${apps.length} of ${controller.totalApplications}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.macosBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // View Toggle: Table vs Cards
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: true,
                              icon: Icon(Icons.table_rows_outlined, size: 16),
                              label: Text('Table'),
                            ),
                            ButtonSegment(
                              value: false,
                              icon: Icon(Icons.grid_view_outlined, size: 16),
                              label: Text('Cards'),
                            ),
                          ],
                          selected: {_isTableView},
                          onSelectionChanged: (set) => setState(() => _isTableView = set.first),
                          style: const ButtonStyle(visualDensity: VisualDensity.compact),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.macosBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Application'),
                          onPressed: widget.onAddApplication,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Multi-Filter Dropdowns and Sort Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Country Filter
                      _buildFilterDropdown<String>(
                        label: 'Country',
                        value: controller.selectedCountry,
                        items: [
                          'All Countries',
                          ...controller.availableCountries,
                        ],
                        onChanged: (v) => controller.setSelectedCountry(v == 'All Countries' ? null : v),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),

                      // Status Filter
                      _buildFilterDropdown<String>(
                        label: 'Status',
                        value: controller.statusFilter,
                        items: [
                          'All Statuses',
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
                        ],
                        onChanged: (v) => controller.setStatusFilter(v == 'All Statuses' ? null : v),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),

                      // Degree Filter
                      _buildFilterDropdown<String>(
                        label: 'Degree',
                        value: controller.degreeFilter,
                        items: ["All Degrees", "Bachelor's", "Master's", "PhD", "Diploma", "Other"],
                        onChanged: (v) => controller.setDegreeFilter(v == 'All Degrees' ? null : v),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),

                      // Priority Filter
                      _buildFilterDropdown<String>(
                        label: 'Priority',
                        value: controller.priorityFilter,
                        items: ['All Priorities', 'High', 'Medium', 'Low'],
                        onChanged: (v) => controller.setPriorityFilter(v == 'All Priorities' ? null : v),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),

                      // Favorites Filter
                      FilterChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text('Favorites Only', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        selected: controller.favoritesOnly,
                        onSelected: (_) => controller.toggleFavoritesOnly(),
                      ),
                      const SizedBox(width: 8),

                      // Reset Filters Button
                      if (controller.selectedCountry != null ||
                          controller.statusFilter != null ||
                          controller.degreeFilter != null ||
                          controller.priorityFilter != null ||
                          controller.favoritesOnly ||
                          controller.searchQuery.isNotEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Reset Filters', style: TextStyle(fontSize: 12)),
                          onPressed: () => controller.resetFilters(),
                        ),

                      const SizedBox(width: 16),
                      // Sorting Dropdown
                      Container(height: 20, width: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                      const SizedBox(width: 16),
                      const Text('Sort by: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      DropdownButton<String>(
                        value: controller.sortBy,
                        underline: const SizedBox(),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'deadline', child: Text('Deadline')),
                          DropdownMenuItem(value: 'university', child: Text('University')),
                          DropdownMenuItem(value: 'country', child: Text('Country')),
                          DropdownMenuItem(value: 'status', child: Text('Status')),
                          DropdownMenuItem(value: 'priority', child: Text('Priority')),
                          DropdownMenuItem(value: 'ielts', child: Text('IELTS Requirement')),
                          DropdownMenuItem(value: 'date', child: Text('Date Created')),
                        ],
                        onChanged: (val) {
                          if (val != null) controller.setSort(val);
                        },
                      ),
                      IconButton(
                        tooltip: controller.sortAscending ? 'Ascending' : 'Descending',
                        icon: Icon(
                          controller.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                        ),
                        onPressed: () => controller.setSort(controller.sortBy),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Application List Content (Table or Cards)
          Expanded(
            child: apps.isEmpty
                ? EmptyStateView(
                    icon: Icons.school_outlined,
                    title: controller.applications.isEmpty
                        ? 'No applications yet'
                        : 'No matching applications found',
                    description: controller.applications.isEmpty
                        ? 'Start building your university application command center by adding your first program.'
                        : 'Try adjusting your filters or search keywords to see applications.',
                    buttonText: controller.applications.isEmpty ? '+ Add University' : 'Reset Filters',
                    onButtonPressed: controller.applications.isEmpty
                        ? widget.onAddApplication
                        : () => controller.resetFilters(),
                  )
                : (_isTableView
                    ? _buildTableView(context, apps, isDark, controller, settings.currencySymbol)
                    : _buildCardsView(context, apps, isDark, controller, settings.currencySymbol)),
          ),
        ],
      ),
    );
  }

  // --- Table View ---
  Widget _buildTableView(
    BuildContext context,
    List<ApplicationModel> apps,
    bool isDark,
    ApplicationController controller,
    String currency,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2129) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStateProperty.all(
              isDark ? const Color(0xFF282B35) : const Color(0xFFF8FAFC),
            ),
            columns: const [
              DataColumn(label: Text('⭐', style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('University & Course', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Country & City', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Intake / Degree', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Period & Deadline', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('IELTS Req', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Tuition', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: apps.map((app) {
              final isCompared = controller.comparisonIds.contains(app.id);

              return DataRow(
                onSelectChanged: (_) => widget.onOpenApplication(app.id),
                cells: [
                  DataCell(
                    IconButton(
                      icon: Icon(
                        app.isFavorite ? Icons.star : Icons.star_border,
                        size: 18,
                        color: app.isFavorite ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () => controller.toggleFavorite(app.id),
                    ),
                  ),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          app.universityName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          app.courseName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Text(CountryStatModel.getFlag(app.country)),
                        const SizedBox(width: 6),
                        Text('${app.country}${app.city.isNotEmpty ? ' • ${app.city}' : ''}'),
                      ],
                    ),
                  ),
                  DataCell(Text('${app.intake} ${app.semesterYear} (${app.degreeLevel})')),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (app.startOfApplications.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  size: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Opens: ${app.startOfApplications}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              app.applicationDeadline.isEmpty ? 'No date' : app.applicationDeadline,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 6),
                            UrgencyBadge(urgency: app.urgency, customLabel: app.daysRemainingLabel),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    app.ieltsRequired
                        ? Row(
                            children: [
                              Text('${app.ieltsOverallRequired}'),
                              const SizedBox(width: 4),
                              Icon(
                                app.isIeltsMet ? Icons.check_circle : Icons.error_outline,
                                size: 14,
                                color: app.isIeltsMet ? AppTheme.macosGreen : AppTheme.macosOrange,
                              ),
                            ],
                          )
                        : const Text('Not req', style: TextStyle(color: Colors.grey)),
                  ),
                  DataCell(StatusBadge(status: app.status)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: app.priority == 'High'
                            ? AppTheme.macosRed.withAlpha(25)
                            : (app.priority == 'Medium'
                                ? AppTheme.macosBlue.withAlpha(25)
                                : Colors.grey.withAlpha(25)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        app.priority,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: app.priority == 'High'
                              ? AppTheme.macosRed
                              : (app.priority == 'Medium' ? AppTheme.macosBlue : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      app.tuitionFee > 0 ? '$currency ${app.tuitionFee.toStringAsFixed(0)}' : 'Free / Nil',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          tooltip: isCompared ? 'Remove Comparison' : 'Add to Comparison',
                          icon: Icon(
                            isCompared ? Icons.compare : Icons.compare_arrows,
                            size: 18,
                            color: isCompared ? AppTheme.macosBlue : null,
                          ),
                          onPressed: () => controller.toggleComparison(app.id),
                        ),
                        IconButton(
                          tooltip: 'Duplicate',
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          onPressed: () => showDuplicateApplicationDialog(context, app),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => ApplicationFormDialog.show(context, application: app),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // --- Cards View ---
  Widget _buildCardsView(
    BuildContext context,
    List<ApplicationModel> apps,
    bool isDark,
    ApplicationController controller,
    String currency,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.32,
          ),
          itemCount: apps.length,
          itemBuilder: (ctx, i) {
            final app = apps[i];
            final docs = controller.getDocumentsFor(app.id);
            final completedDocs = docs.where((d) => d.completed).length;
            final readiness = app.calculateReadiness(
              documentsTotal: docs.length,
              documentsCompleted: completedDocs,
            );
            final isCompared = controller.comparisonIds.contains(app.id);

            return InkWell(
              onTap: () => widget.onOpenApplication(app.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2129) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompared
                        ? AppTheme.macosBlue
                        : (isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0)),
                    width: isCompared ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Country, Status, Favorite
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(CountryStatModel.getFlag(app.country), style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              app.country,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            StatusBadge(status: app.status, fontSize: 10),
                            const SizedBox(width: 4),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                app.isFavorite ? Icons.star : Icons.star_border,
                                size: 18,
                                color: app.isFavorite ? Colors.amber : Colors.grey,
                              ),
                              onPressed: () => controller.toggleFavorite(app.id),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Title & Course
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.universityName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${app.courseName} • ${app.degreeLevel}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Period, Deadline & Readiness
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.play_circle_outline,
                                  size: 12,
                                  color: AppTheme.macosBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Opens: ${app.startOfApplications.isNotEmpty ? app.startOfApplications : 'Open / Rolling'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            if (app.startOfApplications.isNotEmpty && app.daysUntilOpen != null && app.daysUntilOpen! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.macosBlue.withAlpha(25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Opens in ${app.daysUntilOpen}d',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.macosBlue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event_available,
                                  size: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  app.applicationDeadline.isEmpty ? 'No deadline' : 'Deadline: ${app.applicationDeadline}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            UrgencyBadge(urgency: app.urgency, customLabel: app.daysRemainingLabel),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: readiness / 100.0,
                                  minHeight: 4,
                                  backgroundColor: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    readiness >= 80 ? AppTheme.macosGreen : AppTheme.macosBlue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$readiness%',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Footer Info & Quick actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${app.intake} ${app.semesterYear} • ${app.priority} Priority',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              tooltip: isCompared ? 'Remove Comparison' : 'Add to Comparison',
                              icon: Icon(
                                isCompared ? Icons.compare : Icons.compare_arrows,
                                size: 16,
                                color: isCompared ? AppTheme.macosBlue : null,
                              ),
                              onPressed: () => controller.toggleComparison(app.id),
                            ),
                            IconButton(
                              tooltip: 'Duplicate',
                              icon: const Icon(Icons.copy_outlined, size: 16),
                              onPressed: () => showDuplicateApplicationDialog(context, app),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              onPressed: () => ApplicationFormDialog.show(context, application: app),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282B35) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF3B404E) : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButton<T>(
        value: value,
        hint: Text(label, style: const TextStyle(fontSize: 12)),
        underline: const SizedBox(),
        isDense: true,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white : Colors.black87,
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(item.toString()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
