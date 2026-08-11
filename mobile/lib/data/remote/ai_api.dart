import '../models/ai_proposal.dart';
import 'api_client.dart';

class AiApi {
  AiApi(this._client);

  final ApiClient _client;

  Future<List<AiIssue>> extractIssues({
    required String jobDescription,
    required String domain,
    required String language,
    String? notes,
  }) async {
    final body = await _client.postJson('/api/ai/extract-issues', {
      'jobDescription': jobDescription,
      'domain': domain,
      'language': language,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    final raw = body['issues'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => AiIssue.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<AiSolution>> suggestSolutions({
    required String jobDescription,
    required String domain,
    required List<AiIssue> issues,
    String? notes,
  }) async {
    final body = await _client.postJson('/api/ai/suggest-solutions', {
      'jobDescription': jobDescription,
      'domain': domain,
      'issues': issues.map((e) => e.toJson()).toList(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    final raw = body['solutions'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => AiSolution.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<String> draftProposal({
    required String jobDescription,
    required String domain,
    required String language,
    required List<AiIssue> issues,
    required List<AiSolution> solutions,
    required List<AiProjectMention> projects,
    String? templateBody,
    String? clientName,
    String? notes,
  }) async {
    final body = await _client.postJson('/api/ai/draft-proposal', {
      'jobDescription': jobDescription,
      'domain': domain,
      'language': language,
      'issues': issues.map((e) => e.toJson()).toList(),
      'solutions': solutions.map((e) => e.toJson()).toList(),
      'projects': projects
          .map(
            (mention) {
              final p = mention.project;
              final note = mention.mentionNote?.trim();
              return {
                'name': p.name,
                'description': p.description,
                'types': p.types.map((t) => t.name).toList(),
                'playStoreUrl': p.playStoreUrl,
                'appStoreUrl': p.appStoreUrl,
                'webUrl': p.webUrl,
                'describe': mention.describe,
                'mentionNote': (note != null && note.isNotEmpty) ? note : null,
              };
            },
          )
          .toList(),
      if (templateBody != null && templateBody.isNotEmpty)
        'templateBody': templateBody,
      if (clientName != null && clientName.isNotEmpty) 'clientName': clientName,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return body['body']?.toString() ?? '';
  }
}
