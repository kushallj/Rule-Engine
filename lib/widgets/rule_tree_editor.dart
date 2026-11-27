import 'package:material_ui/material_ui.dart';

import '../models/catalog.dart';
import '../models/rule_tree.dart';

/// Left border colour per nesting level, so deep trees stay readable.
const _depthColors = [Color(0xFF1F5EFF), Color(0xFF0F9D58), Color(0xFFB06000), Color(0xFF8E44AD), Color(0xFFC0392B)];

/// Recursive editor for an ALL / ANY group. Mutates the tree in place and calls
/// [onChanged] so the screen can rebuild and mark the rule set as modified.
class GroupEditor extends StatelessWidget {
  final RuleGroup group;
  final FactCatalog catalog;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  final int depth;

  const GroupEditor({
    super.key,
    required this.group,
    required this.catalog,
    required this.onChanged,
    this.onRemove,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = _depthColors[depth % _depthColors.length];
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: depth == 0 ? null : theme.colorScheme.surfaceContainerLowest,
        border: Border(left: BorderSide(color: color, width: 3)),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<GroupType>(
                key: ValueKey('group-type-${group.id}'),
                segments: const [
                  ButtonSegment(value: GroupType.all, label: Text('ALL'), tooltip: 'Every condition must be true'),
                  ButtonSegment(value: GroupType.any, label: Text('ANY'), tooltip: 'At least one condition must be true'),
                ],
                selected: {group.type},
                showSelectedIcon: false,
                onSelectionChanged: (s) {
                  group.type = s.first;
                  onChanged();
                },
              ),
              Text(group.type == GroupType.all ? 'of these must match' : 'of these can match',
                  style: theme.textTheme.bodySmall),
              FilterChip(
                label: const Text('NOT'),
                tooltip: 'Invert the whole group',
                selected: group.negate,
                onSelected: (v) {
                  group.negate = v;
                  onChanged();
                },
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                key: ValueKey('add-condition-${group.id}'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Condition'),
                onPressed: () {
                  group.rules.add(RuleCondition());
                  onChanged();
                },
              ),
              TextButton.icon(
                key: ValueKey('add-group-${group.id}'),
                icon: const Icon(Icons.account_tree_outlined, size: 18),
                label: const Text('Group'),
                onPressed: () {
                  group.rules.add(RuleGroup(type: GroupType.any, rules: [RuleCondition()]));
                  onChanged();
                },
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Remove group',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
            ],
          ),
          for (final node in group.rules)
            switch (node) {
              RuleGroup g => GroupEditor(
                  key: ValueKey(g.id),
                  group: g,
                  catalog: catalog,
                  depth: depth + 1,
                  onChanged: onChanged,
                  onRemove: () {
                    group.rules.remove(g);
                    onChanged();
                  },
                ),
              RuleCondition c => ConditionEditor(
                  key: ValueKey(c.id),
                  condition: c,
                  catalog: catalog,
                  onChanged: onChanged,
                  onRemove: () {
                    group.rules.remove(c);
                    onChanged();
                  },
                ),
            },
          if (group.rules.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Empty group: add a condition', style: TextStyle(color: theme.colorScheme.error)),
            ),
        ],
      ),
    );
  }
}

