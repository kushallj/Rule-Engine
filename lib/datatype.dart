import 'package:flutter/material.dart';

enum FactType {
  string, bool, int, double
}

enum OperatorType {
  equalTo, greaterThan, lessThan
}

enum RuleGroupType {
  any, all
}

class Fact {
  final int id;
  final String label;
  final FactType type;

  Fact({required this.id, required this.label, required this.type});

  @override
  String toString() {
    return 'Fact{id: $id, label: $label, type: $type}';
  }
}

class Condition {
  final int id;
  final String label;
  final OperatorType operator;

  Condition({required this.id, required this.label, required this.operator});

  @override
  String toString() {
    return 'Condition{id: $id, label: $label, operator: $operator}';
  }
}

class Rule {
  final Fact fact;
  final Condition condition;
  final dynamic value;

  Rule({required this.fact, required this.condition, required this.value});

  @override
  String toString() {
    return 'Rule{fact: $fact, condition: $condition, value: $value}';
  }
}

class RuleGroup {
  final int id;
  final RuleGroupType type;
  final List rules;

  RuleGroup({required this.id, required this.type, required this.rules});

  @override
  String toString() {
    return 'RuleGroup{id: $id, type: $type, rules: $rules}';
  }
}
//
// void main() {
//   var factDropdown = DropdownButtonFormField<String>(
//     hint: const Text('Select Facts'),
//     items: <String>['Fact 1', 'Fact 2', 'Fact 3'].map((String value) {
//       return DropdownMenuItem<String>(
//         value: value,
//         child: Text(value),
//       );
//     }).toList(),
//     onChanged: (_) {},
//   );
//
//   var conditionDropdown = DropdownButtonFormField<String>(
//     hint: const Text('Select Operator'),
//     items: <String>['Operator 1', 'Operator 2', 'Operator 3'].map((String value) {
//       return DropdownMenuItem<String>(
//         value: value,
//         child: Text(value),
//       );
//     }).toList(),
//     onChanged: (_) {
//       // Handle change
//     },
//   );
//
//   var valueField = TextFormField(
//     decoration: const InputDecoration(hintText: 'Enter value'),
//   );
//
//   var rule = Rule(factDropdown, conditionDropdown, valueField);
//
//   var  ruleGroup = RuleGroup({"rule": rule, "RuleGroup": RuleGroup});
// }
