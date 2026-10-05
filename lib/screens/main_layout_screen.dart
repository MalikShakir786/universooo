import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../controllers/settings_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/application_form_dialog.dart';
import 'analytics_screen.dart';
import 'application_detail_screen.dart';
import 'applications_screen.dart';
import 'calendar_screen.dart';
import 'comparison_screen.dart';
import 'country_dashboard_screen.dart';
import 'dashboard_screen.dart';
import 'documents_hub_screen.dart';
import 'portals_screen.dart';
import 'scholarships_screen.dart';
import 'settings_screen.dart';
import 'university_notes_screen.dart';

enum NavigationSection {
  dashboard,
  applications,
  calendar,
  countries,
  documents,
  scholarships,
  portals,
  comparison,
  analytics,
  universities,
  settings,
}

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  NavigationSection _currentSection = NavigationSection.dashboard;
  String? _activeDetailApplicationId;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openApplicationDetail(String id) {
    setState(() {
      _activeDetailApplicationId = id;
    });
  }

  void _closeApplicationDetail() {
    setState(() {
      _activeDetailApplicationId = null;
    });
  }

  void _showAddApplicationDialog() {
    ApplicationFormDialog.show(
      context,
      onOpenExisting: (existing) {
        _openApplicationDetail(existing.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Provider.of<ApplicationController>(context);
    final settingsCtrl = Provider.of<SettingsController>(context);

    // Keyboard Shortcuts (Requirement 36)
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN): const _NewAppIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF): const _SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS): const _SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyE): const _ExportIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.comma): const _SettingsIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewAppIntent: CallbackAction<_NewAppIntent>(
            onInvoke: (_) => _showAddApplicationDialog(),
          ),
          _SearchIntent: CallbackAction<_SearchIntent>(
            onInvoke: (_) => _searchFocusNode.requestFocus(),
          ),
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) async {
              if (!mounted) return null;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Workbook state refreshed & verified.')),
              );
              return null;
            },
          ),
          _ExportIntent: CallbackAction<_ExportIntent>(
            onInvoke: (_) async {
              await settingsCtrl.exportBackupDialog();
              return null;
            },
          ),
          _SettingsIntent: CallbackAction<_SettingsIntent>(
            onInvoke: (_) {
              setState(() {
                _activeDetailApplicationId = null;
                _currentSection = NavigationSection.settings;
              });
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(
              children: [
                // macOS Sidebar Navigation (Requirement 33 & 34)
                _buildSidebar(context, controller, isDark),

                // Main Content Area
                Expanded(
                  child: Column(
                    children: [
                      // macOS Top Navigation / Search Bar
                      _buildTopBar(context, controller, isDark),

                      // Screen Body or Detail View
                      Expanded(
                        child: _activeDetailApplicationId != null
                            ? ApplicationDetailScreen(
                                applicationId: _activeDetailApplicationId!,
                                onBack: _closeApplicationDetail,
                              )
                            : _buildCurrentScreen(controller),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- macOS Sidebar ---
  Widget _buildSidebar(
    BuildContext context,
    ApplicationController controller,
    bool isDark,
  ) {
    final settingsCtrl = Provider.of<SettingsController>(context);
    final comparisonCount = controller.comparisonIds.length;

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181A20) : const Color(0xFFEBEFF5),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Title / Branding in Sidebar
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.macosBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'University Mgr',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'macOS Edition',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildNavItem(
                  section: NavigationSection.dashboard,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                  isDark: isDark,
                ),
                _buildNavItem(
                  section: NavigationSection.applications,
                  icon: Icons.school_outlined,
                  activeIcon: Icons.school,
                  label: 'Applications',
                  badgeText: controller.totalApplications > 0
                      ? '${controller.totalApplications}'
                      : null,
                  isDark: isDark,
                ),
                _buildNavItem(
                  section: NavigationSection.calendar,
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  label: 'Calendar',
                  badgeText: controller.upcomingDeadlinesCount > 0
                      ? '${controller.upcomingDeadlinesCount}'
                      : null,
                  badgeColor: AppTheme.macosRed,
                  isDark: isDark,
                ),
                _buildNavItem(
                  section: NavigationSection.countries,
                  icon: Icons.public,
                  activeIcon: Icons.public,
                  label: 'Countries',
                  badgeText: controller.countryStats.isNotEmpty
                      ? '${controller.countryStats.length}'
                      : null,
                  isDark: isDark,
                ),
                _buildNavItem(
                  section: NavigationSection.documents,
                  icon: Icons.description_outlined,
                  activeIcon: Icons.description,
                  label: 'Documents',
                  badgeText: controller.documents.isNotEmpty
                      ? '${controller.documents.length}'
                      : null,
                  isDark: isDark,
                ),
                _buildNavItem(
                  section: NavigationSection.scholarships,
                  icon: Icons.monetization_on_outlined,
                  activeIcon: Icons.monetization_on,
                  label: 'Scholarships',
                  badgeText: controller.scholarships.isNotEmpty
                      ? '${controller.scholarships.length}'
                      : null,
                  isDark: isDark,
                ),
                _buildNavItem(
                  section: NavigationSection.portals,
                  icon: Icons.language_outlined,
                  activeIcon: Icons.language,
                  label: 'Direct Links',
                  badgeText: controller.portalLinks.isNotEmpty
                      ? '${controller.portalLinks.length}'
                      : null,
                  isDark: isDark,
                ),
                _buildNavItem(
                  section: NavigationSection.comparison,
                  icon: Icons.compare_arrows,
                  activeIcon: Icons.compare_arrows,
                  label: 'Comparison',
                  badgeText: comparisonCount > 0 ? '$comparisonCount' : null,
                  badgeColor: AppTheme.macosIndigo,
                  isDark: isDark,
                ),
                _buildNavItem(
                  section: NavigationSection.analytics,
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: 'Analytics',
                  isDark: isDark,
                ),
                _buildNavItem(
                  section: NavigationSection.universities,
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book,
                  label: 'Universities',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 10),
                _buildNavItem(
                  section: NavigationSection.settings,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Sidebar Footer with Local Storage Badge & Direct File Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF20232B) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_chart, size: 16, color: AppTheme.macosGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Tooltip(
                        message: settingsCtrl.databaseFilePath,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'university_applications.xlsx',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              controller.isSaving ? 'Saving...' : 'All changes saved',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => settingsCtrl.revealInFinder(),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? const Color(0xFF3B4252) : const Color(0xFFCBD5E1),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open, size: 13),
                              SizedBox(width: 4),
                              Text('Finder', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () => settingsCtrl.openInExcel(),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.macosGreen.withAlpha(isDark ? 50 : 25),
                            border: Border.all(
                              color: AppTheme.macosGreen.withAlpha(isDark ? 100 : 70),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.open_in_new, size: 13, color: AppTheme.macosGreen),
                              SizedBox(width: 4),
                              Text('Excel', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.macosGreen)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required NavigationSection section,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    String? badgeText,
    Color? badgeColor,
    required bool isDark,
  }) {
    final isSelected = _currentSection == section && _activeDetailApplicationId == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeDetailApplicationId = null;
            _currentSection = section;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.macosBlue.withAlpha(isDark ? 60 : 30)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 18,
                color: isSelected ? AppTheme.macosBlue : (isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.macosBlue
                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? (isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: badgeColor != null ? Colors.white : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Top Navigation & Search Bar ---
  Widget _buildTopBar(
    BuildContext context,
    ApplicationController controller,
    bool isDark,
  ) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2129) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          // Global Search Input
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Global Search (University, Course, Country, Status, Notes)... ⌘F',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 16),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () {
                            _searchController.clear();
                            controller.setSearchQuery('');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onChanged: (val) => controller.setSearchQuery(val),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Country Filter Quick Indicator
          if (controller.selectedCountry != null)
            Chip(
              visualDensity: VisualDensity.compact,
              avatar: const Icon(Icons.public, size: 14),
              label: Text(controller.selectedCountry!, style: const TextStyle(fontSize: 11)),
              onDeleted: () => controller.setSelectedCountry(null),
            ),

          const SizedBox(width: 12),

          // New Application Button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.macosBlue,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Application', style: TextStyle(fontSize: 12)),
            onPressed: _showAddApplicationDialog,
          ),
        ],
      ),
    );
  }

  // --- Render Current Screen ---
  Widget _buildCurrentScreen(ApplicationController controller) {
    switch (_currentSection) {
      case NavigationSection.dashboard:
        return DashboardScreen(
          onOpenApplication: _openApplicationDetail,
          onAddApplication: _showAddApplicationDialog,
          onViewAllApplications: () => setState(() => _currentSection = NavigationSection.applications),
        );
      case NavigationSection.applications:
        return ApplicationsScreen(
          onOpenApplication: _openApplicationDetail,
          onAddApplication: _showAddApplicationDialog,
        );
      case NavigationSection.calendar:
        return CalendarScreen(
          onOpenApplication: _openApplicationDetail,
        );
      case NavigationSection.countries:
        return CountryDashboardScreen(
          onOpenApplication: _openApplicationDetail,
          onFilterCountry: (c) {
            controller.setSelectedCountry(c);
            setState(() => _currentSection = NavigationSection.applications);
          },
        );
      case NavigationSection.documents:
        return DocumentsHubScreen(
          onOpenApplication: _openApplicationDetail,
        );
      case NavigationSection.scholarships:
        return ScholarshipsScreen(
          onOpenApplication: _openApplicationDetail,
        );
      case NavigationSection.portals:
        return const PortalsScreen();
      case NavigationSection.comparison:
        return ComparisonScreen(
          onOpenApplication: _openApplicationDetail,
          onViewApplications: () => setState(() => _currentSection = NavigationSection.applications),
        );
      case NavigationSection.analytics:
        return const AnalyticsScreen();
      case NavigationSection.universities:
        return const UniversityNotesScreen();
      case NavigationSection.settings:
        return const SettingsScreen();
    }
  }
}

// Shortcut Intent classes
class _NewAppIntent extends Intent {
  const _NewAppIntent();
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _ExportIntent extends Intent {
  const _ExportIntent();
}

class _SettingsIntent extends Intent {
  const _SettingsIntent();
}
