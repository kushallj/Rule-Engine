/// Thin client for the DocFlow REST API (token auth).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/catalog.dart';
import '../models/rule_tree.dart';

class ApiException implements Exception {
  final int? status;
  final String message;
  final dynamic data;   // parsed error body, when there is one
  ApiException(this.message, {this.status, this.data});

  bool get isForbidden => status == 403;
  bool get isUnauthorized => status == 401;

  @override
  String toString() => message;
}

/// Outcome of POST /api/rulesets/test/ (a dry run that saves nothing).
class RuleTestResult {
  final bool valid;
  final bool matched;
  final Map<String, dynamic>? trace;
  final List<String> errors;
  final Map<String, dynamic> facts;

  RuleTestResult({required this.valid, required this.matched, this.trace, this.errors = const [], this.facts = const {}});
}

class DocflowApi {
  final Uri baseUrl;
  final String? token;
  final http.Client _http;

  DocflowApi(String baseUrl, {this.token, http.Client? client})
      : baseUrl = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
        _http = client ?? http.Client();

  DocflowApi withToken(String token) => DocflowApi(baseUrl.toString(), token: token, client: _http);

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      };

  Uri _u(String path, [Map<String, String>? query]) => baseUrl.resolve(path).replace(queryParameters: query);

  Future<dynamic> _send(String method, String path, {Object? body, Map<String, String>? query}) async {
    final req = http.Request(method, _u(path, query))..headers.addAll(_headers);
    if (body != null) req.body = jsonEncode(body);
    late http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(req));
    } catch (e) {
      throw ApiException('Cannot reach DocFlow at $baseUrl. Is the server running? ($e)');
    }
    final text = utf8.decode(res.bodyBytes);
    final data = text.isEmpty ? null : _tryJson(text);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw ApiException(describeError(res.statusCode, data), status: res.statusCode, data: data);
  }

  static dynamic _tryJson(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  /// Turn DRF error bodies ({"tree": ["root.rules[0]...: ..."], "detail": "..."}) into one readable message.
  static String describeError(int status, dynamic data) {
    if (status == 401) return 'Your session has expired. Sign in again.';
    if (status == 403) {
      final detail = data is Map ? data['detail'] : null;
      return detail?.toString() ?? 'You do not have permission to do that. Only admins can change rules.';
    }
    final lines = <String>[];
    void walk(dynamic v, String prefix) {
      if (v is Map) {
        v.forEach((k, val) => walk(val, k == 'detail' || k == 'non_field_errors' ? prefix : '$prefix$k: '));
      } else if (v is List) {
        for (final x in v) {
          walk(x, prefix);
        }
      } else if (v != null) {
        lines.add('$prefix$v');
      }
    }

    walk(data is String && data.length > 300 ? null : data, '');
    return lines.isEmpty ? 'Request failed (HTTP $status)' : lines.join('\n');
  }

  // --- auth ---------------------------------------------------------------

  Future<String> login(String username, String password) async {
    final data = await _send('POST', 'api/auth/token/', body: {'username': username, 'password': password});
    return (data as Map)['token'] as String;
  }

  // --- catalog --------------------------------------------------------------

  Future<List<DocumentTypeInfo>> documentTypes() async {
    final data = await _send('GET', 'api/document-types/');
    return [for (final j in _results(data)) DocumentTypeInfo.fromJson(j)];
  }

  Future<FactCatalog> facts(String documentType) async {
    final data = await _send('GET', 'api/document-types/$documentType/facts/');
    return FactCatalog.fromJson(data as List);
  }

  // --- rule sets ------------------------------------------------------------

  Future<List<RuleSet>> ruleSets(String documentType) async {
    final data = await _send('GET', 'api/rulesets/', query: {'document_type__slug': documentType, 'page_size': '200'});
    return [for (final j in _results(data)) RuleSet.fromJson(j)];
  }

  Future<RuleSet> saveRuleSet(RuleSet rs, FactCatalog catalog) async {
    final body = rs.toJson(catalog);
    final data = rs.id == null
        ? await _send('POST', 'api/rulesets/', body: body)
        : await _send('PATCH', 'api/rulesets/${rs.id}/', body: body);
    return RuleSet.fromJson(data as Map<String, dynamic>);
  }

  Future<RuleSet> setActive(RuleSet rs, bool active) async {
    final data = await _send('PATCH', 'api/rulesets/${rs.id}/', body: {'is_active': active});
    return RuleSet.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteRuleSet(int id) => _send('DELETE', 'api/rulesets/$id/');

  /// Dry-run a tree against a real document without saving anything.
  Future<RuleTestResult> testRule(Map<String, dynamic> tree, {required int documentId}) async {
    try {
      final data = await _send('POST', 'api/rulesets/test/', body: {'tree': tree, 'document_id': documentId}) as Map;
      return RuleTestResult(
        valid: true,
        matched: data['matched'] == true,
        trace: (data['trace'] as Map).cast<String, dynamic>(),
        facts: (data['facts'] as Map? ?? const {}).cast<String, dynamic>(),
      );
    } on ApiException catch (e) {
      if (e.status == 400) {
        final body = e.data;
        final errors = body is Map && body['errors'] is List
            ? [for (final x in body['errors'] as List) '$x']
            : e.message.split('\n');
        return RuleTestResult(valid: false, matched: false, errors: errors);
      }
      rethrow;
    }
  }

  // --- documents --------------------------------------------------------------

  Future<List<DocumentSummary>> documents(String documentType) async {
    final data = await _send('GET', 'api/documents/', query: {'document_type__slug': documentType});
    return [for (final j in _results(data)) DocumentSummary.fromJson(j)];
  }

  static List<Map<String, dynamic>> _results(dynamic data) {
    final list = data is Map ? data['results'] as List : data as List;
    return list.cast<Map<String, dynamic>>();
  }
}