/// One "fact  operator  value" row.
class ConditionEditor extends StatefulWidget {
  final RuleCondition condition;
  final FactCatalog catalog;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const ConditionEditor({
    super.key,
    required this.condition,
    required this.catalog,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<ConditionEditor> createState() => _ConditionEditorState();
}

class _ConditionEditorState extends State<ConditionEditor> {
  late final _text = TextEditingController(text: widget.condition.text);
  late final _low = TextEditingController(text: widget.condition.low);
  late final _high = TextEditingController(text: widget.condition.high);

  RuleCondition get c => widget.condition;

  @override
  void dispose() {
    _text.dispose();
    _low.dispose();
    _high.dispose();
    super.dispose();
  }

  void _changed() => widget.onChanged();

  @override
  Widget build(BuildContext context) {
    final fact = widget.catalog[c.fact];
    final op = fact?.operator(c.operator);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<String>(
              key: ValueKey('fact-${c.id}'),
              initialValue: fact?.key,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Fact', isDense: true, border: OutlineInputBorder()),
              items: [
                for (final f in widget.catalog.facts)
                  DropdownMenuItem(
                    value: f.key,
                    child: Tooltip(
                      message: f.description.isEmpty ? f.key : '${f.key}: ${f.description}',
                      child: Text('${f.label}  ·  ${f.type.name}', overflow: TextOverflow.ellipsis),
                    ),
                  ),
              ],
              onChanged: (key) {
                setState(() {
                  c.fact = key;
                  c.onFactChanged(widget.catalog[key]);
                });
                _changed();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              key: ValueKey('op-${c.id}-${fact?.key}'),
              initialValue: op?.name,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Operator', isDense: true, border: OutlineInputBorder()),
              items: [
                for (final o in fact?.operators ?? const <OperatorDef>[])
                  DropdownMenuItem(value: o.name, child: Text(o.label, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: fact == null
                  ? null
                  : (name) {
                      setState(() => c.operator = name);
                      _changed();
                    },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _valueInput(fact, op)),
          IconButton(tooltip: 'Remove condition', icon: const Icon(Icons.close), onPressed: widget.onRemove),
        ],
      ),
    );
  }

  Widget _valueInput(FactDef? fact, OperatorDef? op) {
    if (fact == null || op == null) return const SizedBox.shrink();
    if (!op.needsValue) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('no value needed', style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }
    final canRef = op.arity == Arity.one && !op.takesDayCount && widget.catalog.ofType(fact.type).length > 1;
    final refToggle = canRef
        ? IconButton(
            tooltip: c.refFact == null ? 'Compare with another fact' : 'Compare with a fixed value',
            icon: Icon(c.refFact == null ? Icons.link : Icons.link_off),
            onPressed: () {
              setState(() => c.refFact = c.refFact == null
                  ? widget.catalog.ofType(fact.type).firstWhere((f) => f.key != fact.key).key
                  : null);
              _changed();
            },
          )
        : null;

    Widget field;
    if (c.refFact != null && canRef) {
      field = DropdownButtonFormField<String>(
        key: ValueKey('ref-${c.id}'),
        initialValue: c.refFact,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Other fact', isDense: true, border: OutlineInputBorder()),
        items: [
          for (final f in widget.catalog.ofType(fact.type))
            if (f.key != fact.key) DropdownMenuItem(value: f.key, child: Text(f.label, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) {
          setState(() => c.refFact = v);
          _changed();
        },
      );
    } else if (fact.type == FactType.bool && op.arity == Arity.one) {
      field = Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<bool>(
          key: ValueKey('bool-${c.id}'),
          segments: const [ButtonSegment(value: true, label: Text('Yes')), ButtonSegment(value: false, label: Text('No'))],
          selected: {c.boolValue},
          showSelectedIcon: false,
          onSelectionChanged: (s) {
            setState(() => c.boolValue = s.first);
            _changed();
          },
        ),
      );
    } else if (op.arity == Arity.two) {
      field = Row(children: [
        Expanded(child: _textField(_low, 'From', fact, (v) => c.low = v, key: 'low')),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('and')),
        Expanded(child: _textField(_high, 'To', fact, (v) => c.high = v, key: 'high')),
      ]);
    } else if (op.arity == Arity.list) {
      field = _textField(_text, 'Values, comma separated', fact, (v) => c.text = v, key: 'list', listHint: true);
    } else if (op.takesDayCount) {
      field = _textField(_text, 'Days', fact, (v) => c.text = v, key: 'days', numeric: true);
    } else {
      field = _textField(_text, 'Value', fact, (v) => c.text = v, key: 'value');
    }
    return Row(children: [Expanded(child: field), if (refToggle != null) refToggle]);
  }

  Widget _textField(TextEditingController ctl, String label, FactDef fact, void Function(String) set,
      {required String key, bool numeric = false, bool listHint = false}) {
    final isDate = fact.type == FactType.date && !numeric;
    return TextField(
      key: ValueKey('$key-${c.id}'),
      controller: ctl,
      keyboardType: numeric || fact.type == FactType.number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: listHint
            ? (fact.type == FactType.number ? '0, 5, 12, 18, 28' : 'a, b, c')
            : isDate
                ? 'YYYY-MM-DD'
                : null,
        isDense: true,
        border: const OutlineInputBorder(),
        suffixIcon: isDate
            ? IconButton(
                icon: const Icon(Icons.calendar_today, size: 18),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(ctl.text) ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    ctl.text = picked.toIso8601String().substring(0, 10);
                    set(ctl.text);
                    _changed();
                  }
                },
              )
            : null,
      ),
      onChanged: (v) {
        set(v);
        _changed();
      },
    );
  }
}
