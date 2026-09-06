class StatusHistoryModel {
  final String id;
  final String applicationId;
  final String date;
  final String previousStatus;
  final String newStatus;
  final String event;
  final String notes;

  const StatusHistoryModel({
    required this.id,
    required this.applicationId,
    required this.date,
    this.previousStatus = '',
    required this.newStatus,
    required this.event,
    this.notes = '',
  });

  StatusHistoryModel copyWith({
    String? id,
    String? applicationId,
    String? date,
    String? previousStatus,
    String? newStatus,
    String? event,
    String? notes,
  }) {
    return StatusHistoryModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      date: date ?? this.date,
      previousStatus: previousStatus ?? this.previousStatus,
      newStatus: newStatus ?? this.newStatus,
      event: event ?? this.event,
      notes: notes ?? this.notes,
    );
  }
}
