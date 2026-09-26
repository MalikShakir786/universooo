import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/application_controller.dart';
import '../models/portal_link_model.dart';
import '../theme/app_theme.dart';
import '../widgets/portal_link_form_dialog.dart';

class PortalsScreen extends StatefulWidget {
  const PortalsScreen({super.key});

  @override
  State<PortalsScreen> createState() => _PortalsScreenState();
}

class _PortalsScreenState extends State<PortalsScreen> {
  String _selectedCategoryFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categoryFilters = [
    'All',
    'Pinned',
    'Application Portal',
    'Scholarship Portal',
    'Language & Tests',
    'Visa & Immigration',
    'University Official',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(BuildContext context, String rawUrl) async {
    var urlStr = rawUrl.trim();
    if (urlStr.isEmpty) return;

    if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
      urlStr = 'https://$urlStr';
    }

    final uri = Uri.tryParse(urlStr);
    bool launched = false;

    if (uri != null) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }
    }

    // Desktop native fallback if url_launcher fails
    if (!launched) {
      try {
        if (Platform.isMacOS) {
          final res = await Process.run('open', [urlStr]);
          launched = res.exitCode == 0;
        } else if (Platform.isWindows) {
          final res = await Process.run('cmd', ['/c', 'start', '', urlStr]);
          launched = res.exitCode == 0;
        } else if (Platform.isLinux) {
          final res = await Process.run('xdg-open', [urlStr]);
          launched = res.exitCode == 0;
        }
      } catch (_) {}
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open "$urlStr". Check the URL format.'),
          backgroundColor: AppTheme.macosRed,
        ),
      );
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Copied "$text" to clipboard.')),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete(BuildContext context, PortalLinkModel link) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Portal Link'),
        content: Text('Are you sure you want to delete "${link.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.macosRed),
            onPressed: () {
              Provider.of<ApplicationController>(context, listen: false).deletePortalLink(link.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Application Portal':
        return Icons.school;
      case 'Scholarship Portal':
        return Icons.monetization_on;
      case 'Language & Tests':
        return Icons.spellcheck;
      case 'Visa & Immigration':
        return Icons.badge;
      case 'University Official':
        return Icons.account_balance;
      default:
        return Icons.language;
    }
  }

  Color _getCategoryColor(String category, bool isDark) {
    switch (category) {
      case 'Application Portal':
        return AppTheme.macosBlue;
      case 'Scholarship Portal':
        return AppTheme.macosGreen;
      case 'Language & Tests':
        return AppTheme.macosPurple;
      case 'Visa & Immigration':
        return AppTheme.macosOrange;
      case 'University Official':
        return AppTheme.macosIndigo;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Provider.of<ApplicationController>(context);
    final allLinks = controller.portalLinks;

    // Filter links
    final filteredLinks = allLinks.where((link) {
      // Category filter
      if (_selectedCategoryFilter == 'Pinned') {
        if (!link.isPinned) return false;
      } else if (_selectedCategoryFilter != 'All') {
        if (link.category != _selectedCategoryFilter) return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = link.title.toLowerCase().contains(q);
        final matchDesc = link.description.toLowerCase().contains(q);
        final matchUrl = link.url.toLowerCase().contains(q);
        final matchCat = link.category.toLowerCase().contains(q);
        final matchCountry = link.country.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchUrl && !matchCat && !matchCountry) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort: pinned first, then alphabetical by title
    filteredLinks.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    final totalCount = allLinks.length;
    final pinnedCount = allLinks.where((l) => l.isPinned).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121316) : const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Direct Portals & Links',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.macosBlue.withAlpha(isDark ? 50 : 25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.macosBlue.withAlpha(80)),
                          ),
                          child: Text(
                            '$totalCount links ($pinnedCount pinned)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.macosBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Direct one-click access to application portals, scholarship boards, and university websites',
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
                  label: const Text('Add Direct Link', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () => showPortalLinkFormDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Controls: Search & Category Chips
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2129) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Input
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search portals by title, description, URL, country...',
                              hintStyle: const TextStyle(fontSize: 13),
                              prefixIcon: const Icon(Icons.search, size: 18),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categoryFilters.map((cat) {
                        final isSelected = _selectedCategoryFilter == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.grey[300] : const Color(0xFF334155)),
                              ),
                            ),
                            selectedColor: AppTheme.macosBlue,
                            backgroundColor: isDark ? const Color(0xFF282C37) : const Color(0xFFF1F5F9),
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.macosBlue
                                  : (isDark ? const Color(0xFF3B4252) : const Color(0xFFCBD5E1)),
                            ),
                            onSelected: (_) => setState(() => _selectedCategoryFilter = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Content Area: Grid of Portal Cards or Empty State
            Expanded(
              child: filteredLinks.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Responsive columns: 1 column if narrow, 2 if medium, 3 if wide
                        int crossAxisCount = 1;
                        if (constraints.maxWidth > 1150) {
                          crossAxisCount = 3;
                        } else if (constraints.maxWidth > 750) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: crossAxisCount == 1 ? 2.8 : 1.55,
                          ),
                          itemCount: filteredLinks.length,
                          itemBuilder: (context, index) {
                            final link = filteredLinks[index];
                            return _buildPortalCard(context, link, isDark);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2129) : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.link_off,
              size: 36,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Direct Portals or Links Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'No portals matched your search terms.'
                : 'Add application portals, official websites, and resources for quick access.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.macosBlue),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add First Portal Link'),
            onPressed: () => showPortalLinkFormDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalCard(BuildContext context, PortalLinkModel link, bool isDark) {
    final catColor = _getCategoryColor(link.category, isDark);
    final catIcon = _getCategoryIcon(link.category);
    final controller = Provider.of<ApplicationController>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2129) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: link.isPinned
              ? AppTheme.macosBlue.withAlpha(isDark ? 120 : 90)
              : (isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0)),
          width: link.isPinned ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category Icon, Title, Pin & Options
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: catColor.withAlpha(isDark ? 50 : 25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(catIcon, color: catColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: catColor.withAlpha(isDark ? 45 : 25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            link.category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: catColor,
                            ),
                          ),
                        ),
                        // Country Badge
                        if (link.country.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF282C37) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.public, size: 10, color: Colors.grey),
                                const SizedBox(width: 3),
                                Text(
                                  link.country,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Pin star toggle
              IconButton(
                icon: Icon(
                  link.isPinned ? Icons.star : Icons.star_border,
                  color: link.isPinned ? Colors.amber : (isDark ? Colors.grey[600] : Colors.grey[400]),
                  size: 20,
                ),
                splashRadius: 18,
                tooltip: link.isPinned ? 'Unpin' : 'Pin to top',
                onPressed: () => controller.togglePinPortalLink(link.id),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description
          Expanded(
            child: Text(
              link.description.isNotEmpty ? link.description : 'No description provided.',
              style: TextStyle(
                fontSize: 12,
                color: link.description.isNotEmpty
                    ? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),

          // Direct URL with Copy button
          InkWell(
            onTap: () => _copyToClipboard(context, link.url),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14161C) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? const Color(0xFF282C37) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      link.url,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Tooltip(
                    message: 'Copy URL',
                    child: Icon(Icons.copy, size: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Action Row: Open Website Button, Edit, Delete
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.macosBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Open Website', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: () => _openUrl(context, link.url),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Icon(Icons.edit_outlined, size: 14),
                onPressed: () => showPortalLinkFormDialog(context, initialLink: link),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.macosRed,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Icon(Icons.delete_outline, size: 14),
                onPressed: () => _confirmDelete(context, link),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
