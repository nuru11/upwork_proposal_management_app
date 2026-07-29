import '../models/project.dart';
import 'api_client.dart';

class ProjectApi {
  ProjectApi(this._client);

  final ApiClient _client;

  Future<void> upsert(Project project) async {
    await _client.postJson('/api/projects', project.toJson());
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/projects/$id');
  }
}
