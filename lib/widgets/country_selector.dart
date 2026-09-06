import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../models/country_stat_model.dart';
import '../theme/app_theme.dart';
import 'add_country_dialog.dart';

class CountrySelector extends StatelessWidget {
  final String? selectedCountry;
  final Function(String?) onCountrySelected;
  final List<String>? activeCountries;
  final VoidCallback? onAddCountry;

  const CountrySelector({
    super.key,
    required this.selectedCountry,
    required this.onCountrySelected,
    this.activeCountries,
    this.onAddCountry,
  });

  void _handleAddCountry(BuildContext context) async {
    if (onAddCountry != null) {
      onAddCountry!();
      return;
    }
    final newCountry = await showAddCountryDialog(
      context,
      onCountryAdded: (added) {
        onCountrySelected(added);
      },
    );
    if (newCountry != null) {
      onCountrySelected(newCountry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAllSelected = selectedCountry == null ||
        selectedCountry == 'All Countries' ||
        selectedCountry!.isEmpty;

    final appCtrl = Provider.of<ApplicationController>(context);
    final countries = activeCountries ?? appCtrl.availableCountries;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public, size: 18, color: AppTheme.macosBlue),
                  const SizedBox(width: 8),
                  const Text(
                    'Filter by Destination Country',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (selectedCountry != null && selectedCountry != 'All Countries') ...[
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => onCountrySelected(null),
                      child: const Text('Show All', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
              // Prominent + Add Country Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.macosBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 15),
                label: const Text('+ Add Country', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: () => _handleAddCountry(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "All Countries" Option Pill
                _buildCountryPill(
                  label: 'All Countries',
                  flag: '🌍',
                  isSelected: isAllSelected,
                  onTap: () => onCountrySelected(null),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),

                // User-added countries only (No hardcoded world country list)
                ...countries.map((country) {
                  final selected = selectedCountry != null &&
                      selectedCountry!.toLowerCase() == country.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCountryPill(
                      label: country,
                      flag: CountryStatModel.getFlag(country),
                      isSelected: selected,
                      onTap: () => onCountrySelected(country),
                      isDark: isDark,
                    ),
                  );
                }),

                // Inline "+ Add Country" Pill
                InkWell(
                  onTap: () => _handleAddCountry(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF282B35) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.macosBlue.withAlpha(120),
                        style: BorderStyle.solid,
                        width: 1.2,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14, color: AppTheme.macosBlue),
                        SizedBox(width: 4),
                        Text(
                          'Add Country',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.macosBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (countries.isEmpty) ...[
                  const SizedBox(width: 12),
                  Text(
                    'No destination countries added yet. Click "+ Add Country" to add one.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryPill({
    required String label,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.macosBlue
              : (isDark ? const Color(0xFF282B35) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.macosBlue
                : (isDark ? const Color(0xFF3B404E) : const Color(0xFFCBD5E1)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
