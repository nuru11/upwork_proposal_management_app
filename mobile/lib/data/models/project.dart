import 'dart:convert';

enum ProjectType {
  ecommerce,
  marketplace,
  elearning,
  booking,
  social,
  delivery,
  fintech,
  healthcare,
  gaming,
  other;

  String get label => switch (this) {
        ProjectType.ecommerce => 'Ecommerce',
        ProjectType.marketplace => 'Marketplace',
        ProjectType.elearning => 'E-learning',
        ProjectType.booking => 'Booking',
        ProjectType.social => 'Social',
        ProjectType.delivery => 'Delivery',
        ProjectType.fintech => 'Fintech',
        ProjectType.healthcare => 'Healthcare',
        ProjectType.gaming => 'Gaming',
        ProjectType.other => 'Other',
      };

  static ProjectType fromStorage(String value) {
    return ProjectType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProjectType.other,
    );
  }

  static List<ProjectType> listFromStorage(dynamic value) {
    List<dynamic> raw;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        raw = decoded is List ? decoded : const [];
      } catch (_) {
        raw = const [];
      }
    } else if (value is List) {
      raw = value;
    } else {
      raw = const [];
    }

    final types = <ProjectType>[];
    for (final item in raw) {
      final type = ProjectType.fromStorage(item.toString());
      if (!types.contains(type)) {
        types.add(type);
      }
    }
    if (types.isEmpty) {
      return [ProjectType.other];
    }
    return types;
  }

  static String listToStorage(List<ProjectType> types) {
    final unique = <String>[];
    for (final type in types) {
      if (!unique.contains(type.name)) {
        unique.add(type.name);
      }
    }
    if (unique.isEmpty) {
      unique.add(ProjectType.other.name);
    }
    return jsonEncode(unique);
  }
}

class Project {
  const Project({
    required this.id,
    required this.name,
    this.playStoreUrl,
    this.appStoreUrl,
    this.webUrl,
    required this.types,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? playStoreUrl;
  final String? appStoreUrl;
  final String? webUrl;
  final List<ProjectType> types;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasPlayStore => playStoreUrl != null && playStoreUrl!.isNotEmpty;
  bool get hasAppStore => appStoreUrl != null && appStoreUrl!.isNotEmpty;
  bool get hasWeb => webUrl != null && webUrl!.isNotEmpty;

  Project copyWith({
    String? id,
    String? name,
    String? playStoreUrl,
    String? appStoreUrl,
    String? webUrl,
    List<ProjectType>? types,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearPlayStoreUrl = false,
    bool clearAppStoreUrl = false,
    bool clearWebUrl = false,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      playStoreUrl:
          clearPlayStoreUrl ? null : (playStoreUrl ?? this.playStoreUrl),
      appStoreUrl: clearAppStoreUrl ? null : (appStoreUrl ?? this.appStoreUrl),
      webUrl: clearWebUrl ? null : (webUrl ?? this.webUrl),
      types: types ?? this.types,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'play_store_url': playStoreUrl,
      'app_store_url': appStoreUrl,
      'web_url': webUrl,
      'types': ProjectType.listToStorage(types),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, Object?> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      playStoreUrl: map['play_store_url'] as String?,
      appStoreUrl: map['app_store_url'] as String?,
      webUrl: map['web_url'] as String?,
      types: ProjectType.listFromStorage(map['types']),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'playStoreUrl': playStoreUrl,
      'appStoreUrl': appStoreUrl,
      'webUrl': webUrl,
      'types': types.map((t) => t.name).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      playStoreUrl: json['playStoreUrl'] as String?,
      appStoreUrl: json['appStoreUrl'] as String?,
      webUrl: json['webUrl'] as String?,
      types: ProjectType.listFromStorage(json['types']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
