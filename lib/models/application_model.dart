enum ApplicationUrgency {
  normal, // > 30 days
  attention, // 15-30 days
  urgent, // 7-14 days
  critical, // 0-6 days
  overdue, // past deadline
  none, // no deadline set
}

class ApplicationModel {
  final String id;
  final String universityName;
  final String country;
  final String city;
  final String universityWebsite;
  final String courseName;
  final String degreeLevel; // Bachelor's, Master's, PhD, Diploma, Other
  final String faculty;
  final String programWebsite;
  final String studyMode; // On Campus, Online, Hybrid
  final String duration;
  final String credits;
  final String language;
  final String intake; // Fall, Spring, Summer, Winter, Other
  final String semesterYear;

  // Deadlines & Dates
  final String applicationDeadline; // YYYY-MM-DD
  final String startOfApplications; // YYYY-MM-DD
  final String scholarshipDeadline;
  final String housingDeadline;
  final String visaDeadline;
  final String decisionDate;
  final String applicationDate;

  // Status & Workflow
  final String status;
  final String priority; // High, Medium, Low
  final String applicationEmail;
  final bool isFavorite;

  // Financial Information
  final double applicationFee;
  final double tuitionFee;
  final double livingCost;
  final double scholarshipAmount;

  // Language Requirements
  final bool ieltsRequired;
  final double ieltsOverallRequired;
  final double ieltsListeningRequired;
  final double ieltsReadingRequired;
  final double ieltsWritingRequired;
  final double ieltsSpeakingRequired;
  final double myIeltsScore;
  final String ieltsStatus;
  final String toeflRequired;
  final String pteRequired;

  // Academic Requirements
  final double gpaRequired;
  final double myGpa;
  final String greRequired;
  final String gmatRequired;
  final bool sopRequired;
  final bool cvRequired;
  final bool recommendationRequired;
  final bool portfolioRequired;
  final bool interviewRequired;

  // Ratings (1 - 5)
  final double universityRating;
  final double academicRating;
  final double costRating;
  final double locationRating;
  final double careerRating;
  final double studentLifeRating;

  // Reviews & Notes
  final String pros;
  final String cons;
  final String personalReview;
  final String generalNotes;

  // Timestamps
  final String createdDate;
  final String lastUpdated;

  const ApplicationModel({
    required this.id,
    required this.universityName,
    required this.country,
    this.city = '',
    this.universityWebsite = '',
    required this.courseName,
    this.degreeLevel = "Master's",
    this.faculty = '',
    this.programWebsite = '',
    this.studyMode = 'On Campus',
    this.duration = '2 Years',
    this.credits = '',
    this.language = 'English',
    this.intake = 'Fall',
    this.semesterYear = '2026',
    this.applicationDeadline = '',
    this.startOfApplications = '',
    this.scholarshipDeadline = '',
    this.housingDeadline = '',
    this.visaDeadline = '',
    this.decisionDate = '',
    this.applicationDate = '',
    this.status = 'Researching',
    this.priority = 'Medium',
    this.applicationEmail = '',
    this.isFavorite = false,
    this.applicationFee = 0.0,
    this.tuitionFee = 0.0,
    this.livingCost = 0.0,
    this.scholarshipAmount = 0.0,
    this.ieltsRequired = false,
    this.ieltsOverallRequired = 0.0,
    this.ieltsListeningRequired = 0.0,
    this.ieltsReadingRequired = 0.0,
    this.ieltsWritingRequired = 0.0,
    this.ieltsSpeakingRequired = 0.0,
    this.myIeltsScore = 0.0,
    this.ieltsStatus = '',
    this.toeflRequired = '',
    this.pteRequired = '',
    this.gpaRequired = 0.0,
    this.myGpa = 0.0,
    this.greRequired = '',
    this.gmatRequired = '',
    this.sopRequired = false,
    this.cvRequired = false,
    this.recommendationRequired = false,
    this.portfolioRequired = false,
    this.interviewRequired = false,
    this.universityRating = 0.0,
    this.academicRating = 0.0,
    this.costRating = 0.0,
    this.locationRating = 0.0,
    this.careerRating = 0.0,
    this.studentLifeRating = 0.0,
    this.pros = '',
    this.cons = '',
    this.personalReview = '',
    this.generalNotes = '',
    this.createdDate = '',
    this.lastUpdated = '',
  });

