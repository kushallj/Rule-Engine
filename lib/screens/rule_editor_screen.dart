import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../api/docflow_api.dart';
import '../models/catalog.dart';
import '../models/rule_tree.dart';
import '../widgets/rule_tree_editor.dart';
import '../widgets/trace_view.dart';
import 'rulesets_screen.dart';

class RuleEditorScreen extends StatefulWidget {
  final DocflowApi api;
  final FactCatalog catalog;
  final RuleSet ruleSet;

  const RuleEditorScreen({super.key, required this.api, required this.catalog, required this.ruleSet});

  @override
  State<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends State<RuleEditorScreen> {
  late RuleSet rs = widget.ruleSet;
  late final _name = TextEditingController(text: rs.name);
  late final _route = TextEditingController(text: rs.routeTo);
  late final _reason = TextEditingController(text: rs.reason);
  late final _priority = TextEditingController(text: '${rs.priority}');

  bool _dirty = false;
  bool _saving = false;
  bool _saved = false;
  String? _error;
  bool _showJson = false;

  List<DocumentSummary>? _docs;
  int? _docId;
  bool _testing = false;
  RuleTestResult? _test;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    try {
      final docs = await widget.api.documents(rs.documentType);
      setState(() {
        _docs = docs;
        _docId = docs.isEmpty ? null : docs.first.id;
      });
    } on ApiException {
      setState(() => _docs = const []);
    }
  }

  void _changed() => setState(() {
        _dirty = true;
        _test = null;
        _error = null;
      });

  void _syncMeta() {
    rs.name = _name.text;
    rs.routeTo = _route.text;
    rs.reason = _reason.text;
    rs.priority = int.tryParse(_priority.text) ?? rs.priority;
  }

  Future<void> _save() async {
    _syncMeta();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.api.saveRuleSet(rs, widget.catalog);
      setState(() {
        rs = saved;
        _dirty = false;
        _saved = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved "${saved.name}" (v${saved.version})')));
      }
    } on RuleFormatException catch (e) {
      setState(() => _error = e.message);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _runTest() async {
    setState(() {
      _testing = true;
      _error = null;
    });
    try {
      final tree = rs.tree.toJson(widget.catalog);
      final result = await widget.api.testRule(tree, documentId: _docId!);
      setState(() => _test = result);
    } on RuleFormatException catch (e) {
      setState(() => _error = e.message);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  String _jsonPreview() {
    try {
      return const JsonEncoder.withIndent('  ').convert(rs.tree.toJson(widget.catalog));
    } on RuleFormatException catch (e) {
      return '// not valid yet: ${e.message}';
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('This rule set has unsaved changes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop(_saved);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () async {
            if (await _confirmLeave() && context.mounted) Navigator.of(context).pop(_saved);
          }),
          title: Text(rs.id == null ? 'New rule set' : 'Edit rule set${rs.version > 0 ? '  (v${rs.version})' : ''}'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                key: const ValueKey('save'),
                onPressed: _saving || (!_dirty && rs.id != null) ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_dirty || rs.id == null ? 'Save' : 'Saved'),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            if (_error != null)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!, key: const ValueKey('error'), style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                ),
              ),
            _section(context, 'Rule set', [
              Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(width: 420, child: _field(_name, 'Name', key: 'name')),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<RuleAction>(
                    key: const ValueKey('action'),
                    initialValue: rs.action,
                    decoration: const InputDecoration(labelText: 'When it matches', border: OutlineInputBorder(), isDense: true),
                    items: [
                      for (final a in RuleAction.values)
                        DropdownMenuItem(value: a, child: Text(actionLabel(a), style: TextStyle(color: actionColor(a)))),
                    ],
                    onChanged: (a) {
                      rs.action = a!;
                      _changed();
                    },
                  ),
                ),
                SizedBox(width: 200, child: _field(_route, 'Review queue (optional)', key: 'route')),
                SizedBox(width: 110, child: _field(_priority, 'Priority', key: 'priority', numeric: true)),
                SizedBox(width: 560, child: _field(_reason, 'Reason shown to reviewers', key: 'reason')),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Switch(
                    value: rs.isActive,
                    onChanged: (v) {
                      rs.isActive = v;
                      _changed();
                    },
                  ),
                  const Text('Active'),
                ]),
              ]),
            ]),
            _section(context, 'Conditions', [
              GroupEditor(group: rs.tree, catalog: widget.catalog, onChanged: _changed),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: Icon(_showJson ? Icons.expand_less : Icons.code),
                  label: Text(_showJson ? 'Hide JSON' : 'Show JSON sent to DocFlow'),
                  onPressed: () => setState(() => _showJson = !_showJson),
                ),
              ),
              if (_showJson)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(_jsonPreview(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
            ]),
            _section(context, 'Try it on a real document', [
              Text('Runs the conditions above against a processed document. Nothing is saved.',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              if (_docs == null)
                const LinearProgressIndicator()
              else if (_docs!.isEmpty)
                const Text('Upload a document in DocFlow first.')
              else
                Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  SizedBox(
                    width: 420,
                    child: DropdownButtonFormField<int>(
                      key: const ValueKey('test-doc'),
                      initialValue: _docId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Document', border: OutlineInputBorder(), isDense: true),
                      items: [
                        for (final d in _docs!)
                          DropdownMenuItem(value: d.id, child: Text('${d.title}  (${d.status.replaceAll('_', ' ')})',
                              overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setState(() {
                        _docId = v;
                        _test = null;
                      }),
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('run-test'),
                    onPressed: _testing || _docId == null ? null : _runTest,
                    icon: _testing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow),
                    label: const Text('Run test'),
                  ),
                ]),
              if (_test != null) ...[
                const SizedBox(height: 12),
                if (!_test!.valid)
                  Text(_test!.errors.join('\n'), style: TextStyle(color: theme.colorScheme.error))
                else ...[
                  Chip(
                    key: const ValueKey('test-result'),
                    avatar: Icon(_test!.matched ? Icons.check : Icons.close, size: 18),
                    label: Text(_test!.matched
                        ? 'Matches: this document would be sent to "${actionLabel(rs.action).toLowerCase()}"'
                        : 'Does not match this document'),
                  ),
                  TraceView(node: _test!.trace!),
                ],
              ],
            ]),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {required String key, bool numeric = false}) => TextField(
        key: ValueKey(key),
        controller: c,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        onChanged: (_) => _changed(),
      );

  Widget _section(BuildContext context, String title, List<Widget> children) => Card(
        margin: const EdgeInsets.only(top: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ]),
        ),
      );
}
