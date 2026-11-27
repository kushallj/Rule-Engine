import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rule_builder/models/rule_tree.dart';
import 'package:rule_builder/widgets/rule_tree_editor.dart';

import 'fixtures.dart';

void main() {
  testWidgets('editor renders a nested tree and adds conditions and groups', (tester) async {
    final tree = RuleGroup.fromJson(seedTree);
    var changes = 0;
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => GroupEditor(
              group: tree,
              catalog: catalog(),
              onChanged: () => setState(() => changes++),
            ),
          ),
        ),
      ),
    ));

    // 4 conditions across 2 groups
    expect(find.byType(ConditionEditor), findsNWidgets(4));
    expect(find.byType(GroupEditor), findsNWidgets(2));
    expect(find.text('no value needed'), findsOneWidget); // vendor_name exists

    await tester.tap(find.byKey(ValueKey('add-condition-${tree.id}')));
    await tester.pump();
    expect(find.byType(ConditionEditor), findsNWidgets(5));

    await tester.tap(find.byKey(ValueKey('add-group-${tree.id}')));
    await tester.pump();
    expect(find.byType(GroupEditor), findsNWidgets(3));
    expect(tree.rules.last, isA<RuleGroup>());
    expect(changes, 2);

    // typing a value updates the model
    final total = tree.rules[1] as RuleCondition;
    await tester.enterText(find.byKey(ValueKey('value-${total.id}')), '150000');
    expect(total.toJson(catalog())['value'], 150000);
  });
}
