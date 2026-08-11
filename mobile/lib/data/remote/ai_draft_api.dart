import '../models/ai_draft.dart';
import 'api_client.dart';

class AiDraftApi {
  AiDraftApi(this._client);

  final ApiClient _client;

  Future<void> upsert(AiDraft draft) async {
    await _client.postJson('/api/ai-drafts', draft.toJson());
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/ai-drafts/$id');
  }
}
