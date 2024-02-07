import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animated_tree_view/animated_tree_view.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Rule Engine',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: MyHomePage(onAddRule: (){},),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final VoidCallback onAddRule;
  MyHomePage({required this.onAddRule});
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TreeViewController? _controller;
  late List<Widget> ruleWidgets;



  final  sampleTree = TreeNode<UserName>.root(data: UserName("User", "Names"))
    ..addAll([
      TreeNode<UserName>(key: "0A", data: UserName("Sr. John", "Doe"))
        ..add(TreeNode(key: "0A1A", data: UserName("Jr. John", "Doe"))),
      TreeNode<UserName>(key: "0C", data: UserName("General", "Lee"))
        ..addAll([
          TreeNode<UserName>(key: "0C1A", data: UserName("Major", "Lee")),
          TreeNode<UserName>(key: "0C1B", data: UserName("Happy", "Lee")),
          TreeNode<UserName>(key: "0C1C", data: UserName("Busy", "Lee"))
            ..addAll([
              TreeNode<UserName>(key: "0C1C2A", data: UserName("Jr. Busy", "Lee"))
            ]),
        ]),
      TreeNode<UserName>(key: "0D", data: UserName("Mr. Anderson", "Neo")),
      TreeNode<UserName>(key: "0E", data: UserName("Mr. Smith", "Agent")),
    ]);

  @override
  void initState() {
    super.initState();
    ruleWidgets = [RuleWidget(onAddRule: addNewRule, addChild: addNewChild)];
  }

  void addNewRule() {
    setState(() {
      ruleWidgets.add(RuleWidget(onAddRule: addNewRule, addChild: addNewChild));
    });
  }

  void addNewChild() {
    setState(() {
      ruleWidgets.add(RuleWidget(onAddRule: addNewRule, addChild: addNewChild));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rule Builder UI'),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: sampleTree.expansionNotifier,
        builder: (context, isExpanded, _) {
          return FloatingActionButton(
            onPressed: () {
              if (sampleTree.isExpanded) {
                _controller?.collapseNode(sampleTree);
              } else {
                _controller?.expandAllChildren(sampleTree);
              }
            },
            child: isExpanded ? const Text("Collapse all") : const Text("Expand all"),
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: TreeView.simple(
              tree: sampleTree,
              showRootNode: true,
              expansionIndicatorBuilder: (context, node) => ChevronIndicator.rightDown(
                tree: node,
                color: Colors.blue,
                padding: const EdgeInsets.all(8),
              ),
              indentation: const Indentation(style: IndentStyle.squareJoint),
              onItemTap: (item) {
                if (kDebugMode) print("Item tapped: ${item.key}");

                if (showSnackBar) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Item tapped: ${item.key}"),
                      duration: const Duration(milliseconds: 750),
                    ),
                  );
                }
              },
              onTreeReady: (controller) {
                _controller = controller;
                if (expandChildrenOnReady) controller.expandAllChildren(sampleTree);
              },
              builder: (context, node) => Card(
                color: colorMapper[node.level.clamp(0, colorMapper.length - 1)]!,
                child: Column(
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      hint: const Text('Select Facts'),
                      items: <String>['Fact 1', 'Fact 2', 'Fact 3'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 8.0),
                    DropdownButtonFormField<String>(
                      hint: const Text('Select Operator'),
                      items: <String>['Operator 1', 'Operator 2', 'Operator 3']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (_) {
                        // Handle change
                      },
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      decoration: const InputDecoration(hintText: 'Enter value'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            widget.onAddRule();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            // Logic to handle remove
                          },
                        ),
                      ],
                    ),
                  ],



                ),
              ),
            ),
          ),
        ],
      ),


      // Padding(
      //   padding: const EdgeInsets.all(8.0),
      //   child: ListView(
      //     children: <Widget>[
      //       ...ruleWidgets,
      //       ElevatedButton(
      //         onPressed: () {
      //           setState(() {
      //             ruleWidgets.add(RuleWidget(onAddRule: addNewRule, addChild: addNewChild));
      //           });
      //         },
      //         child: const Text('Add Rule'),
      //       ),
      //       ElevatedButton(
      //         onPressed: () {
      //           setState(() {
      //             List<Widget> newGroup = List.from(ruleWidgets);
      //             ruleWidgets.add(Column(
      //               children: newGroup,
      //             ));
      //           });
      //         },
      //         child: const Text('Add Group'),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}

class UserName {
  final String firstName;
  final String lastName;

  UserName(this.firstName, this.lastName);
}


class RuleWidget extends StatefulWidget {
  final VoidCallback onAddRule;
  final VoidCallback addChild;

  RuleWidget({required this.onAddRule, required this.addChild});
  @override
  State<RuleWidget> createState() => _RuleWidgetState();
}

class _RuleWidgetState extends State<RuleWidget> {



  late List<Widget> ruleWidgets;

  void addNewRule() {
    setState(() {
      ruleWidgets.add(RuleWidget(onAddRule: addNewRule, addChild: addNewChild));
    });
  }

  void addNewChild() {
    setState(() {
      ruleWidgets.add(RuleWidget(onAddRule: addNewRule, addChild: addNewChild));
    });
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              DropdownButtonFormField<String>(
                hint: const Text('Select Facts'),
                items: <String>['Fact 1', 'Fact 2', 'Fact 3'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                hint: const Text('Select Operator'),
                items: <String>['Operator 1', 'Operator 2', 'Operator 3']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (_) {
                  // Handle change
                },
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                decoration: const InputDecoration(hintText: 'Enter value'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      widget.onAddRule();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      // Logic to handle remove
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Define these constants and variables at the beginning of your file
const showSnackBar = true;
const expandChildrenOnReady = true;
Map<int, Color> colorMapper = {
  0: Colors.red,
  1: Colors.green,
  2: Colors.blue,
  3: Colors.yellow,
};
