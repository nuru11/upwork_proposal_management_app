import '../models/template.dart';
import 'api_client.dart';

class TemplateApi {
  TemplateApi(this._client);

  final ApiClient _client;

  Future<void> upsert(ProposalTemplate template) async {
    await _client.postJson('/api/templates', template.toJson());
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/templates/$id');
  }
}
