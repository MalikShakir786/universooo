import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../models/application_model.dart';
import '../models/country_stat_model.dart';
import '../theme/app_theme.dart';
import '../widgets/country_selector.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/urgency_badge.dart';

class DashboardScreen extends StatelessWidget {
  final Function(String applicationId) onOpenApplication;
  final VoidCallback onAddApplication;
  final VoidCallback onViewAllApplications;

  const DashboardScreen({
    super.key,
    required this.onOpenApplication,
    required this.onAddApplication,
    required this.onViewAllApplications,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Provider.of<ApplicationController>(context);

    final currentDateStr = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    // All user-added and tracked destination countries
    final activeCountries = controller.availableCountries;

    // Upcoming deadlines sorted by closest date
    final upcomingApps = List<ApplicationModel>.from(controller.applications)
      ..removeWhere((a) {
        final days = a.daysRemaining;
        return days == null || days < 0; // Exclude past or unset
      })
      ..sort((a, b) => (a.daysRemaining ?? 999).compareTo(b.daysRemaining ?? 999));
    final nextDeadlines = upcomingApps.take(5).toList();

    // Recently updated applications
    final recentApps = List<ApplicationModel>.from(controller.applications)
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    final recentCards = recentApps.take(4).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121316) : const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to University Application Manager',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Today is $currentDateStr • Offline Local Command Center',
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
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('+ Add Application'),
                  onPressed: onAddApplication,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Prominent Country Selector (Requirement 4)
            CountrySelector(
              selectedCountry: controller.selectedCountry,
              activeCountries: activeCountries,
              onCountrySelected: (c) => controller.setSelectedCountry(c),
            ),
            const SizedBox(height: 20),

            // Active Filter Notice if any stat or country is active
            if (controller.statFilter != null || controller.selectedCountry != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.macosBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.macosBlue.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 16, color: AppTheme.macosBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Filtered Dashboard: ${controller.selectedCountry ?? 'All Countries'} ${controller.statFilter != null ? '• Stat: ${controller.statFilter}' : ''}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.macosBlue,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => controller.resetFilters(),
                      child: const Text('Clear Filter', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // 8 Interactive Dashboard Statistics Cards (Requirement 5)
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 700 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 2.2,
                  children: [
                    StatCard(
                      title: 'Total Applications',
                      count: controller.totalApplications.toString(),
                      icon: Icons.school_outlined,
                      color: AppTheme.macosBlue,
                      subtitle: 'universities tracked',
                      isSelected: controller.statFilter == null && controller.selectedCountry == null,
                      onTap: () {
                        controller.resetFilters();
                        onViewAllApplications();
                      },
                    ),
                    StatCard(
                      title: 'Applications Submitted',
                      count: controller.submittedCount.toString(),
                      icon: Icons.send_outlined,
                      color: AppTheme.macosIndigo,
                      subtitle: 'in evaluation',
                      isSelected: controller.statFilter == 'Submitted',
                      onTap: () {
                        controller.setStatFilter('Submitted');
                        onViewAllApplications();
                      },
                    ),
                    StatCard(
                      title: 'Pending / In Progress',
                      count: controller.pendingCount.toString(),
                      icon: Icons.hourglass_empty_outlined,
                      color: AppTheme.macosOrange,
                      subtitle: 'drafts & prep',
                      isSelected: controller.statFilter == 'Pending',
                      onTap: () {
                        controller.setStatFilter('Pending');
                        onViewAllApplications();
                      },
                    ),
                    StatCard(
                      title: 'Offers & Accepted',
                      count: controller.acceptedCount.toString(),
                      icon: Icons.check_circle_outline,
                      color: AppTheme.macosGreen,
                      subtitle: 'positive outcomes',
                      isSelected: controller.statFilter == 'Accepted',
                      onTap: () {
                        controller.setStatFilter('Accepted');
                        onViewAllApplications();
                      },
                    ),
                    StatCard(
                      title: 'Rejected Applications',
                      count: controller.rejectedCount.toString(),
                      icon: Icons.cancel_outlined,
                      color: AppTheme.macosRed,
                      subtitle: 'rejections',
                      isSelected: controller.statFilter == 'Rejected',
                      onTap: () {
                        controller.setStatFilter('Rejected');
                        onViewAllApplications();
                      },
                    ),
                    StatCard(
                      title: 'Upcoming Deadlines',
                      count: controller.upcomingDeadlinesCount.toString(),
                      icon: Icons.alarm,
                      color: AppTheme.macosRed,
                      subtitle: 'next 30 days',
                      isSelected: controller.statFilter == 'Upcoming Deadlines',
                      onTap: () {
                        controller.setStatFilter('Upcoming Deadlines');
                        onViewAllApplications();
                      },
                    ),
                    StatCard(
                      title: 'Interviews Scheduled',
                      count: controller.interviewCount.toString(),
                      icon: Icons.record_voice_over_outlined,
                      color: AppTheme.macosPurple,
                      subtitle: 'admissions chats',
                      isSelected: controller.statFilter == 'Interviews',
                      onTap: () {
                        controller.setStatFilter('Interviews');
                        onViewAllApplications();
                      },
                    ),
                    StatCard(
                      title: 'Shortlisted Programs',
                      count: controller.shortlistedCount.toString(),
                      icon: Icons.bookmark_border,
                      color: AppTheme.macosTeal,
                      subtitle: 'candidates',
                      isSelected: controller.statFilter == 'Shortlisted',
                      onTap: () {
                        controller.setStatFilter('Shortlisted');
                        onViewAllApplications();
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Main 2-Column Section: Upcoming Deadlines Table + Distribution Overview
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 950;

                final deadlinesCard = Container(
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
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined, size: 18, color: AppTheme.macosRed),
                                SizedBox(width: 8),
                                Text(
                                  'Upcoming Deadlines Alert',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            TextButton(
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              onPressed: onViewAllApplications,
                              child: const Text('View All Applications →'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (nextDeadlines.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                              child: Text(
                                'No upcoming deadlines recorded.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 520),
                              child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2.4),
                              1: FlexColumnWidth(2.0),
                              2: FlexColumnWidth(1.2),
                              3: FlexColumnWidth(1.4),
                              4: FlexColumnWidth(1.4),
                              5: FlexColumnWidth(1.4),
                            },
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                children: [
                                  _buildTableHeader('University'),
                                  _buildTableHeader('Course'),
                                  _buildTableHeader('Country'),
                                  _buildTableHeader('Period / Deadline'),
                                  _buildTableHeader('Days Left'),
                                  _buildTableHeader('Status'),
                                ],
                              ),
                              ...nextDeadlines.map((app) {
                                return TableRow(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isDark ? const Color(0xFF2E3340).withAlpha(100) : const Color(0xFFF1F5F9),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  children: [
                                    InkWell(
                                      onTap: () => onOpenApplication(app.id),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Text(
                                          app.universityName,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Text(
                                        app.courseName,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Row(
                                        children: [
                                          Text(CountryStatModel.getFlag(app.country)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              app.country,
                                              style: const TextStyle(fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
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
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    'Opens: ${app.startOfApplications}',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.event_available,
                                                size: 11,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                app.applicationDeadline.isEmpty ? 'No date' : app.applicationDeadline,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: UrgencyBadge(
                                        urgency: app.urgency,
                                        customLabel: app.daysRemainingLabel,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: StatusBadge(status: app.status, fontSize: 10.5),
                                    ),
                                  ],
                                );
                              }),
                            ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );

                // Top Destination Countries Breakdown
                final countriesCard = Container(
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
                        const Row(
                          children: [
                            Icon(Icons.public, size: 18, color: AppTheme.macosBlue),
                            SizedBox(width: 8),
                            Text(
                              'Applications by Country',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (controller.countryStats.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text('No country data recorded yet.'),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.countryStats.take(5).length,
                            separatorBuilder: (ctx, i) => const Divider(height: 14),
                            itemBuilder: (ctx, i) {
                              final c = controller.countryStats[i];
                              final percent = controller.totalApplications == 0
                                  ? 0.0
                                  : c.applicationsCount / controller.totalApplications;

                              return InkWell(
                                onTap: () => controller.setSelectedCountry(c.country),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(c.flag, style: const TextStyle(fontSize: 16)),
                                            const SizedBox(width: 8),
                                            Text(c.country, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          ],
                                        ),
                                        Text(
                                          '${c.applicationsCount} apps (${(percent * 100).toStringAsFixed(0)}%)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percent,
                                        minHeight: 5,
                                        backgroundColor: isDark ? const Color(0xFF2E3340) : const Color(0xFFF1F5F9),
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.macosBlue),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: deadlinesCard),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: countriesCard),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      deadlinesCard,
                      const SizedBox(height: 20),
                      countriesCard,
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Recently Updated Applications Section (Requirement 34)
            Container(
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
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_toggle_off, size: 18, color: AppTheme.macosIndigo),
                          SizedBox(width: 8),
                          Text(
                            'Recently Tracked Applications',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: onViewAllApplications,
                        child: const Text('View Application Table →'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (recentCards.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No applications yet.'),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        final count = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 650 ? 2 : 1);
                        return GridView.count(
                          crossAxisCount: count,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.45,
                          children: recentCards.map((app) {
                            return InkWell(
                              onTap: () => onOpenApplication(app.id),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF282B35) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF3B404E) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(CountryStatModel.getFlag(app.country)),
                                            const SizedBox(width: 6),
                                            Text(
                                              app.country,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        StatusBadge(status: app.status, fontSize: 10),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          app.universityName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          app.courseName,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${app.intake} ${app.semesterYear}',
                                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              app.daysRemaining != null ? '${app.daysRemaining}d left' : 'No date',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: app.urgency == ApplicationUrgency.critical || app.urgency == ApplicationUrgency.overdue
                                                    ? AppTheme.macosRed
                                                    : AppTheme.macosBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                app.startOfApplications.isNotEmpty
                                                    ? 'Opens: ${app.startOfApplications}'
                                                    : 'Open / Rolling',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              app.applicationDeadline.isNotEmpty
                                                  ? 'Due: ${app.applicationDeadline}'
                                                  : 'No deadline',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}
