class DocumentModel {
  final String id;
  final String applicationId;
  final String document;
  final bool required;
  final bool completed;
  final bool submitted;
  final String notes;

  const DocumentModel({
    required this.id,
    required this.applicationId,
    required this.document,
    this.required = true,
    this.completed = false,
    this.submitted = false,
    this.notes = '',
  });

  DocumentModel copyWith({
    String? id,
    String? applicationId,
    String? document,
    bool? required,
    bool? completed,
    bool? submitted,
    String? notes,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      document: document ?? this.document,
      required: required ?? this.required,
      completed: completed ?? this.completed,
      submitted: submitted ?? this.submitted,
      notes: notes ?? this.notes,
    );
  }

  /// Preset checklist documents for quick population
  static List<String> get standardDocumentNames => [
        'Valid Passport',
        'Curriculum Vitae (CV) / Resume',
        "Bachelor's Degree Certificate",
        'Academic Transcripts',
        'IELTS / English Test Certificate',
        'Statement of Purpose (SOP)',
        'Motivation Letter',
        'Letter of Recommendation 1 (Academic)',
        'Letter of Recommendation 2 (Professional/Academic)',
        'Proof of Funds / Bank Statement',
        'Passport Size Photograph',
        'Portfolio / Work Samples',
        'GRE / GMAT Score Report',
        'University Application Form (Signed)',
      ];
}
