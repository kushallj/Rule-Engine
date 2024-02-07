import 'dart:math' as math;

import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:dribbble/datatype.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Rule Engine',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  // TreeViewController? _controller;
  final RuleGroup _root = RuleGroup(id: 1, type: RuleGroupType.any, rules: []);
  final _facts = [
    Fact(id: 1, label: 'age', type: FactType.int),
    Fact(id: 2, label: 'name', type: FactType.string)
  ];
  final _conditions = [
    Condition(id: 1, label: 'greaterThan', operator: OperatorType.greaterThan),
    Condition(id: 2, label: 'lessThan', operator: OperatorType.lessThan),
    Condition(id: 3, label: 'equalTo', operator: OperatorType.equalTo),
  ];
  final _ageFact = Fact(id: 1, label: 'age', type: FactType.int);
  final _nameFact = Fact(id: 2, label: 'name', type: FactType.string);
  final _greaterCondition = Condition(
      id: 1, label: 'greaterThan', operator: OperatorType.greaterThan);
  final _equalCondition =
      Condition(id: 3, label: 'equalTo', operator: OperatorType.equalTo);
  late TreeNode _tree;

  final Map<int, Color> _colorMapper = {
    0: Colors.red,
    1: Colors.green,
    2: Colors.blue,
    3: Colors.yellow,
  };

  TreeNode _createNode(RuleGroup ruleGroup, {bool isRoot = false}) {
    late TreeNode node;
    if (isRoot) {
      node = TreeNode.root(data: ruleGroup);
    } else {
      node = TreeNode(data: ruleGroup);
    }
    return node
      ..addAll(ruleGroup.rules.map((rule) {
        if (rule is Rule) {
          return TreeNode(key: rule.fact.label, data: rule);
        } else {
          final ruleGroup = rule as RuleGroup;
          return _createNode(ruleGroup);
        }
      }).toList());
  }

  @override
  void initState() {
    super.initState();
    _root.rules.addAll([
      Rule(fact: _ageFact, condition: _greaterCondition, value: 45),
      Rule(fact: _nameFact, condition: _equalCondition, value: 'ravi'),
      RuleGroup(id: 2, type: RuleGroupType.all, rules: [
        Rule(fact: _nameFact, condition: _equalCondition, value: 'ravi')
      ]),
      RuleGroup(id: 3, type: RuleGroupType.all, rules: [
        Rule(fact: _nameFact, condition: _equalCondition, value: 'ravi'),
        RuleGroup(id: 3, type: RuleGroupType.all, rules: [
          Rule(fact: _nameFact, condition: _equalCondition, value: 'ravi'),
        ])
      ])
    ]);

    _tree = _createNode(_root, isRoot: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Rule Builder UI'),
        ),
        body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: TreeView.simple(
                    tree: _tree,
                    showRootNode: true,
                    expansionIndicatorBuilder: (context, node) =>
                        ChevronIndicator.rightDown(
                      tree: node,
                      color: Colors.blue,
                      padding: const EdgeInsets.all(8),
                    ),
                    indentation:
                        const Indentation(style: IndentStyle.squareJoint),
                    onItemTap: (item) {
                      if (kDebugMode) print("Item tapped: ${item.key}");

                      // if (showSnackBar) {
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     SnackBar(
                      //       content: Text("Item tapped: ${item.key}"),
                      //       duration: const Duration(milliseconds: 750),
                      //     ),
                      //   );
                      // }
                    },
                    onTreeReady: (controller) {
                      controller.expandAllChildren(_tree);
                      // _controller = controller;
                      // if (expandChildrenOnReady)
                      //   controller.expandAllChildren(sampleTree);
                    },
                    builder: (context, node) {
                      return ValueListenableBuilder(
                          valueListenable: node.listenableData,
                          builder: (context, data, child) {
                            if (node.data is RuleGroup) {
                              return _ruleGroupView(node, data);
                            } else {
                              final rule = node.data as Rule;
                              return _ruleView(rule);
                            }
                          });
                    },
                  ),
                ),
              ],
            )));
  }

  void _addGroup(TreeNode node) {
    node.add(TreeNode(
        data: RuleGroup(
            id: math.Random().nextInt(100000),
            type: RuleGroupType.all,
            rules: [
          Rule(fact: _nameFact, condition: _equalCondition, value: 'ravi'),
        ])));
  }

  Widget _ruleGroupView(TreeNode node, RuleGroup ruleGroup) {
    return Row(
      children: [
        DropdownMenu<String>(
            initialSelection: ruleGroup.type.name,
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: 'all', label: 'All'),
              DropdownMenuEntry(value: 'any', label: 'Any'),
            ]),
        const SizedBox(width: 16.0),
        FilledButton(
            onPressed: () {
              _addGroup(node);
            },
            child: const Text('Add Group'))
      ],
    );
  }

  Widget _ruleView(Rule rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          DropdownMenu<int>(
            dropdownMenuEntries: _facts
                .map((fact) =>
                    DropdownMenuEntry(value: fact.id, label: fact.label))
                .toList(),
            initialSelection: rule.fact.id,
            label: const Text('Fact'),
          ),
          const SizedBox(
            width: 16.0,
          ),
          DropdownMenu<int>(
            dropdownMenuEntries: _conditions
                .map((condition) => DropdownMenuEntry(
                    value: condition.id, label: condition.label))
                .toList(),
            initialSelection: rule.condition.id,
            label: const Text('Condition'),
          ),
          const SizedBox(
            width: 16.0,
          ),
          Expanded(
              child: TextField(
            decoration: const InputDecoration(
                label: Text('Value'), border: OutlineInputBorder()),
            controller: TextEditingController(text: rule.value.toString()),
          )),
        ],
      ),
    );
  }
}
