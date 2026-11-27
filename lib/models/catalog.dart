/// Fact catalog served by DocFlow at GET /api/document-types/{slug}/facts/.
library;

enum FactType { string, number, bool, date }

FactType factTypeFrom(String raw) {
  switch (raw) {
    case 'number':
    case 'int':
    case 'double':
      return FactType.number;
    case 'bool':
      return FactType.bool;
    case 'date':
      return FactType.date;
    default:
      return FactType.string;
  }
}

/// "none" (exists), "one" (greaterThan 5), "two" (between [a, b]), "list" (in [a, b, c])
enum Arity { none, one, two, list }

class OperatorDef {
  final String name;
  final String label;
  final Arity arity;
  final bool needsValue;

  const OperatorDef({required this.name, required this.label, required this.arity, required this.needsValue});

  /// olderThanDays / withinNextDays take a number of days, not a date.
  bool get takesDayCount => name == 'olderThanDays' || name == 'withinNextDays';

  factory OperatorDef.fromJson(Map<String, dynamic> j) => OperatorDef(
        name: j['name'] as String,
        label: j['label'] as String,
        arity: Arity.values.byName(j['arity'] as String),
        needsValue: j['needs_value'] as bool? ?? true,
      );
}

class FactDef {
  final String key;
  final String label;
  final FactType type;
  final String description;
  final List<OperatorDef> operators;

  const FactDef({
    required this.key,
    required this.label,
    required this.type,
    this.description = '',
    this.operators = const [],
  });

  OperatorDef? operator(String? name) {
    for (final op in operators) {
      if (op.name == name) return op;
    }
    return null;
  }

  factory FactDef.fromJson(Map<String, dynamic> j) => FactDef(
        key: j['key'] as String,
        label: j['label'] as String,
        type: factTypeFrom(j['type'] as String),
        description: j['description'] as String? ?? '',
        operators: [
          for (final o in (j['operators'] as List? ?? const [])) OperatorDef.fromJson(o as Map<String, dynamic>)
        ],
      );
}

class FactCatalog {
  final List<FactDef> facts;
  final Map<String, FactDef> _byKey;

  FactCatalog(this.facts) : _byKey = {for (final f in facts) f.key: f};

  FactDef? operator [](String? key) => key == null ? null : _byKey[key];

  List<FactDef> ofType(FactType t) => facts.where((f) => f.type == t).toList();

  factory FactCatalog.fromJson(List<dynamic> list) =>
      FactCatalog([for (final f in list) FactDef.fromJson(f as Map<String, dynamic>)]);
}

class DocumentTypeInfo {
  final String slug;
  final String name;

  const DocumentTypeInfo(this.slug, this.name);

  factory DocumentTypeInfo.fromJson(Map<String, dynamic> j) =>
      DocumentTypeInfo(j['slug'] as String, j['name'] as String);
}

class DocumentSummary {
  final int id;
  final String name;
  final String status;
  final String? vendor;
  final String? invoiceNumber;

  const DocumentSummary({required this.id, required this.name, required this.status, this.vendor, this.invoiceNumber});

  factory DocumentSummary.fromJson(Map<String, dynamic> j) {
    final s = (j['summary'] as Map?) ?? const {};
    return DocumentSummary(
      id: j['id'] as int,
      name: j['original_name'] as String,
      status: j['status'] as String,
      vendor: s['vendor_name']?.toString(),
      invoiceNumber: s['invoice_number']?.toString(),
    );
  }

  String get title => [vendor, invoiceNumber].whereType<String>().join(' · ').ifEmpty(name);
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
