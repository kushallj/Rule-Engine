import 'package:flutter_test/flutter_test.dart';
import 'package:rule_builder/models/rule_tree.dart';

import 'fixtures.dart';

void main() {
  final cat = catalog();

  test('DocFlow rule JSON survives a load / save round trip unchanged', () {
    final tree = RuleGroup.fromJson(seedTree);
    expect(tree.toJson(cat), seedTree);
    expect(tree.conditionCount, 4);
  });

  test('values are converted to the fact type when saving', () {
    final c = RuleCondition(fact: 'total_amount', operator: 'greaterThan', text: '2,00,000');
    expect(c.toJson(cat), {'fact': 'total_amount', 'operator': 'greaterThan', 'value': 200000});

    final between = RuleCondition(fact: 'total_amount', operator: 'between', low: '10', high: '99.5');
    expect(between.toJson(cat)['value'], [10, 99.5]);

    final days = RuleCondition(fact: 'due_date', operator: 'withinNextDays', text: '7');
    expect(days.toJson(cat)['value'], 7);

    final flag = RuleCondition(fact: 'vendor_approved', operator: 'equalTo', boolValue: false);
    expect(flag.toJson(cat)['value'], false);
  });

  test('fact-to-fact comparison', () {
    final c = RuleCondition(fact: 'total_amount', operator: 'greaterThan', refFact: 'subtotal');
    expect(c.toJson(cat)['value'], {'fact': 'subtotal'});
    expect(RuleCondition.fromJson(c.toJson(cat)).refFact, 'subtotal');
  });

  test('NOT groups keep their flag', () {
    final g = RuleGroup.fromJson({'type': 'any', 'not': true, 'rules': [
      {'fact': 'vendor_name', 'operator': 'exists'}
    ]});
    expect(g.negate, isTrue);
    expect(g.toJson(cat)['not'], true);
  });

  group('helpful errors before anything is sent', () {
    void expectError(RuleNode node, String fragment) => expect(
          () => node.toJson(cat),
          throwsA(isA<RuleFormatException>().having((e) => e.message, 'message', contains(fragment))),
        );

    test('missing fact', () => expectError(RuleCondition(), 'choose a fact'));
    test('not a number', () =>
        expectError(RuleCondition(fact: 'total_amount', operator: 'greaterThan', text: 'lots'), 'not a number'));
    test('bad date', () =>
        expectError(RuleCondition(fact: 'due_date', operator: 'lessThan', text: '31/12/2026'), '2026-12-31'));
    test('empty list', () =>
        expectError(RuleCondition(fact: 'total_amount', operator: 'in', text: ' , '), 'at least one value'));
    test('empty group, with its path', () =>
        expectError(RuleGroup(rules: [RuleGroup()]), 'root.rules[0]: add at least one'));
  });

  test('changing the fact drops an operator that no longer applies', () {
    final c = RuleCondition(fact: 'total_amount', operator: 'between');
    c.fact = 'vendor_name';
    c.onFactChanged(cat['vendor_name']);
    expect(c.operator, 'contains');
  });

  test('RuleSet serialises the fields DocFlow expects', () {
    final rs = RuleSet.fromJson({
      'id': 3, 'name': 'Big', 'document_type': 'invoice', 'priority': 30, 'tree': seedTree,
      'action': 'review', 'route_to': 'finance-manager', 'reason': 'r', 'is_active': true, 'version': 2,
    });
    final body = rs.toJson(cat);
    expect(body['action'], 'review');
    expect(body['route_to'], 'finance-manager');
    expect(body['tree'], seedTree);
    expect(body.containsKey('version'), isFalse); // server-owned
  });
}
