import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../models/application_model.dart';
import '../models/scholarship_model.dart';
import '../theme/app_theme.dart';

class CalendarEventItem {
  final String date;
  final String title;
  final String type; // Application, Scholarship, Visa, Decision, Interview
  final Color color;
  final ApplicationModel? application;
  final String? subtitle;

  const CalendarEventItem({
    required this.date,
    required this.title,
    required this.type,
    required this.color,
    this.application,
    this.subtitle,
  });
}

class CalendarScreen extends StatefulWidget {
  final Function(String applicationId) onOpenApplication;

  const CalendarScreen({
    super.key,
    required this.onOpenApplication,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedDate;

  List<CalendarEventItem> _extractEvents(List<ApplicationModel> apps, List<ScholarshipModel> scholarships) {
    final List<CalendarEventItem> events = [];

    for (final app in apps) {
      if (app.startOfApplications.isNotEmpty) {
        events.add(CalendarEventItem(
          date: app.startOfApplications,
          title: '${app.universityName} (Applications Open)',
          type: 'Start of Applications',
          color: AppTheme.macosBlue,
          application: app,
        ));
      }
      if (app.applicationDeadline.isNotEmpty) {
        events.add(CalendarEventItem(
          date: app.applicationDeadline,
          title: '${app.universityName} (App Deadline)',
          type: 'Application Deadline',
          color: AppTheme.macosRed,
          application: app,
        ));
      }
      if (app.scholarshipDeadline.isNotEmpty) {
        events.add(CalendarEventItem(
          date: app.scholarshipDeadline,
          title: '${app.universityName} (Scholarship Deadline)',
          type: 'Scholarship Deadline',
          color: AppTheme.macosIndigo,
          application: app,
        ));
      }
      if (app.visaDeadline.isNotEmpty) {
        events.add(CalendarEventItem(
          date: app.visaDeadline,
          title: '${app.universityName} (Visa Deadline)',
          type: 'Visa Deadline',
          color: AppTheme.macosOrange,
          application: app,
        ));
      }
      if (app.decisionDate.isNotEmpty) {
        events.add(CalendarEventItem(
          date: app.decisionDate,
          title: '${app.universityName} (Decision Expected)',
          type: 'Decision Date',
          color: AppTheme.macosGreen,
          application: app,
        ));
      }
    }

    // Add independent scholarships and additional tracked scholarships
    for (final s in scholarships) {
      if (s.deadline.isNotEmpty) {
        final app = apps.where((a) => a.id == s.applicationId).firstOrNull;
        // Avoid duplicate if already tracked by app.scholarshipDeadline with same date
        final isDup = app != null && app.scholarshipDeadline == s.deadline;
        if (!isDup) {
          events.add(CalendarEventItem(
            date: s.deadline,
            title: s.scholarshipName,
            type: s.isIndependent ? 'Independent Scholarship' : 'Scholarship Deadline',
            color: s.isIndependent ? AppTheme.macosPurple : AppTheme.macosIndigo,
            application: app,
            subtitle: s.isIndependent
                ? (s.organization.isNotEmpty ? s.organization : 'External Funding Award')
                : '${app?.universityName ?? ""} • ${app?.courseName ?? ""}',
          ));
        }
      }
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Provider.of<ApplicationController>(context);
    final allEvents = _extractEvents(controller.applications, controller.scholarships);

    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = _currentMonth.weekday; // 1 = Monday, 7 = Sunday
    final monthTitle = DateFormat('MMMM yyyy').format(_currentMonth);

    // Selected date events
    final selectedDateStr = _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : null;
    final selectedEvents = selectedDateStr != null
        ? allEvents.where((e) => e.date == selectedDateStr).toList()
        : allEvents;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121316) : const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Header & Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppTheme.macosBlue),
                    const SizedBox(width: 8),
                    Text(
                      monthTitle,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                        });
                      },
                    ),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
                          _selectedDate = DateTime.now();
                        });
                      },
                      child: const Text('Today'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Legend indicators
            Row(
              children: [
                _buildLegendItem('Application Deadline', AppTheme.macosRed),
                const SizedBox(width: 14),
                _buildLegendItem('Scholarship Deadline', AppTheme.macosIndigo),
                const SizedBox(width: 14),
                _buildLegendItem('Independent Scholarship', AppTheme.macosPurple),
                const SizedBox(width: 14),
                _buildLegendItem('Visa Deadline', AppTheme.macosOrange),
                const SizedBox(width: 14),
                _buildLegendItem('Decision Expected', AppTheme.macosGreen),
              ],
            ),
            const SizedBox(height: 16),

            // Main Content: Calendar Grid + Selected Events Sidebar
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendar Grid
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2129) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Weekdays Header
                          Row(
                            children: const [
                              Expanded(child: Center(child: Text('Mon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              Expanded(child: Center(child: Text('Tue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              Expanded(child: Center(child: Text('Wed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              Expanded(child: Center(child: Text('Thu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              Expanded(child: Center(child: Text('Fri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              Expanded(child: Center(child: Text('Sat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                              Expanded(child: Center(child: Text('Sun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                            ],
                          ),
                          const Divider(height: 16),

                          // Day Cells
                          Expanded(
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1.3,
                              ),
                              itemCount: 42, // 6 weeks
                              itemBuilder: (ctx, index) {
                                final dayOffset = index - (firstWeekday - 1);
                                if (dayOffset < 0 || dayOffset >= daysInMonth) {
                                  return const SizedBox();
                                }

                                final dayNumber = dayOffset + 1;
                                final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                                final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;
                                final isSelected = selectedDateStr == dateStr;

                                final dayEvents = allEvents.where((e) => e.date == dateStr).toList();

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = date;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    margin: const EdgeInsets.all(2),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.macosBlue.withAlpha(35)
                                          : (isToday ? AppTheme.macosBlue.withAlpha(15) : null),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.macosBlue
                                            : (isToday
                                                ? AppTheme.macosBlue.withAlpha(80)
                                                : Colors.transparent),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$dayNumber',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isToday ? AppTheme.macosBlue : null,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        ...dayEvents.take(2).map((ev) {
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 2),
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: ev.color.withAlpha(40),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              ev.title,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: ev.color,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }),
                                        if (dayEvents.length > 2)
                                          Text(
                                            '+${dayEvents.length - 2} more',
                                            style: const TextStyle(fontSize: 8, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Event List Sidebar
                  Expanded(
                    flex: 2,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate != null
                                    ? DateFormat('MMMM d, yyyy').format(_selectedDate!)
                                    : 'All Upcoming Deadlines',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              if (_selectedDate != null)
                                TextButton(
                                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                  onPressed: () => setState(() => _selectedDate = null),
                                  child: const Text('Show All'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: selectedEvents.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No deadline events on this date.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: selectedEvents.length,
                                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                                    itemBuilder: (ctx, i) {
                                      final ev = selectedEvents[i];
                                      return InkWell(
                                        onTap: ev.application != null
                                            ? () => widget.onOpenApplication(ev.application!.id)
                                            : null,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF282B35) : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: ev.color.withAlpha(70),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: ev.color.withAlpha(30),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      ev.type,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: ev.color,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    ev.date,
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                ev.application?.universityName ?? ev.title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              Text(
                                                ev.subtitle ?? ev.application?.courseName ?? '',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11.5)),
      ],
    );
  }
}
