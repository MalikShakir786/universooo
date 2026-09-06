import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../controllers/settings_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class ScholarshipsScreen extends StatelessWidget {
  final Function(String applicationId) onOpenApplication;

  const ScholarshipsScreen({
    super.key,
    required this.onOpenApplication,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Provider.of<ApplicationController>(context);
    final settings = Provider.of<SettingsController>(context).settings;
    final scholarships = controller.scholarships;

    final totalAwarded = scholarships
        .where((s) => s.status.toLowerCase() == 'awarded')
        .fold(0.0, (sum, s) => sum + s.amount);

    final totalPotential = scholarships.fold(0.0, (sum, s) => sum + s.amount);

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
                      'Scholarships & Funding Hub',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track tuition waivers, government fellowships, and university financial grants',
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

            // Statistics Banners
            Row(
              children: [
                Expanded(
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
                      children: [
                        const Text('Total Scholarships Tracked', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${scholarships.length} opportunities',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
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
                      children: [
                        const Text('Awarded Funding', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${settings.currencySymbol} ${totalAwarded.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.macosGreen),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
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
                      children: [
                        const Text('Total Potential Value', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${settings.currencySymbol} ${totalPotential.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.macosBlue),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Scholarships Table
            Expanded(
              child: scholarships.isEmpty
                  ? const Center(child: Text('No scholarships recorded yet. Open an application to add scholarships.'))
                  : Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2129) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: ListView.separated(
                        itemCount: scholarships.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final s = scholarships[i];
                          final app = controller.applications
                              .where((a) => a.id == s.applicationId)
                              .firstOrNull;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            title: Row(
                              children: [
                                Text(
                                  s.scholarshipName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(width: 10),
                                StatusBadge(status: s.status, fontSize: 10.5),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  app != null
                                      ? '${app.universityName} • ${app.courseName}'
                                      : 'Independent Scholarship',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                if (s.eligibility.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Eligibility: ${s.eligibility}',
                                    style: const TextStyle(fontSize: 11.5, color: Colors.grey),
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
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      s.deadline.isNotEmpty ? 'Due ${s.deadline}' : 'No deadline',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                if (app != null)
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward, size: 16),
                                    onPressed: () => onOpenApplication(app.id),
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
