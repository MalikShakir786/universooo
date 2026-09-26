class PortalLinkModel {
  final String id;
  final String title;
  final String url;
  final String description;
  final String category; // Application Portal, Scholarship, Language & Tests, Visa & Embassy, University Official, Other
  final String country;
  final bool isPinned;
  final String createdAt;
  final String updatedAt;

  const PortalLinkModel({
    required this.id,
    required this.title,
    required this.url,
    this.description = '',
    this.category = 'Application Portal',
    this.country = '',
    this.isPinned = false,
    this.createdAt = '',
    this.updatedAt = '',
  });

  PortalLinkModel copyWith({
    String? id,
    String? title,
    String? url,
    String? description,
    String? category,
    String? country,
    bool? isPinned,
    String? createdAt,
    String? updatedAt,
  }) {
    return PortalLinkModel(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      description: description ?? this.description,
      category: category ?? this.category,
      country: country ?? this.country,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'description': description,
      'category': category,
      'country': country,
      'isPinned': isPinned ? 'true' : 'false',
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory PortalLinkModel.fromMap(Map<String, dynamic> map) {
    return PortalLinkModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Application Portal',
      country: map['country']?.toString() ?? '',
      isPinned: map['isPinned']?.toString().toLowerCase() == 'true',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}
