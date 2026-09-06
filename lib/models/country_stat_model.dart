class CountryStatModel {
  final String country;
  final String flag;
  final int applicationsCount;
  final int submittedCount;
  final int acceptedCount;
  final int rejectedCount;
  final int pendingCount;
  final int upcomingDeadlinesCount;
  final double estimatedTuition;

  const CountryStatModel({
    required this.country,
    this.flag = '🌍',
    this.applicationsCount = 0,
    this.submittedCount = 0,
    this.acceptedCount = 0,
    this.rejectedCount = 0,
    this.pendingCount = 0,
    this.upcomingDeadlinesCount = 0,
    this.estimatedTuition = 0.0,
  });

  static const Map<String, String> countryFlags = {
    'Germany': '🇩🇪',
    'Italy': '🇮🇹',
    'France': '🇫🇷',
    'United Kingdom': '🇬🇧',
    'United States': '🇺🇸',
    'Canada': '🇨🇦',
    'Australia': '🇦🇺',
    'Netherlands': '🇳🇱',
    'Sweden': '🇸🇪',
    'Finland': '🇫🇮',
    'Denmark': '🇩🇰',
    'Norway': '🇳🇴',
    'Austria': '🇦🇹',
    'Poland': '🇵🇱',
    'Spain': '🇪🇸',
    'Portugal': '🇵🇹',
    'Ireland': '🇮🇪',
    'Switzerland': '🇨🇭',
    'Belgium': '🇧🇪',
    'Hungary': '🇭🇺',
    'Czech Republic': '🇨🇿',
    'Japan': '🇯🇵',
    'South Korea': '🇰🇷',
    'China': '🇨🇳',
    'Turkey': '🇹🇷',
    'Singapore': '🇸🇬',
    'New Zealand': '🇳🇿',
    'Other': '🌐',
  };

  static String getFlag(String countryName) {
    return countryFlags[countryName] ?? '🌍';
  }
}
