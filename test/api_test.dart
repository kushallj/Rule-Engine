import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rule_builder/api/docflow_api.dart';
import 'package:rule_builder/models/rule_tree.dart';

import 'fixtures.dart';

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  test('login returns the token and later calls send it', () async {
    final seen = <http.Request>[];
    final client = MockClient((req) async {
      seen.add(req);
      if (req.url.path == '/api/auth/token/') return json({'token': 'abc123'});
      return json({'count': 0, 'results': []});
    });
    final api = DocflowApi('http://localhost:8000', client: client);
    final token = await api.login('admin', 'pw');
    expect(token, 'abc123');
    await api.withToken(token).ruleSets('invoice');
    expect(seen.last.headers['Authorization'], 'Token abc123');
    expect(seen.last.url.queryParameters['document_type__slug'], 'invoice');
  });

  test('new rule sets are POSTed, existing ones PATCHed', () async {
    final methods = <String>[];
    final client = MockClient((req) async {
      methods.add('${req.method} ${req.url.path}');
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      return json({...body, 'id': 7, 'version': 1}, req.method == 'POST' ? 201 : 200);
    });
    final api = DocflowApi('http://x/', token: 't', client: client);
    final rs = RuleSet(documentType: 'invoice', name: 'Big', tree: RuleGroup.fromJson(seedTree));
    final saved = await api.saveRuleSet(rs, catalog());
    await api.saveRuleSet(saved, catalog());
    expect(methods, ['POST /api/rulesets/', 'PATCH /api/rulesets/7/']);
  });

  test('server validation errors become one readable message', () async {
    final client = MockClient((_) async => json({
          'tree': ["root.rules[0].operator: 'greaterThan' cannot be used with string fact 'vendor_name'"]
        }, 400));
    final api = DocflowApi('http://x', token: 't', client: client);
    final rs = RuleSet(documentType: 'invoice', name: 'Bad', tree: RuleGroup.fromJson(seedTree));
    expect(
      () => api.saveRuleSet(rs, catalog()),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('tree: root.rules[0].operator'))),
    );
  });

  test('403 explains that only admins can edit', () {
    expect(DocflowApi.describeError(403, {'detail': 'You do not have permission to perform this action.'}),
        contains('permission'));
  });

  test('dry run returns the trace; invalid trees return errors instead of throwing', () async {
    var call = 0;
    final client = MockClient((_) async => ++call == 1
        ? json({'valid': true, 'matched': true, 'trace': {'passed': true, 'kind': 'group', 'description': 'ALL of 1'}, 'facts': {}})
        : json({'valid': false, 'errors': ['root.rules[0].fact: unknown fact']}, 400));
    final api = DocflowApi('http://x', token: 't', client: client);
    final ok = await api.testRule(seedTree, documentId: 1);
    expect(ok.matched, isTrue);
    final bad = await api.testRule(seedTree, documentId: 1);
    expect(bad.valid, isFalse);
    expect(bad.errors.single, contains('unknown fact'));
  });

  test('unreachable server gives a clear message', () async {
    final client = MockClient((_) async => throw http.ClientException('Connection refused'));
    expect(() => DocflowApi('http://localhost:9', client: client).documentTypes(),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Is the server running'))));
  });
}
