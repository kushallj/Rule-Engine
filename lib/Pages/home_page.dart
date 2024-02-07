import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter UI Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  List<Widget> ruleWidgets = [RuleWidget()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rule Builder UI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            ...ruleWidgets,
            ElevatedButton(
              onPressed: () {
                // Logic to add a new rule
                setState(() {
                  ruleWidgets.add(RuleWidget());
                });
              },
              child: const Text('Add Rule'),
            ),
            ElevatedButton(
              onPressed: () {
                // Logic to replicate the entire group
                setState(() {
                  ruleWidgets = List.from(ruleWidgets);
                });
              },
              child: const Text('Add Group'),
            ),
          ],
        ),
      ),
    );
  }
}

class RuleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
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
                  onPressed: () {},
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
    );
  }
}
