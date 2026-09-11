import 'package:flutter_test/flutter_test.dart';
import 'package:university_system/models/application_model.dart';
import 'package:university_system/models/app_settings_model.dart';
import 'package:university_system/models/country_stat_model.dart';

void main() {
  group('ApplicationModel Calculations & Computed Properties', () {
    test('Deadline countdown and urgency categorization', () {
      final now = DateTime.now();
      final in5Days = DateTime(now.year, now.month, now.day + 5).toIso8601String().substring(0, 10);
      final in10Days = DateTime(now.year, now.month, now.day + 10).toIso8601String().substring(0, 10);
      final in25Days = DateTime(now.year, now.month, now.day + 25).toIso8601String().substring(0, 10);
      final in40Days = DateTime(now.year, now.month, now.day + 40).toIso8601String().substring(0, 10);
      final pastDate = DateTime(now.year, now.month, now.day - 5).toIso8601String().substring(0, 10);

      final appCritical = ApplicationModel(
        id: '1',
        universityName: 'Uni A',
        country: 'Germany',
        courseName: 'CS',
        applicationDeadline: in5Days,
      );
      expect(appCritical.urgency, ApplicationUrgency.critical);

      final appUrgent = ApplicationModel(
        id: '2',
        universityName: 'Uni B',
        country: 'UK',
        courseName: 'CS',
        applicationDeadline: in10Days,
      );
      expect(appUrgent.urgency, ApplicationUrgency.urgent);

      final appAttention = ApplicationModel(
        id: '3',
        universityName: 'Uni C',
        country: 'USA',
        courseName: 'CS',
        applicationDeadline: in25Days,
      );
      expect(appAttention.urgency, ApplicationUrgency.attention);

      final appNormal = ApplicationModel(
        id: '4',
        universityName: 'Uni D',
        country: 'Canada',
        courseName: 'CS',
        applicationDeadline: in40Days,
      );
      expect(appNormal.urgency, ApplicationUrgency.normal);

      final appOverdue = ApplicationModel(
        id: '5',
        universityName: 'Uni E',
        country: 'Australia',
        courseName: 'CS',
        applicationDeadline: pastDate,
      );
      expect(appOverdue.urgency, ApplicationUrgency.overdue);

      final appNone = const ApplicationModel(
        id: '6',
        universityName: 'Uni F',
        country: 'Japan',
        courseName: 'CS',
        applicationDeadline: '',
      );
      expect(appNone.urgency, ApplicationUrgency.none);
    });

    test('startOfApplications and compatibility aliases', () {
      const app = ApplicationModel(
        id: '7',
        universityName: 'Oxford',
        country: 'UK',
        courseName: 'CS',
        startOfApplications: '2025-09-01',
        applicationDeadline: '2026-01-15',
      );

      expect(app.startOfApplications, '2025-09-01');
      expect(app.earlyDeadline, '2025-09-01');
      expect(app.startApplicationPeriod, '2025-09-01');

      final updated = app.copyWith(startOfApplications: '2025-10-01');
      expect(updated.startOfApplications, '2025-10-01');
      expect(updated.earlyDeadline, '2025-10-01');

      final updatedViaAlias = app.copyWith(earlyDeadline: '2025-08-15');
      expect(updatedViaAlias.startOfApplications, '2025-08-15');
    });

    test('IELTS score matching calculation', () {
      const appMet = ApplicationModel(
        id: '1',
        universityName: 'TUM',
        country: 'Germany',
        courseName: 'Informatics',
        ieltsRequired: true,
        ieltsOverallRequired: 6.5,
        myIeltsScore: 7.5,
      );
      expect(appMet.isIeltsMet, isTrue);

      const appNotMet = ApplicationModel(
        id: '2',
        universityName: 'Oxford',
        country: 'UK',
        courseName: 'Advanced CS',
        ieltsRequired: true,
        ieltsOverallRequired: 7.5,
        myIeltsScore: 6.5,
      );
      expect(appNotMet.isIeltsMet, isFalse);

      const appNotReq = ApplicationModel(
        id: '3',
        universityName: 'Uni',
        country: 'France',
        courseName: 'Data Science',
        ieltsRequired: false,
      );
      expect(appNotReq.isIeltsMet, isTrue);
    });

    test('Cost tracking and year division calculations', () {
      const app = ApplicationModel(
        id: '1',
        universityName: 'Melbourne',
        country: 'Australia',
        courseName: 'IT',
        duration: '2 Years',
        applicationFee: 100.0,
        tuitionFee: 40000.0,
        livingCost: 15000.0,
        scholarshipAmount: 10000.0,
      );
      // Total = 100 + 40000 + 15000 - 10000 = 45100
      expect(app.estimatedTotalCost, 45100.0);
      expect(app.estimatedCostPerYear, 22550.0);
    });

    test('Application readiness scoring calculation', () {
      const app = ApplicationModel(
        id: '1',
        universityName: 'TUM',
        country: 'Germany',
        courseName: 'CS',
        ieltsRequired: true,
        ieltsOverallRequired: 6.5,
        myIeltsScore: 7.5,
        gpaRequired: 3.0,
        myGpa: 3.8,
        applicationEmail: 'alex@example.com',
        status: 'Preparing',
      );

      final readiness = app.calculateReadiness(
        documentsTotal: 10,
        documentsCompleted: 8,
      );
      // Readiness is a percentage 0 - 100
      expect(readiness, greaterThanOrEqualTo(70));
      expect(readiness, lessThanOrEqualTo(100));
    });
  });

  group('Country and Settings Models', () {
    test('CountryStatModel flags', () {
      expect(CountryStatModel.getFlag('Germany'), '🇩🇪');
      expect(CountryStatModel.getFlag('United Kingdom'), '🇬🇧');
      expect(CountryStatModel.getFlag('United States'), '🇺🇸');
      expect(CountryStatModel.getFlag('Unknown Country'), '🌍');
    });

    test('AppSettingsModel serialization and round-trip', () {
      const original = AppSettingsModel(
        studentName: 'Alex Mercer',
        defaultEmail: 'alex@student.com',
        currentIeltsScore: 8.0,
        currentGpa: 3.9,
        defaultCountry: 'Germany',
        defaultCurrency: 'EUR',
      );

      final map = original.toMap();
      final restored = AppSettingsModel.fromMap(map);

      expect(restored.studentName, 'Alex Mercer');
      expect(restored.defaultEmail, 'alex@student.com');
      expect(restored.currentIeltsScore, 8.0);
      expect(restored.currentGpa, 3.9);
      expect(restored.defaultCountry, 'Germany');
      expect(restored.defaultCurrency, 'EUR');
      expect(restored.currencySymbol, '€');
    });
  });
}
