import '../models/proposal.dart';
import 'api_client.dart';

class ProposalApi {
  ProposalApi(this._client);

  final ApiClient _client;

  Future<void> upsert(Proposal proposal) async {
    await _client.postJson('/api/proposals', proposal.toJson());
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/proposals/$id');
  }
}
