class EmailAccountModel {
  final String id;
  final String emailAddress;
  final String type; // Personal, University, Other
  final String notes;

  const EmailAccountModel({
    required this.id,
    required this.emailAddress,
    this.type = 'Personal',
    this.notes = '',
  });

  EmailAccountModel copyWith({
    String? id,
    String? emailAddress,
    String? type,
    String? notes,
  }) {
    return EmailAccountModel(
      id: id ?? this.id,
      emailAddress: emailAddress ?? this.emailAddress,
      type: type ?? this.type,
      notes: notes ?? this.notes,
    );
  }
}
