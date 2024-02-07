import 'package:flutter/material.dart';

class Rule {
  dynamic fact;
  dynamic condition;
  var value;

  Rule(this.fact, this.condition, this.value);
}

class RuleGroup {

  dynamic ruleGroup;

  RuleGroup(this.ruleGroup);
}

void main() {
  var factDropdown = DropdownButtonFormField<String>(
    hint: const Text('Select Facts'),
    items: <String>['Fact 1', 'Fact 2', 'Fact 3'].map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList(),
    onChanged: (_) {},
  );

  var conditionDropdown = DropdownButtonFormField<String>(
    hint: const Text('Select Operator'),
    items: <String>['Operator 1', 'Operator 2', 'Operator 3'].map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList(),
    onChanged: (_) {
      // Handle change
    },
  );

  var valueField = TextFormField(
    decoration: const InputDecoration(hintText: 'Enter value'),
  );

  var rule = Rule(factDropdown, conditionDropdown, valueField);

  var  ruleGroup = RuleGroup({"rule": rule, "RuleGroup": RuleGroup});
}
