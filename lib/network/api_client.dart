import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client _client = http.Client();
  String? _token;
  Future<void> Function()? _onUnauthorized;
  bool _notifyingUnauthorized = false;

  set onUnauthorized(Future<void> Function()? callback) {
    _onUnauthorized = callback;
  }

  void setToken(String? token) {
    _token = (token != null && token.isNotEmpty) ? token : null;
  }

  void clearToken() {
    _token = null;
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) {
    return _send(() {
      return _client.get(uri, headers: _buildHeaders(headers));
    });
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _send(() {
      return _client.post(
        uri,
        headers: _buildHeaders(headers),
        body: body,
        encoding: encoding,
      );
    });
  }

  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _send(() {
      return _client.delete(
        uri,
        headers: _buildHeaders(headers),
        body: body,
        encoding: encoding,
      );
    });
  }

  Future<http.Response> patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _send(() {
      return _client.patch(
        uri,
        headers: _buildHeaders(headers),
        body: body,
        encoding: encoding,
      );
    });
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request();
    } on Exception catch (e) {
      throw Exception('Verbinding mislukt: $e');
    }

    if (response.statusCode == 401 &&
        _token != null &&
        _token!.isNotEmpty &&
        !_notifyingUnauthorized) {
      _notifyingUnauthorized = true;
      try {
        if (_onUnauthorized != null) {
          await _onUnauthorized!.call();
        }
      } finally {
        _notifyingUnauthorized = false;
      }
    }
    return response;
  }

  Map<String, String> _buildHeaders(Map<String, String>? headers) {
    final merged = <String, String>{};
    if (headers != null) {
      merged.addAll(headers);
    }
    if (_token != null && _token!.isNotEmpty) {
      merged['Authorization'] = 'Bearer $_token';
    }
    return merged;
  }
}

final ApiClient apiClient = ApiClient();
