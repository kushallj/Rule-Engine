import 'package:material_ui/material_ui.dart';

/// Renders DocFlow's evaluation trace: every group and condition with pass / fail
/// and the actual value the rule saw.
class TraceView extends StatelessWidget {
  final Map<String, dynamic> node;
  const TraceView({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final passed = node['passed'] == true;
    final isCondition = node['kind'] == 'condition';
    final children = (node['children'] as List? ?? const []).cast<Map<String, dynamic>>();
    final theme = Theme.of(context);
    final ok = const Color(0xFF137A43);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(passed ? Icons.check_circle : Icons.cancel, size: 18, color: passed ? ok : muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                    text: node['description'] as String? ?? '',
                    style: TextStyle(fontWeight: isCondition ? FontWeight.normal : FontWeight.w600),
                  ),
                  if (isCondition)
                    TextSpan(
                      text: '   actual: ${node['actual'] ?? '(empty)'}',
                      style: TextStyle(color: muted, fontFamily: 'monospace', fontSize: 12),
                    ),
                  if (node['error'] != null)
                    TextSpan(text: '   ${node['error']}', style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                ])),
              ),
            ],
          ),
          if (children.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 2),
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(border: Border(left: BorderSide(color: theme.dividerColor, width: 2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final c in children) TraceView(node: c)],
              ),
            ),
        ],
      ),
    );
  }
}
