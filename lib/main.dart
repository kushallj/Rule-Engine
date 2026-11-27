import 'package:material_ui/material_ui.dart';

import 'screens/login_screen.dart';
import 'screens/rulesets_screen.dart';
import 'state/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session();
  await session.restore();
  runApp(RuleBuilderApp(session: session));
}

class RuleBuilderApp extends StatelessWidget {
  final Session session;
  const RuleBuilderApp({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocFlow Rule Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F5EFF)),
        useMaterial3: true,
        visualDensity: VisualDensity.standard,
      ),
      // rebuild on sign-in / sign-out
      home: ListenableBuilder(
        listenable: session,
        builder: (context, _) => session.signedIn
            ? RuleSetsScreen(key: ValueKey(session.serverUrl), session: session)
            : LoginScreen(session: session),
      ),
    );
  }
}
