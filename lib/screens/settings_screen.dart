import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/country_stat_model.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _studentNameCtrl;
  late TextEditingController _defaultEmailCtrl;
  late TextEditingController _currentIeltsCtrl;
  late TextEditingController _currentGpaCtrl;
  late TextEditingController _degreeCtrl;
  late TextEditingController _gradYearCtrl;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsController>(context, listen: false).settings;
    _studentNameCtrl = TextEditingController(text: settings.studentName);
    _defaultEmailCtrl = TextEditingController(text: settings.defaultEmail);
    _currentIeltsCtrl = TextEditingController(text: settings.currentIeltsScore.toString());
    _currentGpaCtrl = TextEditingController(text: settings.currentGpa.toString());
    _degreeCtrl = TextEditingController(text: settings.currentDegree);
    _gradYearCtrl = TextEditingController(text: settings.graduationYear);
  }

  @override
  void dispose() {
    _studentNameCtrl.dispose();
    _defaultEmailCtrl.dispose();
    _currentIeltsCtrl.dispose();
    _currentGpaCtrl.dispose();
    _degreeCtrl.dispose();
    _gradYearCtrl.dispose();
    super.dispose();
  }

  void _saveProfile(SettingsController controller) {
    final updated = controller.settings.copyWith(
      studentName: _studentNameCtrl.text.trim(),
      defaultEmail: _defaultEmailCtrl.text.trim(),
      currentIeltsScore: double.tryParse(_currentIeltsCtrl.text) ?? 7.5,
      currentGpa: double.tryParse(_currentGpaCtrl.text) ?? 3.7,
      currentDegree: _degreeCtrl.text.trim(),
      graduationYear: _gradYearCtrl.text.trim(),
    );
    controller.updateSettings(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved to Excel')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsCtrl = Provider.of<SettingsController>(context);
    final appCtrl = Provider.of<ApplicationController>(context);
    final settings = settingsCtrl.settings;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121316) : const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Preferences & Local Data Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your applicant profile, default preferences, theme, and local Excel database',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            // Privacy Guarantee Banner (Requirement 43)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.macosGreen.withAlpha(isDark ? 30 : 20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.macosGreen.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: AppTheme.macosGreen, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🔒 Privacy Assured: Your application data is stored 100% locally on this Mac in "university_applications.xlsx". No credentials or data are sent to external servers.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Personal Profile
            _buildSectionCard(
              title: 'Student Profile & Defaults',
              isDark: isDark,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _studentNameCtrl,
                          decoration: const InputDecoration(labelText: 'Student Full Name'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _defaultEmailCtrl,
                          decoration: const InputDecoration(labelText: 'Default Application Email'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _currentIeltsCtrl,
                          decoration: const InputDecoration(labelText: 'Current IELTS Score'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _currentGpaCtrl,
                          decoration: const InputDecoration(labelText: 'Current GPA'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _degreeCtrl,
                          decoration: const InputDecoration(labelText: 'Current Degree Title'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _gradYearCtrl,
                          decoration: const InputDecoration(labelText: 'Graduation Year'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.macosBlue),
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Save Profile Updates'),
                        onPressed: () => _saveProfile(settingsCtrl),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Application Defaults & Appearance
            _buildSectionCard(
              title: 'Application Defaults & Appearance',
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: appCtrl.availableCountries.contains(settings.defaultCountry)
                              ? settings.defaultCountry
                              : (appCtrl.availableCountries.isNotEmpty ? appCtrl.availableCountries.first : null),
                          decoration: const InputDecoration(labelText: 'Default Country'),
                          items: [
                            if (settings.defaultCountry.isNotEmpty && !appCtrl.availableCountries.contains(settings.defaultCountry))
                              DropdownMenuItem(
                                value: settings.defaultCountry,
                                child: Text(settings.defaultCountry),
                              ),
                            ...appCtrl.availableCountries.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Text(CountryStatModel.getFlag(c)),
                                    const SizedBox(width: 8),
                                    Text(c),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              settingsCtrl.updateSettings(settings.copyWith(defaultCountry: val));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: settings.defaultIntake,
                          decoration: const InputDecoration(labelText: 'Default Intake'),
                          items: const [
                            DropdownMenuItem(value: 'Fall', child: Text('Fall')),
                            DropdownMenuItem(value: 'Spring', child: Text('Spring')),
                            DropdownMenuItem(value: 'Summer', child: Text('Summer')),
                            DropdownMenuItem(value: 'Winter', child: Text('Winter')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              settingsCtrl.updateSettings(settings.copyWith(defaultIntake: val));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: settings.defaultCurrency,
                          decoration: const InputDecoration(labelText: 'Currency'),
                          items: const [
                            DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                            DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                            DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                            DropdownMenuItem(value: 'CAD', child: Text('CAD (CA\$)')),
                            DropdownMenuItem(value: 'AUD', child: Text('AUD (A\$)')),
                            DropdownMenuItem(value: 'CHF', child: Text('CHF (CHF)')),
                            DropdownMenuItem(value: 'JPY', child: Text('JPY (¥)')),
                          ],
                          onChanged: (val) {
                            if (val != null) settingsCtrl.setCurrency(val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Appearance & Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto, size: 16),
                        label: Text('System Appearance'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode, size: 16),
                        label: Text('Light Mode'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode, size: 16),
                        label: Text('Dark Mode'),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (set) => settingsCtrl.setThemeMode(set.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Data Persistence & Backup / Restore (Requirement 30 & 31)
            _buildSectionCard(
              title: 'Excel Storage & Backup / Restore Center',
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.table_chart_outlined, color: AppTheme.macosBlue, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Active Excel Workbook Path:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            SelectableText(
                              settingsCtrl.databaseFilePath,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.open_in_new, size: 14),
                                  label: const Text('Open in Excel / Numbers', style: TextStyle(fontSize: 12)),
                                  onPressed: () async {
                                    final ok = await settingsCtrl.openInExcel();
                                    if (!ok && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Could not open file in external spreadsheet app')),
                                      );
                                    }
                                  },
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.folder_open, size: 14),
                                  label: const Text('Show in Finder', style: TextStyle(fontSize: 12)),
                                  onPressed: () => settingsCtrl.revealInFinder(),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.drive_file_move_outline, size: 14),
                                  label: const Text('Change Storage Folder', style: TextStyle(fontSize: 12)),
                                  onPressed: () async {
                                    final path = await settingsCtrl.changeDatabaseLocationDialog();
                                    if (path != null && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Database moved to: $path')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.macosBlue),
                        icon: const Icon(Icons.backup_outlined, size: 16),
                        label: const Text('Export Backup (.xlsx)'),
                        onPressed: () async {
                          final path = await settingsCtrl.exportBackupDialog();
                          if (path != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Backup exported to $path')),
                            );
                          }
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.restore_outlined, size: 16),
                        label: const Text('Restore from Backup'),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Restore Backup?'),
                              content: const Text(
                                'Restoring from a backup will replace current application data with the backup file. A temporary safety backup will be created first.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Proceed with Restore'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final ok = await settingsCtrl.restoreBackupDialog();
                            if (ok) {
                              await appCtrl.loadData();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Data restored successfully!')),
                                );
                              }
                            }
                          }
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('Export CSV'),
                        onPressed: () async {
                          final path = await settingsCtrl.exportCsvDialog(appCtrl.applications);
                          if (path != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('CSV exported to $path')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
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
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
