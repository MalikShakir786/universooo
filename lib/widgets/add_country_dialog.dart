import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/application_controller.dart';
import '../models/country_stat_model.dart';
import '../theme/app_theme.dart';

/// Mac-style modal dialog to add a new destination country.
Future<String?> showAddCountryDialog(
  BuildContext context, {
  Function(String addedCountry)? onCountryAdded,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _AddCountryDialogContent(onCountryAdded: onCountryAdded),
  );
}

class _AddCountryDialogContent extends StatefulWidget {
  final Function(String)? onCountryAdded;

  const _AddCountryDialogContent({this.onCountryAdded});

  @override
  State<_AddCountryDialogContent> createState() => _AddCountryDialogContentState();
}

class _AddCountryDialogContentState extends State<_AddCountryDialogContent> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _currentFlag = '🌍';
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    final detectedFlag = CountryStatModel.getFlag(text);
    if (detectedFlag != _currentFlag) {
      setState(() {
        _currentFlag = detectedFlag;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final countryName = _controller.text.trim();
    if (countryName.isEmpty) {
      setState(() => _errorMessage = 'Please enter a country name');
      return;
    }

    final appCtrl = Provider.of<ApplicationController>(context, listen: false);

    // Check duplicate
    final alreadyExists = appCtrl.availableCountries.any(
      (c) => c.toLowerCase() == countryName.toLowerCase(),
    );
    if (alreadyExists) {
      setState(() => _errorMessage = '$countryName is already in your country list');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      await appCtrl.addCountry(countryName, flag: _currentFlag);
      widget.onCountryAdded?.call(countryName);

      if (mounted) {
        Navigator.of(context).pop(countryName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $countryName $_currentFlag to target countries'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            width: 380,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save country: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E2129) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 24,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.macosBlue.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _currentFlag,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Destination Country',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track applications and deadlines for this country',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
              const SizedBox(height: 22),

              // Country Name Input
              Text(
                'Country Name',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. United Kingdom, Germany, Japan...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Center(
                      widthFactor: 1.0,
                      child: Text(_currentFlag, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  errorText: _errorMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF3B404E) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => _submit(),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add, size: 16),
                    label: Text(_isSubmitting ? 'Adding...' : 'Add Country'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.macosBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
