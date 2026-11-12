import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ordering_check.dart';

class MapKeysOrdering extends ManyLintsRule {
  static const LintCode code = LintCode(
    'map_keys_ordering',
    "The key '{0}' is out of order.",
    correctionMessage: 'Move it so the keys stay in the configured order.',
  );

  MapKeysOrdering()
    : super(
        name: 'map_keys_ordering',
        description:
            "Warns when a map literal's keys are not in the configured order.",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addSetOrMapLiteral(this, _Visitor(this));
  }
}

const _defaultMinEntries = 5;

class _Visitor extends SimpleAstVisitor<void> {
  final MapKeysOrdering rule;

  _Visitor(this.rule);

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    final configured = rule.config.options['order'];
    if (configured is! String) return;

    final minEntries = rule.config.intOption(
      'min_entries',
      defaultValue: _defaultMinEntries,
    );

    final entries = node.elements.whereType<MapLiteralEntry>().toList(
      growable: false,
    );
    final hasSpreadOrControlFlow = entries.length != node.elements.length;
    if (hasSpreadOrControlFlow) return;
    if (entries.length < minEntries) return;

    final names = <String>[];
    for (final entry in entries) {
      final name = _sortableKeyName(entry.key);
      if (name == null) return;
      names.add(name);
    }

    final mode = OrderingMode.parse(configured);
    final index = firstUnorderedIndex(names, mode);
    if (index == null) return;

    rule.reportAtNode(entries[index].key, arguments: [names[index]]);
  }

  String? _sortableKeyName(Expression key) => switch (key) {
    SimpleStringLiteral(:final value) => value,
    SimpleIdentifier(:final name) => name,
    PrefixedIdentifier(:final identifier) => identifier.name,
    PropertyAccess(:final propertyName) => propertyName.name,
    _ => null,
  };
}
