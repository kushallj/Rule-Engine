import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:animated_tree_view/animated_tree_view.dart';

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
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // TreeViewController? _controller;
  late List<Widget> ruleWidgets;



  // final sampleTree = TreeNode.root()
  //   ..addAll([
  //     TreeNode(key: "0A")..add(TreeNode(key: "0A1A")),
  //     TreeNode(key: "0C", data: Text('Hello world'))
  //       ..addAll([
  //         TreeNode(key: "0C1A"),
  //         TreeNode(key: "0C1B"),
  //         TreeNode(key: "0C1C")
  //           ..addAll([
  //             TreeNode(key: "0C1C2A")
  //               ..addAll([
  //                 TreeNode(key: "0C1C2A3A"),
  //                 TreeNode(key: "0C1C2A3B"),
  //                 TreeNode(key: "0C1C2A3C"),
  //               ]),
  //           ]),
  //       ]),
  //     TreeNode(key: "0D"),
  //     TreeNode(key: "0E"),
  //   ]);

  @override
  void initState() {
    super.initState();
    ruleWidgets = [RuleWidget(onAddRule: addNewRule, addChild: addNewChild,removeRule: removeRule,)];
  }

  void addNewRule() {
    setState(() {
      ruleWidgets.add(RuleWidget(onAddRule: addNewRule, addChild: addNewChild, removeRule: removeRule));
    });
  }

  void addNewChild() {
    setState(() {
      ruleWidgets.add(RuleWidget(onAddRule: addNewRule, addChild: addNewChild, removeRule: removeRule));
    });
  }

  void removeRule() {
    setState(() {
      ruleWidgets.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rule Builder UI'),
      ),
      // floatingActionButton: ValueListenableBuilder<bool>(
      //   valueListenable: sampleTree.expansionNotifier,
      //   builder: (context, isExpanded, _) {
      //     return FloatingActionButton(
      //       onPressed: () {
      //         if (sampleTree.isExpanded) {
      //           _controller?.collapseNode(sampleTree);
      //         } else {
      //           _controller?.expandAllChildren(sampleTree);
      //         }
      //       },
      //       child: isExpanded ? const Text("Collapse all") : const Text("Expand all"),
      //     );
      //   },
      // ),
    body: Padding(
       padding: const EdgeInsets.all(8.0),
               child: ListView(
                       children: <Widget>[
                                ...ruleWidgets,
                             ElevatedButton(
                              onPressed: () {
                                    setState(() {
                                          ruleWidgets.add(RuleWidget(onAddRule: addNewRule, addChild: addNewChild,removeRule: removeRule,));
                                                   });
                                              },
                                 child: const Text('Add Rule'),
                                        ),
                            ElevatedButton(
                         onPressed: () {
                                setState(() {
                        List<Widget> newGroup = List.from(ruleWidgets);
                                   ruleWidgets.add(Column(
                              children: newGroup,
                                 )
                               );
                                });
                           },
                               child: const Text('Add Group'),
                              ),
                              ],
                              ),
                              )
    );
    //   body: Column(
    //   //   children: [
    //   //     Expanded(
    //   //       child: TreeView.simple(
    //   //         tree: sampleTree,
    //   //         showRootNode: true,
    //   //         expansionIndicatorBuilder: (context, node) => ChevronIndicator.rightDown(
    //   //           tree: node,
    //   //           color: Colors.blue,
    //   //           padding: const EdgeInsets.all(8),
    //   //         ),
    //   //         indentation: const Indentation(style: IndentStyle.squareJoint),
    //   //         onItemTap: (item) {
    //   //           if (kDebugMode) print("Item tapped: ${item.key}");
    //   //
    //   //           if (showSnackBar) {
    //   //             ScaffoldMessenger.of(context).showSnackBar(
    //   //               SnackBar(
    //   //                 content: Text("Item tapped: ${item.key}"),
    //   //                 duration: const Duration(milliseconds: 750),
    //   //               ),
    //   //             );
    //   //           }
    //   //         },
    //   //         onTreeReady: (controller) {
    //   //           _controller = controller;
    //   //           if (expandChildrenOnReady) controller.expandAllChildren(sampleTree);
    //   //         },
    //   //         builder: (context, node) => Card(
    //   //           color: colorMapper[node.level.clamp(0, colorMapper.length - 1)]!,
    //   //           child: ListTile(
    //   //             title: Text("Item ${node.level}-${node.key}"),
    //   //             subtitle: Text('Level ${node.level}'),
    //   //           ),
    //   //         ),
    //   //       ),
    //   //     ),
    //   //   ],
    //   // ),
    //
    //
    //
    // );
  }
}



class RuleWidget extends StatefulWidget {
  final VoidCallback onAddRule;
  final VoidCallback addChild;
  final VoidCallback removeRule;

  RuleWidget({required this.onAddRule, required this.addChild,required this.removeRule});
  @override
  State<RuleWidget> createState() => _RuleWidgetState();
}

class _RuleWidgetState extends State<RuleWidget> {
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
                      widget.removeRule();
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
// const showSnackBar = true;
// const expandChildrenOnReady = true;
// Map<int, Color> colorMapper = {
//   0: Colors.red,
//   1: Colors.green,
//   2: Colors.blue,
//   3: Colors.yellow,
// };
