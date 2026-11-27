/// Editable rule tree, serialised to the exact JSON DocFlow's rule engine accepts:
///
///   {"type": "all", "not": false, "rules": [
///     {"fact": "total_amount", "operator": "greaterThan", "value": 200000},
///     {"type": "any", "rules": [...]}
///   ]}
///
/// Values are kept as the text the user typed, and converted to typed JSON only
/// when saving, so half-typed input ("12.") is never lost or silently changed.
library;

import 'catalog.dart';

enum GroupType { all, any }

int _nextId = 0;

sealed class RuleNode {
  /// Stable identity for Flutter widget keys while editing.
  final int id = _nextId++;

  Map<String, dynamic> toJson(FactCatalog catalog, [String path = 'root']);

  static RuleNode fromJson(Map<String, dynamic> j) =>
      j.containsKey('rules') ? RuleGroup.fromJson(j) : RuleCondition.fromJson(j);
}

class RuleGroup extends RuleNode {
  GroupType type;
  bool negate;
  final List<RuleNode> rules;

  RuleGroup({this.type = GroupType.all, this.negate = false, List<RuleNode>? rules}) : rules = rules ?? [];

  factory RuleGroup.fromJson(Map<String, dynamic> j) => RuleGroup(
        type: j['type'] == 'any' ? GroupType.any : GroupType.all,
        negate: j['not'] == true,
        rules: [for (final r in (j['rules'] as List? ?? const [])) RuleNode.fromJson(r as Map<String, dynamic>)],
      );

  @override
  Map<String, dynamic> toJson(FactCatalog catalog, [String path = 'root']) {
    if (rules.isEmpty) throw RuleFormatException('$path: add at least one condition or group');
    return {
      'type': type.name,
      if (negate) 'not': true,
      'rules': [for (var i = 0; i < rules.length; i++) rules[i].toJson(catalog, '$path.rules[$i]')],
    };
  }

  /// Number of conditions anywhere below this group.
  int get conditionCount =>
      rules.fold(0, (n, r) => n + (r is RuleGroup ? r.conditionCount : 1));
}

class RuleCondition extends RuleNode {
  String? fact;
  String? operator;

  // Raw editor state. Which of these is used depends on the operator's arity.
  String text;          // arity one / list (comma separated)
  String low;           // arity two
  String high;
  bool boolValue;
  String? refFact;      // compare against another fact instead of a literal

  RuleCondition({
    this.fact,
    this.operator,
    this.text = '',
    this.low = '',
    this.high = '',
    this.boolValue = true,
    this.refFact,
  });

  factory RuleCondition.fromJson(Map<String, dynamic> j) {
    final c = RuleCondition(fact: j['fact'] as String?, operator: j['operator'] as String?);
    final v = j['value'];
    if (v is Map && v.containsKey('fact')) {
      c.refFact = v['fact'] as String?;
    } else if (v is bool) {
      c.boolValue = v;
      c.text = v.toString();
    } else if (v is List) {
      if (j['operator'] == 'between' && v.length == 2) {
        c.low = _fmt(v[0]);
        c.high = _fmt(v[1]);
      } else {
        c.text = v.map(_fmt).join(', ');
      }
    } else if (v != null) {
      c.text = _fmt(v);
    }
    return c;
  }

  static String _fmt(dynamic v) => v is double && v == v.roundToDouble() ? v.toInt().toString() : '$v';

  /// Called when the fact changes: keep the operator only if it still applies.
  void onFactChanged(FactDef? def) {
    if (def == null || def.operator(operator) == null) operator = def?.operators.first.name;
    refFact = null;
  }

  @override
  Map<String, dynamic> toJson(FactCatalog catalog, [String path = 'root']) {
    final def = catalog[fact];
    if (def == null) throw RuleFormatException('$path: choose a fact');
    final op = def.operator(operator);
    if (op == null) throw RuleFormatException('$path: choose an operator for "${def.label}"');
    final out = <String, dynamic>{'fact': def.key, 'operator': op.name};
    if (!op.needsValue) return out;

    if (refFact != null && op.arity == Arity.one && !op.takesDayCount) {
      out['value'] = {'fact': refFact};
      return out;
    }
    final where = '$path (${def.label})';
    switch (op.arity) {
      case Arity.none:
        break;
      case Arity.one:
        out['value'] = op.takesDayCount ? _days(text, where) : _literal(def.type, text, where);
      case Arity.two:
        out['value'] = [_literal(def.type, low, '$where low'), _literal(def.type, high, '$where high')];
      case Arity.list:
        final parts = text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (parts.isEmpty) throw RuleFormatException('$where: enter at least one value, separated by commas');
        out['value'] = [for (final p in parts) _literal(def.type, p, where)];
    }
    return out;
  }

  dynamic _literal(FactType type, String raw, String where) {
    final s = raw.trim();
    switch (type) {
      case FactType.bool:
        return boolValue;   // edited with a true / false toggle
      case FactType.number:
        final n = num.tryParse(s.replaceAll(',', ''));
        if (n == null) throw RuleFormatException('$where: "$raw" is not a number');
        return n;
      case FactType.date:
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) || DateTime.tryParse(s) == null) {
          throw RuleFormatException('$where: use a date like 2026-12-31');
        }
        return s;
      case FactType.string:
        if (s.isEmpty) throw RuleFormatException('$where: enter a value');
        return s;
    }
  }

  int _days(String raw, String where) {
    final n = int.tryParse(raw.trim());
    if (n == null || n < 0) throw RuleFormatException('$where: enter a whole number of days');
    return n;
  }
}

class RuleFormatException implements Exception {
  final String message;
  RuleFormatException(this.message);

  @override
  String toString() => message;
}

enum RuleAction { approve, review, reject }

/// A DocFlow rule set (GET/POST/PATCH /api/rulesets/).
class RuleSet {
  int? id;
  String name;
  String description;
  String documentType;
  int priority;
  RuleGroup tree;
  RuleAction action;
  String routeTo;
  String reason;
  bool isActive;
  int version;

  RuleSet({
    this.id,
    this.name = '',
    this.description = '',
    required this.documentType,
    this.priority = 100,
    RuleGroup? tree,
    this.action = RuleAction.review,
    this.routeTo = '',
    this.reason = '',
    this.isActive = true,
    this.version = 0,
  }) : tree = tree ?? RuleGroup(rules: [RuleCondition()]);

  factory RuleSet.fromJson(Map<String, dynamic> j) {
    final rawTree = j['tree'] as Map<String, dynamic>;
    final node = RuleNode.fromJson(rawTree);
    return RuleSet(
      id: j['id'] as int?,
      name: j['name'] as String? ?? '',
      description: j['description'] as String? ?? '',
      documentType: j['document_type'] as String,
      priority: j['priority'] as int? ?? 100,
      // the editor always works with a group at the root
      tree: node is RuleGroup ? node : RuleGroup(rules: [node]),
      action: RuleAction.values.byName(j['action'] as String),
      routeTo: j['route_to'] as String? ?? '',
      reason: j['reason'] as String? ?? '',
      isActive: j['is_active'] as bool? ?? true,
      version: j['version'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson(FactCatalog catalog) {
    if (name.trim().isEmpty) throw RuleFormatException('Give the rule set a name');
    return {
      'name': name.trim(),
      'description': description,
      'document_type': documentType,
      'priority': priority,
      'tree': tree.toJson(catalog),
      'action': action.name,
      'route_to': routeTo.trim(),
      'reason': reason.trim(),
      'is_active': isActive,
    };
  }
}
