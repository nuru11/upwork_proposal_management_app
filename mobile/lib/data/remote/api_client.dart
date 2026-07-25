import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession({required this.token, required this.username});

  final String token;
  final String username;
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    FlutterSecureStorage? storage,
    String? baseUrl,
  })  : _http = httpClient ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage(),
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'auth_username';

  final http.Client _http;
  final FlutterSecureStorage _storage;
  final String baseUrl;

  String? _token;

  Future<void> loadToken() async {
    _token = await _storage.read(key: _tokenKey);
  }

  Future<bool> get hasToken async {
    if (_token != null && _token!.isNotEmpty) return true;
    await loadToken();
    return _token != null && _token!.isNotEmpty;
  }

  Future<String?> get username async {
    return _storage.read(key: _usernameKey);
  }

  Future<AuthSession> login(String username, String password) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final body = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        body['error']?.toString() ?? 'Login failed',
        statusCode: response.statusCode,
      );
    }

    final token = body['token'] as String;
    final user = body['user'] as Map<String, dynamic>? ?? {};
    final resolvedUsername = user['username']?.toString() ?? username;

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: resolvedUsername);
    _token = token;

    return AuthSession(token: token, username: resolvedUsername);
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _send('GET', path);
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _send('POST', path, body: body);
    return _decode(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _send('PUT', path, body: body);
    return _decode(response);
  }

  Future<void> delete(String path) async {
    final response = await _send('DELETE', path);
    if (response.statusCode == 204 || response.body.isEmpty) return;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decode(response);
      throw ApiException(
        body['error']?.toString() ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    await loadToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
    };

    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    switch (method) {
      case 'GET':
        response = await _http.get(uri, headers: headers);
      case 'POST':
        response = await _http.post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        );
      case 'PUT':
        response = await _http.put(
          uri,
          headers: headers,
          body: jsonEncode(body),
        );
      case 'DELETE':
        response = await _http.delete(uri, headers: headers);
      default:
        throw ApiException('Unsupported method $method');
    }

    if (response.statusCode == 401) {
      throw ApiException('Unauthorized', statusCode: 401);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _decode(response);
      throw ApiException(
        decoded['error']?.toString() ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return {};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }
}
