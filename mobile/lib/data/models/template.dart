import 'proposal.dart';

class ProposalTemplate {
  const ProposalTemplate({
    required this.id,
    required this.name,
    required this.body,
    required this.language,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String body;
  final ProposalLanguage language;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProposalTemplate copyWith({
    String? id,
    String? name,
    String? body,
    ProposalLanguage? language,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProposalTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      body: body ?? this.body,
      language: language ?? this.language,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'body': body,
      'language': language.name,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProposalTemplate.fromMap(Map<String, Object?> map) {
    return ProposalTemplate(
      id: map['id'] as String,
      name: map['name'] as String,
      body: map['body'] as String,
      language: ProposalLanguage.fromStorage(map['language'] as String),
      isFavorite: (map['is_favorite'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'body': body,
      'language': language.name,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProposalTemplate.fromJson(Map<String, dynamic> json) {
    return ProposalTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      body: json['body'] as String,
      language: ProposalLanguage.fromStorage(json['language'] as String),
      isFavorite: json['isFavorite'] == true || json['isFavorite'] == 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
