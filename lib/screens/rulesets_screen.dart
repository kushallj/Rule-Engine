import 'package:material_ui/material_ui.dart';

import '../api/docflow_api.dart';
import '../models/catalog.dart';
import '../models/rule_tree.dart';
import '../state/session.dart';
import 'rule_editor_screen.dart';

Color actionColor(RuleAction a) => switch (a) {
      RuleAction.approve => const Color(0xFF137A43),
      RuleAction.review => const Color(0xFF9A5B00),
      RuleAction.reject => const Color(0xFFB42318),
    };

String actionLabel(RuleAction a) => switch (a) {
      RuleAction.approve => 'Auto-approve',
      RuleAction.review => 'Send to review',
      RuleAction.reject => 'Reject',
    };

class RuleSetsScreen extends StatefulWidget {
  final Session session;
  const RuleSetsScreen({super.key, required this.session});

  @override
  State<RuleSetsScreen> createState() => _RuleSetsScreenState();
}

class _RuleSetsScreenState extends State<RuleSetsScreen> {
  DocflowApi get api => widget.session.api!;

  List<DocumentTypeInfo> _types = [];
  String? _type;
  FactCatalog? _catalog;
  List<RuleSet> _rules = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _guard(Future<void> Function() body) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await body();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await widget.session.signOut();
        return;
      }
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTypes() => _guard(() async {
        _types = await api.documentTypes();
        _type = _types.isEmpty ? null : _types.first.slug;
        if (_type != null) await _loadRules();
      });

  Future<void> _loadRules() async {
    final results = await Future.wait([api.facts(_type!), api.ruleSets(_type!)]);
    _catalog = results[0] as FactCatalog;
    _rules = results[1] as List<RuleSet>;
  }

  Future<void> _open(RuleSet rs) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => RuleEditorScreen(api: api, catalog: _catalog!, ruleSet: rs),
    ));
    if (changed == true) await _guard(_loadRules);
  }

  Future<void> _toggle(RuleSet rs, bool active) => _guard(() async {
        final updated = await api.setActive(rs, active);
        _rules = [for (final r in _rules) r.id == updated.id ? updated : r];
      });

  Future<void> _delete(RuleSet rs) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete rule set?'),
        content: Text('"${rs.name}" will stop applying to new documents. This cannot be undone; '
            'consider switching it off instead.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _guard(() async {
        await api.deleteRuleSet(rs.id!);
        await _loadRules();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rule Builder'),
        actions: [
          if (_types.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButton<String>(
                value: _type,
                underline: const SizedBox(),
                items: [for (final t in _types) DropdownMenuItem(value: t.slug, child: Text(t.name))],
                onChanged: (v) {
                  _type = v;
                  _guard(_loadRules);
                },
              ),
            ),
          Center(child: Text('${widget.session.username ?? ''} @ ${widget.session.serverUrl}  ',
              style: theme.textTheme.bodySmall)),
          IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: () => _guard(_loadRules)),
          IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout), onPressed: widget.session.signOut),
        ],
      ),
      floatingActionButton: _catalog == null
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('New rule set'),
              onPressed: () => _open(RuleSet(documentType: _type!)),
            ),
      body: _loading && _rules.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
              children: [
                Text(
                  'Rule sets run on every processed document. When several match, the strictest action wins: '
                  'reject, then review, then approve.',
                  style: theme.textTheme.bodyMedium,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                  ),
                const SizedBox(height: 12),
                if (_rules.isEmpty && _error == null)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No rule sets yet.'))),
                for (final rs in _rules)
                  Card(
                    key: ValueKey('ruleset-${rs.id}'),
                    child: ListTile(
                      onTap: () => _open(rs),
                      leading: Icon(Icons.rule, color: rs.isActive ? actionColor(rs.action) : theme.disabledColor),
                      title: Text(rs.name, style: TextStyle(color: rs.isActive ? null : theme.disabledColor)),
                      subtitle: Text([
                        '${actionLabel(rs.action)}${rs.routeTo.isEmpty ? '' : ' → ${rs.routeTo}'}',
                        'priority ${rs.priority}',
                        '${rs.tree.conditionCount} condition${rs.tree.conditionCount == 1 ? '' : 's'}',
                        'v${rs.version}',
                      ].join('  ·  ')),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Tooltip(
                          message: rs.isActive ? 'Active' : 'Switched off',
                          child: Switch(value: rs.isActive, onChanged: (v) => _toggle(rs, v)),
                        ),
                        IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(rs)),
                      ]),
                    ),
                  ),
              ],
            ),
    );
  }
}
