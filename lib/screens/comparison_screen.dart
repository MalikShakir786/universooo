import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/application_model.dart';
import '../models/country_stat_model.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class ComparisonScreen extends StatelessWidget {
  final Function(String applicationId) onOpenApplication;
  final VoidCallback onViewApplications;

  const ComparisonScreen({
    super.key,
    required this.onOpenApplication,
    required this.onViewApplications,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Provider.of<ApplicationController>(context);
    final settings = Provider.of<SettingsController>(context).settings;
    final comparedApps = controller.comparisonApplications;

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
                      'University Comparison Matrix',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Side-by-side evaluation of up to 5 target programs and universities',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                if (comparedApps.isNotEmpty)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear Comparison'),
                    onPressed: () => controller.clearComparison(),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: comparedApps.length < 2
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2129) : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.compare_arrows, size: 40, color: AppTheme.macosBlue),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            comparedApps.isEmpty
                                ? 'No universities selected for comparison'
                                : 'Select at least 2 universities to compare',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Click the comparison icon (⇄) on any university in the application list or detail page.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: onViewApplications,
                            child: const Text('Browse Applications'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2129) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              isDark ? const Color(0xFF282B35) : const Color(0xFFF8FAFC),
                            ),
                            columns: [
                              const DataColumn(
                                label: Text('Metric / Criterion',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              ...comparedApps.map((app) {
                                return DataColumn(
                                  label: Row(
                                    children: [
                                      Text(CountryStatModel.getFlag(app.country)),
                                      const SizedBox(width: 6),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 180),
                                        child: Text(
                                          app.universityName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            rows: [
                              _buildRow('Status', comparedApps, (a) => StatusBadge(status: a.status)),
                              _buildRow('Course / Program', comparedApps, (a) => Text(a.courseName, style: const TextStyle(fontWeight: FontWeight.w600))),
                              _buildRow('Degree Level', comparedApps, (a) => Text(a.degreeLevel)),
                              _buildRow('Country & City', comparedApps, (a) => Text('${a.country} ${a.city.isNotEmpty ? '• ${a.city}' : ''}')),
                              _buildRow('Intake & Year', comparedApps, (a) => Text('${a.intake} ${a.semesterYear}')),
                              _buildRow('Start of Applications', comparedApps, (a) => Text(a.startOfApplications.isEmpty ? 'N/A' : a.startOfApplications)),
                              _buildRow('Application Deadline', comparedApps, (a) => Text(a.applicationDeadline.isEmpty ? 'N/A' : a.applicationDeadline, style: const TextStyle(fontWeight: FontWeight.bold))),
                              _buildRow('Days Remaining', comparedApps, (a) => Text(a.daysRemainingLabel)),
                              _buildRow('Tuition Fee (Per Year)', comparedApps, (a) => Text(a.tuitionFee > 0 ? '${settings.currencySymbol} ${a.tuitionFee.toStringAsFixed(0)}' : 'Free / Nil', style: const TextStyle(fontWeight: FontWeight.bold))),
                              _buildRow('Living Cost (Per Year)', comparedApps, (a) => Text('${settings.currencySymbol} ${a.livingCost.toStringAsFixed(0)}')),
                              _buildRow('Scholarship Tracking', comparedApps, (a) => Text(a.scholarshipAmount > 0 ? '${settings.currencySymbol} ${a.scholarshipAmount.toStringAsFixed(0)}' : 'None tracked', style: TextStyle(color: a.scholarshipAmount > 0 ? AppTheme.macosGreen : null))),
                              _buildRow('Estimated Total Program Cost', comparedApps, (a) => Text('${settings.currencySymbol} ${a.estimatedTotalCost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                              _buildRow('IELTS Requirement', comparedApps, (a) => Text(a.ieltsRequired ? '${a.ieltsOverallRequired} overall (My: ${a.myIeltsScore})' : 'Not required')),
                              _buildRow('GPA Requirement', comparedApps, (a) => Text(a.gpaRequired > 0 ? '${a.gpaRequired} (My: ${a.myGpa})' : 'Not specified')),
                              _buildRow('Program Duration', comparedApps, (a) => Text(a.duration)),
                              _buildRow('Overall University Rating', comparedApps, (a) => Text('${a.universityRating.toStringAsFixed(1)} ★', style: const TextStyle(fontWeight: FontWeight.bold))),
                              _buildRow('Academic Quality', comparedApps, (a) => Text('${a.academicRating.toStringAsFixed(1)} ★')),
                              _buildRow('Career Opportunities', comparedApps, (a) => Text('${a.careerRating.toStringAsFixed(1)} ★')),
                              _buildRow('Location & Student Life', comparedApps, (a) => Text('${a.locationRating.toStringAsFixed(1)} ★ • ${a.studentLifeRating.toStringAsFixed(1)} ★')),
                              _buildRow('Pros', comparedApps, (a) => ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: Text(a.pros.isEmpty ? '—' : a.pros, maxLines: 3, overflow: TextOverflow.ellipsis))),
                              _buildRow('Cons', comparedApps, (a) => ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: Text(a.cons.isEmpty ? '—' : a.cons, maxLines: 3, overflow: TextOverflow.ellipsis))),
                              _buildRow('View Details', comparedApps, (a) => FilledButton.tonal(
                                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                                    onPressed: () => onOpenApplication(a.id),
                                    child: const Text('Open Page'),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(
    String metricName,
    List<ApplicationModel> apps,
    Widget Function(ApplicationModel) cellBuilder,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(metricName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
        ...apps.map((app) => DataCell(cellBuilder(app))),
      ],
    );
  }
}
