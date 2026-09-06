import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../theme/app_theme.dart';

class DocumentsHubScreen extends StatefulWidget {
  final Function(String applicationId) onOpenApplication;

  const DocumentsHubScreen({
    super.key,
    required this.onOpenApplication,
  });

  @override
  State<DocumentsHubScreen> createState() => _DocumentsHubScreenState();
}

class _DocumentsHubScreenState extends State<DocumentsHubScreen> {
  String _filter = 'All'; // All, Pending, Completed, Submitted
  String? _selectedAppId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Provider.of<ApplicationController>(context);
    final allDocs = controller.documents;

    // Filter by Application if selected
    var filteredDocs = _selectedAppId != null
        ? allDocs.where((d) => d.applicationId == _selectedAppId).toList()
        : allDocs;

    // Filter by completion status
    if (_filter == 'Pending') {
      filteredDocs = filteredDocs.where((d) => !d.completed).toList();
    } else if (_filter == 'Completed') {
      filteredDocs = filteredDocs.where((d) => d.completed).toList();
    } else if (_filter == 'Submitted') {
      filteredDocs = filteredDocs.where((d) => d.submitted).toList();
    }

    final totalCompleted = allDocs.where((d) => d.completed).length;
    final totalSubmitted = allDocs.where((d) => d.submitted).length;
    final overallProgress = allDocs.isEmpty ? 0.0 : totalCompleted / allDocs.length;

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
                      'Global Documents Command Center',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track requirements, certifications, SOPs, and recommendation letters across all universities',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress Summary Card
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Progress: $totalCompleted / ${allDocs.length} Documents Completed (${(overallProgress * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '$totalSubmitted Submitted to Portals',
                        style: const TextStyle(fontSize: 13, color: AppTheme.macosBlue, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: overallProgress,
                      minHeight: 8,
                      backgroundColor: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        overallProgress >= 0.8
                            ? AppTheme.macosGreen
                            : (overallProgress >= 0.5 ? AppTheme.macosBlue : AppTheme.macosOrange),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter Pills & Application Selector
            Row(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All Docs')),
                    ButtonSegment(value: 'Pending', label: Text('Pending ⏳')),
                    ButtonSegment(value: 'Completed', label: Text('Completed ✓')),
                    ButtonSegment(value: 'Submitted', label: Text('Submitted 🚀')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (set) => setState(() => _filter = set.first),
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2129) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: DropdownButton<String?>(
                    value: _selectedAppId,
                    hint: const Text('Filter by University', style: TextStyle(fontSize: 12)),
                    underline: const SizedBox(),
                    isDense: true,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Universities')),
                      ...controller.applications.map((app) {
                        return DropdownMenuItem(
                          value: app.id,
                          child: Text('${app.universityName} (${app.courseName})'),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedAppId = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Documents List
            Expanded(
              child: filteredDocs.isEmpty
                  ? const Center(child: Text('No documents matching this filter.'))
                  : Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2129) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: ListView.separated(
                        itemCount: filteredDocs.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final doc = filteredDocs[i];
                          final app = controller.applications
                              .where((a) => a.id == doc.applicationId)
                              .firstOrNull;

                          return ListTile(
                            leading: Checkbox(
                              value: doc.completed,
                              activeColor: AppTheme.macosGreen,
                              onChanged: (_) => controller.toggleDocumentCompleted(doc.id),
                            ),
                            title: Text(
                              doc.document,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                decoration: doc.completed ? TextDecoration.lineThrough : null,
                                color: doc.completed
                                    ? (isDark ? Colors.grey[500] : Colors.grey[600])
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              app != null
                                  ? '${app.universityName} • ${app.courseName}'
                                  : 'General Document',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FilterChip(
                                  label: Text(doc.submitted ? 'Submitted ✓' : 'Not Submitted'),
                                  selected: doc.submitted,
                                  selectedColor: AppTheme.macosBlue.withAlpha(40),
                                  onSelected: (_) => controller.toggleDocumentSubmitted(doc.id),
                                ),
                                const SizedBox(width: 8),
                                if (app != null)
                                  IconButton(
                                    tooltip: 'Open Application Details',
                                    icon: const Icon(Icons.arrow_forward, size: 16),
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
}
