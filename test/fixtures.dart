import 'package:rule_builder/models/catalog.dart';

/// Subset of DocFlow's real fact catalog for the invoice document type.
final catalogJson = [
  {
    'key': 'total_amount', 'label': 'Grand total', 'type': 'number', 'description': '',
    'operators': [
      {'name': 'equalTo', 'label': 'equals', 'arity': 'one', 'needs_value': true},
      {'name': 'greaterThan', 'label': 'greater than', 'arity': 'one', 'needs_value': true},
      {'name': 'lessThanOrEqual', 'label': 'less than or equal to', 'arity': 'one', 'needs_value': true},
      {'name': 'between', 'label': 'between (inclusive)', 'arity': 'two', 'needs_value': true},
      {'name': 'in', 'label': 'is one of', 'arity': 'list', 'needs_value': true},
      {'name': 'exists', 'label': 'has a value', 'arity': 'none', 'needs_value': false},
    ],
  },
  {
    'key': 'subtotal', 'label': 'Subtotal', 'type': 'number', 'description': '',
    'operators': [
      {'name': 'greaterThan', 'label': 'greater than', 'arity': 'one', 'needs_value': true},
    ],
  },
  {
    'key': 'vendor_name', 'label': 'Vendor name', 'type': 'string', 'description': '',
    'operators': [
      {'name': 'contains', 'label': 'contains', 'arity': 'one', 'needs_value': true},
      {'name': 'exists', 'label': 'has a value', 'arity': 'none', 'needs_value': false},
    ],
  },
  {
    'key': 'vendor_approved', 'label': 'Vendor approved', 'type': 'bool', 'description': '',
    'operators': [
      {'name': 'equalTo', 'label': 'equals', 'arity': 'one', 'needs_value': true},
    ],
  },
  {
    'key': 'due_date', 'label': 'Due date', 'type': 'date', 'description': '',
    'operators': [
      {'name': 'lessThan', 'label': 'less than', 'arity': 'one', 'needs_value': true},
      {'name': 'withinNextDays', 'label': 'is within the next N days', 'arity': 'one', 'needs_value': true},
    ],
  },
];

FactCatalog catalog() => FactCatalog.fromJson(catalogJson);

/// The "Auto-approve" rule set exactly as DocFlow's seed_demo stores it.
final seedTree = {
  'type': 'all',
  'rules': [
    {'fact': 'vendor_approved', 'operator': 'equalTo', 'value': true},
    {'fact': 'total_amount', 'operator': 'lessThanOrEqual', 'value': 200000},
    {
      'type': 'any',
      'rules': [
        {'fact': 'total_amount', 'operator': 'in', 'value': [0, 5, 12, 18, 28]},
        {'fact': 'vendor_name', 'operator': 'exists'},
      ],
    },
  ],
};
