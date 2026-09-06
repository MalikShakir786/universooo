class ContactModel {
  final String id;
  final String applicationId;
  final String department;
  final String contactPerson;
  final String email;
  final String phone;
  final String notes;

  const ContactModel({
    required this.id,
    required this.applicationId,
    this.department = '',
    this.contactPerson = '',
    this.email = '',
    this.phone = '',
    this.notes = '',
  });

  ContactModel copyWith({
    String? id,
    String? applicationId,
    String? department,
    String? contactPerson,
    String? email,
    String? phone,
    String? notes,
  }) {
    return ContactModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      department: department ?? this.department,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
    );
  }
}
