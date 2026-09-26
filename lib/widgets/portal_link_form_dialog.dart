import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../controllers/application_controller.dart';
import '../models/portal_link_model.dart';
import '../theme/app_theme.dart';

Future<PortalLinkModel?> showPortalLinkFormDialog(
  BuildContext context, {
  PortalLinkModel? initialLink,
}) {
  return showDialog<PortalLinkModel>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _PortalLinkFormDialogContent(initialLink: initialLink),
  );
}

class _PortalLinkFormDialogContent extends StatefulWidget {
  final PortalLinkModel? initialLink;

  const _PortalLinkFormDialogContent({this.initialLink});

  @override
  State<_PortalLinkFormDialogContent> createState() => _PortalLinkFormDialogContentState();
}

class _PortalLinkFormDialogContentState extends State<_PortalLinkFormDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  late final TextEditingController _descriptionController;

  late String _selectedCategory;
  late String _selectedCountry;
  late bool _isPinned;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Application Portal',
    'Scholarship Portal',
    'Language & Tests',
    'Visa & Immigration',
    'University Official',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final link = widget.initialLink;
    _titleController = TextEditingController(text: link?.title ?? '');
    _urlController = TextEditingController(text: link?.url ?? '');
    _descriptionController = TextEditingController(text: link?.description ?? '');

    _selectedCategory = link != null && _categories.contains(link.category)
        ? link.category
        : _categories.first;
    _selectedCountry = link?.country ?? '';
    _isPinned = link?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _normalizeUrl(String input) {
    var trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    return trimmed;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final controller = Provider.of<ApplicationController>(context, listen: false);
      final now = DateTime.now().toIso8601String();
      final normalizedUrl = _normalizeUrl(_urlController.text);

      if (widget.initialLink != null) {
        final updated = widget.initialLink!.copyWith(
          title: _titleController.text.trim(),
          url: normalizedUrl,
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          country: _selectedCountry.trim(),
          isPinned: _isPinned,
          updatedAt: now,
        );
        await controller.updatePortalLink(updated);
        if (mounted) Navigator.of(context).pop(updated);
      } else {
        const uuid = Uuid();
        final newLink = PortalLinkModel(
          id: uuid.v4(),
          title: _titleController.text.trim(),
          url: normalizedUrl,
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          country: _selectedCountry.trim(),
          isPinned: _isPinned,
          createdAt: now,
          updatedAt: now,
        );
        await controller.addPortalLink(newLink);
        if (mounted) Navigator.of(context).pop(newLink);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save link: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialLink != null;
    final appCtrl = Provider.of<ApplicationController>(context);
    final availableCountries = ['Global / All', ...appCtrl.availableCountries];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: isDark ? const Color(0xFF1E2129) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.macosBlue.withAlpha(isDark ? 50 : 25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.language, color: AppTheme.macosBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Portal / Website Link' : 'Add Direct Portal / Website Link',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Save URLs, portals, credentials notes, and direct access information',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    splashRadius: 18,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Title / Portal Name *',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Uni-Assist Portal, UCAS Admissions, DAAD Database',
                          prefixIcon: Icon(Icons.title, size: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title for the portal or website.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Direct URL
                      const Text(
                        'Direct Website URL *',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _urlController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          hintText: 'e.g. https://my.uni-assist.de or www.ucas.com',
                          prefixIcon: Icon(Icons.link, size: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the URL or website link.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Category & Country in Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Category',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedCategory,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: _categories.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat, style: const TextStyle(fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCategory = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Country / Region',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedCountry.isEmpty || !availableCountries.contains(_selectedCountry)
                                      ? 'Global / All'
                                      : _selectedCountry,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: availableCountries.map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Text(c, style: const TextStyle(fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedCountry = val == 'Global / All' ? '' : val;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description / Notes
                      const Text(
                        'Description & Instructions',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Enter details, login hints, credential instructions, or useful notes about this portal...',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pin to Top
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF282C37) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF3B4252) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isPinned ? Icons.star : Icons.star_border,
                              color: _isPinned ? Colors.amber : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pin to Top / Quick Access',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Pinned portals appear at the top of your links dashboard',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _isPinned,
                              activeTrackColor: AppTheme.macosBlue,
                              onChanged: (val) => setState(() => _isPinned = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Modal Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.macosBlue),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isEditing ? 'Save Changes' : 'Add Link'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
