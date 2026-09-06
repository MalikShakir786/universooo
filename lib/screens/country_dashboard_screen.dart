import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/application_model.dart';
import '../models/country_stat_model.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/urgency_badge.dart';
import '../widgets/add_country_dialog.dart';

class CountryDashboardScreen extends StatefulWidget {
  final Function(String applicationId) onOpenApplication;
  final Function(String country) onFilterCountry;

  const CountryDashboardScreen({
    super.key,
    required this.onOpenApplication,
    required this.onFilterCountry,
  });

  @override
  State<CountryDashboardScreen> createState() => _CountryDashboardScreenState();
}

class _CountryDashboardScreenState extends State<CountryDashboardScreen> {
  String? _selectedCountryDetail;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Provider.of<ApplicationController>(context);
    final settings = Provider.of<SettingsController>(context).settings;
    final stats = controller.countryStats;

    // Group applications by country -> university
    final selectedCountryApps = _selectedCountryDetail != null
        ? controller.applications
            .where((a) => a.country.toLowerCase() == _selectedCountryDetail!.toLowerCase())
            .toList()
        : <ApplicationModel>[];

    final Map<String, List<ApplicationModel>> univGroups = {};
    for (final app in selectedCountryApps) {
      univGroups.putIfAbsent(app.universityName, () => []).add(app);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121316) : const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Country Dashboard & Regional Hubs',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analyze your university targets, deadlines, and tuition investments by country',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_selectedCountryDetail != null) ...[
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('All Countries View'),
                        onPressed: () => setState(() => _selectedCountryDetail = null),
                      ),
                      const SizedBox(width: 10),
                    ],
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.macosBlue,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ Add Country'),
                      onPressed: () => showAddCountryDialog(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: _selectedCountryDetail == null
                  ? _buildCountryGrid(context, stats, isDark, settings.currencySymbol)
                  : _buildCountryDrilldown(
                      context,
                      _selectedCountryDetail!,
                      univGroups,
                      selectedCountryApps,
                      isDark,
                      settings.currencySymbol,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Grid of Countries with Metrics ---
  Widget _buildCountryGrid(
    BuildContext context,
    List<CountryStatModel> stats,
    bool isDark,
    String currency,
  ) {
    if (stats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.public, size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            const Text(
              'No Destination Countries Added Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add the countries you want to target for your university applications.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('+ Add Country'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.macosBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => showAddCountryDialog(context),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: stats.length + 1,
          itemBuilder: (ctx, i) {
            if (i == stats.length) {
              return InkWell(
                onTap: () => showAddCountryDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2129).withAlpha(150) : Colors.white.withAlpha(180),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.macosBlue.withAlpha(120),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.macosBlue.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_location_alt_outlined, color: AppTheme.macosBlue, size: 28),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '+ Add Target Country',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.macosBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track applications in a new region',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final c = stats[i];

            return InkWell(
              onTap: () => setState(() => _selectedCountryDetail = c.country),
              borderRadius: BorderRadius.circular(12),
              child: Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Flag and Country Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(c.flag, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              c.country,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.macosBlue.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${c.applicationsCount} ${c.applicationsCount == 1 ? 'App' : 'Apps'}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.macosBlue,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Metrics Grid (Submitted, Offers, Rejected, Pending, Deadlines)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricCol('Submitted', c.submittedCount.toString(), AppTheme.macosIndigo),
                        _buildMetricCol('Offers', c.acceptedCount.toString(), AppTheme.macosGreen),
                        _buildMetricCol('Pending', c.pendingCount.toString(), AppTheme.macosOrange),
                        _buildMetricCol('Rejected', c.rejectedCount.toString(), AppTheme.macosRed),
                        _buildMetricCol('Deadlines', c.upcomingDeadlinesCount.toString(), AppTheme.macosBlue),
                      ],
                    ),

                    // Tuition & Drilldown indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimated Tuition: $currency ${c.estimatedTuition.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const Row(
                          children: [
                            Text('Explore programs', style: TextStyle(fontSize: 11, color: AppTheme.macosBlue)),
                            Icon(Icons.chevron_right, size: 16, color: AppTheme.macosBlue),
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

  // --- Drilldown: Country -> University -> Program ---
  Widget _buildCountryDrilldown(
    BuildContext context,
    String country,
    Map<String, List<ApplicationModel>> univGroups,
    List<ApplicationModel> apps,
    bool isDark,
    String currency,
  ) {
    final flag = CountryStatModel.getFlag(country);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                Text(flag, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$country Overview',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${apps.length} application(s) tracked across ${univGroups.length} universities in $country',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // University -> Program Accordion List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: univGroups.keys.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) {
              final univName = univGroups.keys.elementAt(i);
              final programs = univGroups[univName]!;

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2129) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  leading: const Icon(Icons.account_balance, color: AppTheme.macosBlue),
                  title: Text(
                    univName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text('${programs.length} program(s) tracked'),
                  children: programs.map((prog) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: Text(
                        prog.courseName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      subtitle: Text('${prog.degreeLevel} • ${prog.intake} ${prog.semesterYear}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusBadge(status: prog.status),
                          const SizedBox(width: 8),
                          UrgencyBadge(urgency: prog.urgency, customLabel: prog.daysRemainingLabel),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            onPressed: () => widget.onOpenApplication(prog.id),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Colors.grey),
        ),
      ],
    );
  }
}
