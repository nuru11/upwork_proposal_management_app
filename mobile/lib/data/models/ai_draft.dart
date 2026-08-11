import 'dart:convert';

import 'ai_proposal.dart';

class AiDraft {
  const AiDraft({
    required this.id,
    required this.title,
    required this.jobDescription,
    this.notes,
    required this.domain,
    required this.language,
    required this.issues,
    required this.solutions,
    required this.body,
    this.clientName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String jobDescription;
  final String? notes;
  final String domain;
  final String language;
  final List<AiIssue> issues;
  final List<AiSolution> solutions;
  final String body;
  final String? clientName;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get domainLabel {
    for (final d in AiDomain.values) {
      if (d.name == domain) return d.label;
    }
    return domain;
  }

  AiDraft copyWith({
    String? id,
    String? title,
    String? jobDescription,
    String? notes,
    String? domain,
    String? language,
    List<AiIssue>? issues,
    List<AiSolution>? solutions,
    String? body,
    String? clientName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearNotes = false,
    bool clearClientName = false,
  }) {
    return AiDraft(
      id: id ?? this.id,
      title: title ?? this.title,
      jobDescription: jobDescription ?? this.jobDescription,
      notes: clearNotes ? null : (notes ?? this.notes),
      domain: domain ?? this.domain,
      language: language ?? this.language,
      issues: issues ?? this.issues,
      solutions: solutions ?? this.solutions,
      body: body ?? this.body,
      clientName: clearClientName ? null : (clientName ?? this.clientName),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'job_description': jobDescription,
      'notes': notes,
      'domain': domain,
      'language': language,
      'issues': jsonEncode(issues.map((e) => e.toJson()).toList()),
      'solutions': jsonEncode(solutions.map((e) => e.toJson()).toList()),
      'body': body,
      'client_name': clientName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AiDraft.fromMap(Map<String, Object?> map) {
    return AiDraft(
      id: map['id'] as String,
      title: map['title'] as String,
      jobDescription: (map['job_description'] as String?) ?? '',
      notes: map['notes'] as String?,
      domain: (map['domain'] as String?) ?? 'other',
      language: (map['language'] as String?) ?? 'english',
      issues: _issuesFrom(map['issues']),
      solutions: _solutionsFrom(map['solutions']),
      body: (map['body'] as String?) ?? '',
      clientName: map['client_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'jobDescription': jobDescription,
      'notes': notes,
      'domain': domain,
      'language': language,
      'issues': issues.map((e) => e.toJson()).toList(),
      'solutions': solutions.map((e) => e.toJson()).toList(),
      'body': body,
      'clientName': clientName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AiDraft.fromJson(Map<String, dynamic> json) {
    return AiDraft(
      id: json['id'] as String,
      title: json['title'] as String? ?? titleFromJob(json['jobDescription']),
      jobDescription: json['jobDescription']?.toString() ?? '',
      notes: json['notes']?.toString(),
      domain: json['domain']?.toString() ?? 'other',
      language: json['language']?.toString() ?? 'english',
      issues: _issuesFrom(json['issues']),
      solutions: _solutionsFrom(json['solutions']),
      body: json['body']?.toString() ?? '',
      clientName: json['clientName']?.toString(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static String titleFromJob(Object? raw) {
    final text = raw?.toString() ?? '';
    final line = text
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    if (line.isEmpty) return 'Untitled AI draft';
    if (line.length <= 80) return line;
    return '${line.substring(0, 77)}...';
  }

  static List<AiIssue> _issuesFrom(Object? raw) {
    final list = _asList(raw);
    return list
        .whereType<Map>()
        .map((e) => AiIssue.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<AiSolution> _solutionsFrom(Object? raw) {
    final list = _asList(raw);
    return list
        .whereType<Map>()
        .map((e) => AiSolution.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<dynamic> _asList(Object? raw) {
    if (raw is List) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return const [];
  }
}

class ProposalPrefill {
  const ProposalPrefill({
    this.title,
    this.body,
    this.clientName,
    this.language,
  });

  final String? title;
  final String? body;
  final String? clientName;
  final String? language;
}
