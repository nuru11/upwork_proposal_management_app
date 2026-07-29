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
  final ProposalStatus status;
  final ProposalProjectType projectType;
  final String? templateId;
  final String? notes;
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
    ProposalStatus? status,
    ProposalProjectType? projectType,
    String? templateId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    bool clearClientName = false,
    bool clearJobUrl = false,
    bool clearTemplateId = false,
    bool clearNotes = false,
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
      'status': status.name,
      'project_type': projectType.name,
      'template_id': templateId,
      'notes': notes,
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
      status: ProposalStatus.fromStorage(map['status'] as String),
      projectType: ProposalProjectType.fromStorage(
        (map['project_type'] as String?) ?? 'other',
      ),
      templateId: map['template_id'] as String?,
      notes: map['notes'] as String?,
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
      'status': status.name,
      'projectType': projectType.name,
      'templateId': templateId,
      'notes': notes,
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
      status: ProposalStatus.fromStorage(json['status'] as String),
      projectType: ProposalProjectType.fromStorage(
        (json['projectType'] as String?) ?? 'other',
      ),
      templateId: json['templateId'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
    );
  }
}
