import 'dart:convert';

enum ProposalLanguage {
  english,
  arabic;

  String get label => switch (this) {
        ProposalLanguage.english => 'English',
        ProposalLanguage.arabic => 'Arabic',
      };

  static ProposalLanguage fromStorage(String value) {
    return ProposalLanguage.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProposalLanguage.english,
    );
  }
}

enum ProposalStatus {
  submitted,
  viewed,
  responded,
  hired,
  rejected;

  String get label => switch (this) {
        ProposalStatus.submitted => 'Submitted',
        ProposalStatus.viewed => 'Viewed',
        ProposalStatus.responded => 'Responded',
        ProposalStatus.hired => 'Hired',
        ProposalStatus.rejected => 'Rejected',
      };

  static ProposalStatus fromStorage(String value) {
    return ProposalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProposalStatus.submitted,
    );
  }

  static ProposalStatus? _match(String value) {
    for (final status in ProposalStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }

  static List<ProposalStatus> listFromStorage(dynamic value) {
    final names = <String>[];
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.startsWith('[')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            names.addAll(decoded.map((item) => item.toString()));
          }
        } catch (_) {
          final single = _match(trimmed);
          if (single != null) return [single];
        }
      } else if (trimmed.isNotEmpty) {
        names.add(trimmed);
      }
    } else if (value is List) {
      names.addAll(value.map((item) => item.toString()));
    }

    final statuses = <ProposalStatus>[];
    for (final status in ProposalStatus.values) {
      if (names.contains(status.name) && !statuses.contains(status)) {
        statuses.add(status);
      }
    }
    if (statuses.isEmpty) return [ProposalStatus.submitted];
    return statuses;
  }

  static String listToStorage(List<ProposalStatus> statuses) {
    final names = <String>[
      for (final status in ProposalStatus.values)
        if (statuses.contains(status)) status.name,
    ];
    if (names.isEmpty) names.add(ProposalStatus.submitted.name);
    return jsonEncode(names);
  }
}

enum ProposalProjectType {
  mobileApp,
  storeUpload,
  other;

  String get label => switch (this) {
        ProposalProjectType.mobileApp => 'Mobile app',
        ProposalProjectType.storeUpload => 'Play Store & App Store upload',
        ProposalProjectType.other => 'Other',
      };

  static ProposalProjectType fromStorage(String value) {
    return ProposalProjectType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProposalProjectType.other,
    );
  }
}

class Proposal {
  const Proposal({
    required this.id,
    required this.title,
    this.clientName,
    this.jobUrl,
    required this.body,
    required this.language,
    required this.status,
    required this.projectType,
    this.templateId,
    this.notes,
    this.updatedVersion,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
  });

  final String id;
  final String title;
  final String? clientName;
  final String? jobUrl;
  final String body;
  final ProposalLanguage language;
  final List<ProposalStatus> status;
  final ProposalProjectType projectType;
  final String? templateId;
  final String? notes;
  final String? updatedVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;

  Proposal copyWith({
    String? id,
    String? title,
    String? clientName,
    String? jobUrl,
    String? body,
    ProposalLanguage? language,
    List<ProposalStatus>? status,
    ProposalProjectType? projectType,
    String? templateId,
    String? notes,
    String? updatedVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    bool clearClientName = false,
    bool clearJobUrl = false,
    bool clearTemplateId = false,
    bool clearNotes = false,
    bool clearUpdatedVersion = false,
    bool clearSubmittedAt = false,
  }) {
    return Proposal(
      id: id ?? this.id,
      title: title ?? this.title,
      clientName: clearClientName ? null : (clientName ?? this.clientName),
      jobUrl: clearJobUrl ? null : (jobUrl ?? this.jobUrl),
      body: body ?? this.body,
      language: language ?? this.language,
      status: status ?? this.status,
      projectType: projectType ?? this.projectType,
      templateId: clearTemplateId ? null : (templateId ?? this.templateId),
      notes: clearNotes ? null : (notes ?? this.notes),
      updatedVersion: clearUpdatedVersion
          ? null
          : (updatedVersion ?? this.updatedVersion),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: clearSubmittedAt ? null : (submittedAt ?? this.submittedAt),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'client_name': clientName,
      'job_url': jobUrl,
      'body': body,
      'language': language.name,
      'status': ProposalStatus.listToStorage(status),
      'project_type': projectType.name,
      'template_id': templateId,
      'notes': notes,
      'updated_version': updatedVersion,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
    };
  }

  factory Proposal.fromMap(Map<String, Object?> map) {
    return Proposal(
      id: map['id'] as String,
      title: map['title'] as String,
      clientName: map['client_name'] as String?,
      jobUrl: map['job_url'] as String?,
      body: map['body'] as String,
      language: ProposalLanguage.fromStorage(map['language'] as String),
      status: ProposalStatus.listFromStorage(map['status']),
      projectType: ProposalProjectType.fromStorage(
        (map['project_type'] as String?) ?? 'other',
      ),
      templateId: map['template_id'] as String?,
      notes: map['notes'] as String?,
      updatedVersion: map['updated_version'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      submittedAt: map['submitted_at'] != null
          ? DateTime.parse(map['submitted_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'clientName': clientName,
      'jobUrl': jobUrl,
      'body': body,
      'language': language.name,
      'status': status.map((item) => item.name).toList(),
      'projectType': projectType.name,
      'templateId': templateId,
      'notes': notes,
      'updatedVersion': updatedVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
    };
  }

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id'] as String,
      title: json['title'] as String,
      clientName: json['clientName'] as String?,
      jobUrl: json['jobUrl'] as String?,
      body: json['body'] as String,
      language: ProposalLanguage.fromStorage(json['language'] as String),
      status: ProposalStatus.listFromStorage(json['status']),
      projectType: ProposalProjectType.fromStorage(
        (json['projectType'] as String?) ?? 'other',
      ),
      templateId: json['templateId'] as String?,
      notes: json['notes'] as String?,
      updatedVersion: json['updatedVersion'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
    );
  }
}
