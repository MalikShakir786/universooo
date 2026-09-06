class ScholarshipModel {
  final String id;
  final String applicationId;
  final String scholarshipName;
  final double amount;
  final String deadline;
  final String eligibility;
  final String status; // Researching, Eligible, Preparing, Applied, Under Review, Awarded, Rejected
  final String notes;

  const ScholarshipModel({
    required this.id,
    required this.applicationId,
    required this.scholarshipName,
    this.amount = 0.0,
    this.deadline = '',
    this.eligibility = '',
    this.status = 'Researching',
    this.notes = '',
  });

  ScholarshipModel copyWith({
    String? id,
    String? applicationId,
    String? scholarshipName,
    double? amount,
    String? deadline,
    String? eligibility,
    String? status,
    String? notes,
  }) {
    return ScholarshipModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      scholarshipName: scholarshipName ?? this.scholarshipName,
      amount: amount ?? this.amount,
      deadline: deadline ?? this.deadline,
      eligibility: eligibility ?? this.eligibility,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
