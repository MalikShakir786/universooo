import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../controllers/settings_controller.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Provider.of<ApplicationController>(context);
    final settings = Provider.of<SettingsController>(context).settings;
    final currency = settings.currencySymbol;
    final apps = controller.applications;

    // Status breakdown
    final Map<String, int> statusCounts = {};
    for (final a in apps) {
      statusCounts[a.status] = (statusCounts[a.status] ?? 0) + 1;
    }

    // Degree breakdown
    final Map<String, int> degreeCounts = {};
    for (final a in apps) {
      degreeCounts[a.degreeLevel] = (degreeCounts[a.degreeLevel] ?? 0) + 1;
    }

    // Average rating
    final ratedApps = apps.where((a) => a.universityRating > 0);
    final avgRating = ratedApps.isEmpty
        ? 0.0
        : ratedApps.fold(0.0, (sum, a) => sum + a.universityRating) / ratedApps.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121316) : const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Admissions Intelligence & Analytics',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Success rates, financial investment benchmarks, and application volume metrics',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            // 4 Top KPI Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Acceptance Rate',
                    value: '${controller.acceptanceRate.toStringAsFixed(1)}%',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.macosGreen,
                    subtitle: '${controller.acceptedCount} of ${controller.totalApplications} apps accepted',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Offer / Conversion Rate',
                    value: '${controller.offerRate.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: AppTheme.macosIndigo,
                    subtitle: '${controller.acceptedCount} of ${controller.submittedCount} submitted',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Average Tuition',
                    value: '$currency ${controller.averageTuition.toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    color: AppTheme.macosBlue,
                    subtitle: 'per target university year',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Average App Fee',
                    value: '$currency ${controller.averageApplicationFee.toStringAsFixed(0)}',
                    icon: Icons.receipt_long_outlined,
                    color: AppTheme.macosOrange,
                    subtitle: 'direct application cost',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Charts Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Applications by Status
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                        const Text(
                          'Applications by Status',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (statusCounts.isEmpty)
                          const Center(child: Text('No applications tracked.'))
                        else
                          ...statusCounts.entries.map((e) {
                            final percent = controller.totalApplications == 0
                                ? 0.0
                                : e.value / controller.totalApplications;
                            final (bg, fg) = AppTheme.getStatusColors(e.key, isDark);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text('${e.value} (${(percent * 100).toStringAsFixed(0)}%)',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      minHeight: 8,
                                      backgroundColor: isDark ? const Color(0xFF2E3340) : const Color(0xFFF1F5F9),
                                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Applications by Country
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                        const Text(
                          'Applications by Country',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (controller.countryStats.isEmpty)
                          const Center(child: Text('No countries recorded.'))
                        else
                          ...controller.countryStats.map((c) {
                            final percent = controller.totalApplications == 0
                                ? 0.0
                                : c.applicationsCount / controller.totalApplications;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(c.flag),
                                          const SizedBox(width: 6),
                                          Text(c.country, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      Text('${c.applicationsCount} (${(percent * 100).toStringAsFixed(0)}%)',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      minHeight: 8,
                                      backgroundColor: isDark ? const Color(0xFF2E3340) : const Color(0xFFF1F5F9),
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.macosBlue),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bottom Section: Average Rating & Degree Distribution
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                        const Text(
                          'Average University Rating',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              avgRating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 22),
                                    Icon(Icons.star, color: Colors.amber, size: 22),
                                    Icon(Icons.star, color: Colors.amber, size: 22),
                                    Icon(Icons.star, color: Colors.amber, size: 22),
                                    Icon(Icons.star_half, color: Colors.amber, size: 22),
                                  ],
                                ),
                                Text('Across all personal reviews', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                        const Text(
                          'Degree Level Breakdown',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: degreeCounts.entries.map((e) {
                            return Chip(
                              label: Text('${e.key}: ${e.value}'),
                              backgroundColor: isDark ? const Color(0xFF282B35) : const Color(0xFFF1F5F9),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
