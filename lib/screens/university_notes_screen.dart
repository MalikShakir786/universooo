import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../theme/app_theme.dart';
import '../services/university_note_service.dart';

class UniversityNotesScreen extends StatefulWidget {
  const UniversityNotesScreen({super.key});

  @override
  State<UniversityNotesScreen> createState() => _UniversityNotesScreenState();
}

class _UniversityNotesScreenState extends State<UniversityNotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UniversityNoteModel> _savedNotes = [];
  bool _isLoading = true;
  String _expandedUniversity = '';
  String? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final notes = await UniversityNoteService.loadNotes();
    setState(() {
      _savedNotes = notes;
      _isLoading = false;
    });
  }

  Future<void> _saveNote(String university, String details) async {
    final index = _savedNotes.indexWhere((n) => n.universityName == university);
    if (index >= 0) {
      _savedNotes[index] = UniversityNoteModel(universityName: university, details: details);
    } else {
      _savedNotes.add(UniversityNoteModel(universityName: university, details: details));
    }
    await UniversityNoteService.saveNotes(_savedNotes);
    if (mounted) setState(() {});
  }

  void _showAddUniversityDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New University'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'University Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  _saveNote(name, '');
                  setState(() {
                    _expandedUniversity = name;
                    _searchController.clear();
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Provider.of<ApplicationController>(context);

    final Set<String> allUniversities = {};
    final Map<String, String> universityToCountry = {};
    for (var app in controller.applications) {
      if (app.universityName.trim().isNotEmpty) {
        allUniversities.add(app.universityName.trim());
        if (app.country.trim().isNotEmpty) {
          universityToCountry[app.universityName.trim()] = app.country.trim();
        }
      }
    }
    for (var note in _savedNotes) {
      if (note.universityName.trim().isNotEmpty) {
        allUniversities.add(note.universityName.trim());
      }
    }

    final query = _searchController.text.toLowerCase();
    List<String> displayList = allUniversities.toList();
    
    final availableCountries = universityToCountry.values.toSet().toList()..sort();

    if (_selectedCountry != null) {
      displayList = displayList.where((u) {
        return universityToCountry[u] == _selectedCountry;
      }).toList();
    }

    if (query.isNotEmpty && !displayList.any((u) => u.toLowerCase() == query)) {
      displayList.insert(0, _searchController.text.trim());
    }

    displayList = displayList.where((u) => u.toLowerCase().contains(query)).toList();
    displayList.sort((a, b) => a.compareTo(b));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121316) : const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book, color: AppTheme.macosBlue, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Universities & Notes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.macosBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add University'),
                  onPressed: _showAddUniversityDialog,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search or add university to notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isNotEmpty ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ) : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E2129) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: isDark ? const BorderSide(color: Color(0xFF2E3340)) : const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: isDark ? const BorderSide(color: Color(0xFF2E3340)) : const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (val) => setState(() {}),
            ),
            if (availableCountries.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableCountries.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCountry == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: const Text('All Countries', style: TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCountry = null),
                          visualDensity: VisualDensity.compact,
                          selectedColor: AppTheme.macosBlue.withAlpha(isDark ? 80 : 40),
                          checkmarkColor: isDark ? Colors.white : AppTheme.macosBlue,
                        ),
                      );
                    }
                    final country = availableCountries[index - 1];
                    final isSelected = _selectedCountry == country;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(country, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCountry = country),
                        visualDensity: VisualDensity.compact,
                        selectedColor: AppTheme.macosBlue.withAlpha(isDark ? 80 : 40),
                        checkmarkColor: isDark ? Colors.white : AppTheme.macosBlue,
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final univ = displayList[index];
                  final noteObj = _savedNotes.firstWhere((n) => n.universityName == univ, orElse: () => UniversityNoteModel(universityName: univ, details: ''));
                  final isExpanded = _expandedUniversity == univ;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isDark ? const Color(0xFF1E2129) : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isDark ? const Color(0xFF2E3340) : const Color(0xFFE2E8F0)),
                    ),
                    child: ExpansionTile(
                      key: Key(univ),
                      title: Text(univ, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      initiallyExpanded: isExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          if (expanded) {
                            _expandedUniversity = univ;
                          } else if (_expandedUniversity == univ) {
                            _expandedUniversity = '';
                          }
                        });
                      },
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            initialValue: noteObj.details,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              hintText: 'Enter university details, research notes, etc...',
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontSize: 14),
                            onChanged: (val) {
                              _saveNote(univ, val);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