  /// Calculate days remaining until primary deadline
  int? get daysRemaining {
    if (applicationDeadline.trim().isEmpty) return null;
    try {
      final deadline = DateTime.parse(applicationDeadline);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
      return deadlineDay.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }

  /// Urgency categorization based on days remaining
  ApplicationUrgency get urgency {
    final days = daysRemaining;
    if (days == null) return ApplicationUrgency.none;
    if (days < 0) return ApplicationUrgency.overdue;
    if (days <= 6) return ApplicationUrgency.critical;
    if (days <= 14) return ApplicationUrgency.urgent;
    if (days <= 30) return ApplicationUrgency.attention;
    return ApplicationUrgency.normal;
  }

  /// Human-readable days remaining label
  String get daysRemainingLabel {
    final days = daysRemaining;
    if (days == null) return 'No Deadline';
    if (days < 0) return 'Deadline passed (${days.abs()}d ago)';
    if (days == 0) return 'Deadline today!';
    if (days == 1) return '1 day remaining';
    return '$days days remaining';
  }

  /// Compatibility getters for start of applications
  String get earlyDeadline => startOfApplications;
  String get startApplicationPeriod => startOfApplications;

  /// Whether IELTS score meets the requirement
  bool get isIeltsMet {
    if (!ieltsRequired) return true;
    if (ieltsOverallRequired <= 0) return true;
    if (myIeltsScore <= 0) return false;
    return myIeltsScore >= ieltsOverallRequired;
  }

  /// Whether GPA requirement is met
  bool get isGpaMet {
    if (gpaRequired <= 0) return true;
    if (myGpa <= 0) return false;
    return myGpa >= gpaRequired;
  }

  /// Estimated total cost calculation
  double get estimatedTotalCost {
    final total = applicationFee + tuitionFee + livingCost - scholarshipAmount;
    return total > 0 ? total : 0.0;
  }

  /// Estimated cost per year assuming 2 years if duration is 2
  double get estimatedCostPerYear {
    double durationYears = 1.0;
    if (duration.contains('2')) durationYears = 2.0;
    if (duration.contains('3')) durationYears = 3.0;
    if (duration.contains('4')) durationYears = 4.0;
    if (duration.contains('1.5')) durationYears = 1.5;
    return estimatedTotalCost / durationYears;
  }

  /// Calculate overall application readiness percentage (0 - 100)
  int calculateReadiness({int documentsTotal = 0, int documentsCompleted = 0}) {
    int score = 0;
    int maxScore = 0;

    // 1. Language readiness (20 points)
    maxScore += 20;
    if (!ieltsRequired || isIeltsMet) {
      score += 20;
    } else if (myIeltsScore > 0) {
      score += 10;
    }

    // 2. Academic readiness (20 points)
    maxScore += 20;
    if (gpaRequired <= 0 || isGpaMet) {
      score += 20;
    } else if (myGpa > 0) {
      score += 10;
    }

    // 3. Application Details & Email (20 points)
    maxScore += 20;
    if (applicationEmail.isNotEmpty) score += 10;
    if (status != 'Researching' && status != 'Interested') score += 10;

    // 4. Documents readiness (40 points)
    maxScore += 40;
    if (documentsTotal > 0) {
      score += ((documentsCompleted / documentsTotal) * 40).round();
    } else {
      score += 20; // default baseline if no docs tracked yet
    }

    if (maxScore == 0) return 0;
    return ((score / maxScore) * 100).clamp(0, 100).round();
  }

  ApplicationModel copyWith({
    String? id,
    String? universityName,
    String? country,
    String? city,
    String? universityWebsite,
    String? courseName,
    String? degreeLevel,
    String? faculty,
    String? programWebsite,
    String? studyMode,
    String? duration,
    String? credits,
    String? language,
    String? intake,
    String? semesterYear,
    String? applicationDeadline,
    String? startOfApplications,
    String? earlyDeadline,
    String? startApplicationPeriod,
    String? scholarshipDeadline,
    String? housingDeadline,
    String? visaDeadline,
    String? decisionDate,
    String? applicationDate,
    String? status,
    String? priority,
    String? applicationEmail,
    bool? isFavorite,
    double? applicationFee,
    double? tuitionFee,
    double? livingCost,
    double? scholarshipAmount,
    bool? ieltsRequired,
    double? ieltsOverallRequired,
    double? ieltsListeningRequired,
    double? ieltsReadingRequired,
    double? ieltsWritingRequired,
    double? ieltsSpeakingRequired,
    double? myIeltsScore,
    String? ieltsStatus,
    String? toeflRequired,
    String? pteRequired,
    double? gpaRequired,
    double? myGpa,
    String? greRequired,
    String? gmatRequired,
    bool? sopRequired,
    bool? cvRequired,
    bool? recommendationRequired,
    bool? portfolioRequired,
    bool? interviewRequired,
    double? universityRating,
    double? academicRating,
    double? costRating,
    double? locationRating,
    double? careerRating,
    double? studentLifeRating,
    String? pros,
    String? cons,
    String? personalReview,
    String? generalNotes,
    String? createdDate,
    String? lastUpdated,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      universityName: universityName ?? this.universityName,
      country: country ?? this.country,
      city: city ?? this.city,
      universityWebsite: universityWebsite ?? this.universityWebsite,
      courseName: courseName ?? this.courseName,
      degreeLevel: degreeLevel ?? this.degreeLevel,
      faculty: faculty ?? this.faculty,
      programWebsite: programWebsite ?? this.programWebsite,
      studyMode: studyMode ?? this.studyMode,
      duration: duration ?? this.duration,
      credits: credits ?? this.credits,
      language: language ?? this.language,
      intake: intake ?? this.intake,
      semesterYear: semesterYear ?? this.semesterYear,
      applicationDeadline: applicationDeadline ?? this.applicationDeadline,
      startOfApplications: startOfApplications ??
          startApplicationPeriod ??
          earlyDeadline ??
          this.startOfApplications,
      scholarshipDeadline: scholarshipDeadline ?? this.scholarshipDeadline,
      housingDeadline: housingDeadline ?? this.housingDeadline,
      visaDeadline: visaDeadline ?? this.visaDeadline,
      decisionDate: decisionDate ?? this.decisionDate,
      applicationDate: applicationDate ?? this.applicationDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      applicationEmail: applicationEmail ?? this.applicationEmail,
      isFavorite: isFavorite ?? this.isFavorite,
      applicationFee: applicationFee ?? this.applicationFee,
      tuitionFee: tuitionFee ?? this.tuitionFee,
      livingCost: livingCost ?? this.livingCost,
      scholarshipAmount: scholarshipAmount ?? this.scholarshipAmount,
      ieltsRequired: ieltsRequired ?? this.ieltsRequired,
      ieltsOverallRequired: ieltsOverallRequired ?? this.ieltsOverallRequired,
      ieltsListeningRequired:
          ieltsListeningRequired ?? this.ieltsListeningRequired,
      ieltsReadingRequired: ieltsReadingRequired ?? this.ieltsReadingRequired,
      ieltsWritingRequired: ieltsWritingRequired ?? this.ieltsWritingRequired,
      ieltsSpeakingRequired:
          ieltsSpeakingRequired ?? this.ieltsSpeakingRequired,
      myIeltsScore: myIeltsScore ?? this.myIeltsScore,
      ieltsStatus: ieltsStatus ?? this.ieltsStatus,
      toeflRequired: toeflRequired ?? this.toeflRequired,
      pteRequired: pteRequired ?? this.pteRequired,
      gpaRequired: gpaRequired ?? this.gpaRequired,
      myGpa: myGpa ?? this.myGpa,
      greRequired: greRequired ?? this.greRequired,
      gmatRequired: gmatRequired ?? this.gmatRequired,
      sopRequired: sopRequired ?? this.sopRequired,
      cvRequired: cvRequired ?? this.cvRequired,
      recommendationRequired:
          recommendationRequired ?? this.recommendationRequired,
      portfolioRequired: portfolioRequired ?? this.portfolioRequired,
      interviewRequired: interviewRequired ?? this.interviewRequired,
      universityRating: universityRating ?? this.universityRating,
      academicRating: academicRating ?? this.academicRating,
      costRating: costRating ?? this.costRating,
      locationRating: locationRating ?? this.locationRating,
      careerRating: careerRating ?? this.careerRating,
      studentLifeRating: studentLifeRating ?? this.studentLifeRating,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
      personalReview: personalReview ?? this.personalReview,
      generalNotes: generalNotes ?? this.generalNotes,
      createdDate: createdDate ?? this.createdDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
