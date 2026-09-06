import 'package:flutter/material.dart';

class AppSettingsModel {
  // Personal
  final String studentName;
  final String defaultEmail;
  final double currentIeltsScore;
  final double currentGpa;
  final String currentDegree;
  final String graduationYear;

  // Application Defaults
  final String defaultCountry;
  final String defaultIntake;
  final String defaultCurrency; // EUR (€), USD ($), GBP (£), CAD (CA$), AUD (A$), CHF (CHF)

  // Appearance
  final ThemeMode themeMode; // system, light, dark

  // Reminders
  final bool deadlineReminders;
  final bool scholarshipReminders;
  final bool interviewReminders;
  final bool decisionReminders;

  // Custom data file path (optional override)
  final String customExcelPath;

  const AppSettingsModel({
    this.studentName = 'Student',
    this.defaultEmail = '',
    this.currentIeltsScore = 7.5,
    this.currentGpa = 3.7,
    this.currentDegree = "Bachelor of Science",
    this.graduationYear = '2025',
    this.defaultCountry = 'Germany',
    this.defaultIntake = 'Fall',
    this.defaultCurrency = 'EUR',
    this.themeMode = ThemeMode.system,
    this.deadlineReminders = true,
    this.scholarshipReminders = true,
    this.interviewReminders = true,
    this.decisionReminders = true,
    this.customExcelPath = '',
  });

  String get currencySymbol {
    switch (defaultCurrency) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'CAD':
        return 'CA\$';
      case 'AUD':
        return 'A\$';
      case 'CHF':
        return 'CHF ';
      case 'JPY':
        return '¥';
      default:
        return '€';
    }
  }

  Map<String, String> toMap() {
    return {
      'studentName': studentName,
      'defaultEmail': defaultEmail,
      'currentIeltsScore': currentIeltsScore.toString(),
      'currentGpa': currentGpa.toString(),
      'currentDegree': currentDegree,
      'graduationYear': graduationYear,
      'defaultCountry': defaultCountry,
      'defaultIntake': defaultIntake,
      'defaultCurrency': defaultCurrency,
      'themeMode': themeMode.name,
      'deadlineReminders': deadlineReminders.toString(),
      'scholarshipReminders': scholarshipReminders.toString(),
      'interviewReminders': interviewReminders.toString(),
      'decisionReminders': decisionReminders.toString(),
      'customExcelPath': customExcelPath,
    };
  }

  factory AppSettingsModel.fromMap(Map<String, String> map) {
    ThemeMode parseTheme(String? val) {
      if (val == 'light') return ThemeMode.light;
      if (val == 'dark') return ThemeMode.dark;
      return ThemeMode.system;
    }

    return AppSettingsModel(
      studentName: map['studentName'] ?? 'Student',
      defaultEmail: map['defaultEmail'] ?? '',
      currentIeltsScore: double.tryParse(map['currentIeltsScore'] ?? '') ?? 7.5,
      currentGpa: double.tryParse(map['currentGpa'] ?? '') ?? 3.7,
      currentDegree: map['currentDegree'] ?? "Bachelor of Science",
      graduationYear: map['graduationYear'] ?? '2025',
      defaultCountry: map['defaultCountry'] ?? 'Germany',
      defaultIntake: map['defaultIntake'] ?? 'Fall',
      defaultCurrency: map['defaultCurrency'] ?? 'EUR',
      themeMode: parseTheme(map['themeMode']),
      deadlineReminders: map['deadlineReminders'] != 'false',
      scholarshipReminders: map['scholarshipReminders'] != 'false',
      interviewReminders: map['interviewReminders'] != 'false',
      decisionReminders: map['decisionReminders'] != 'false',
      customExcelPath: map['customExcelPath'] ?? '',
    );
  }

  AppSettingsModel copyWith({
    String? studentName,
    String? defaultEmail,
    double? currentIeltsScore,
    double? currentGpa,
    String? currentDegree,
    String? graduationYear,
    String? defaultCountry,
    String? defaultIntake,
    String? defaultCurrency,
    ThemeMode? themeMode,
    bool? deadlineReminders,
    bool? scholarshipReminders,
    bool? interviewReminders,
    bool? decisionReminders,
    String? customExcelPath,
  }) {
    return AppSettingsModel(
      studentName: studentName ?? this.studentName,
      defaultEmail: defaultEmail ?? this.defaultEmail,
      currentIeltsScore: currentIeltsScore ?? this.currentIeltsScore,
      currentGpa: currentGpa ?? this.currentGpa,
      currentDegree: currentDegree ?? this.currentDegree,
      graduationYear: graduationYear ?? this.graduationYear,
      defaultCountry: defaultCountry ?? this.defaultCountry,
      defaultIntake: defaultIntake ?? this.defaultIntake,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      themeMode: themeMode ?? this.themeMode,
      deadlineReminders: deadlineReminders ?? this.deadlineReminders,
      scholarshipReminders: scholarshipReminders ?? this.scholarshipReminders,
      interviewReminders: interviewReminders ?? this.interviewReminders,
      decisionReminders: decisionReminders ?? this.decisionReminders,
      customExcelPath: customExcelPath ?? this.customExcelPath,
    );
  }
}
