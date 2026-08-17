import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ordering_check.dart';

/// Warns when a map literal's keys are not in the configured order.
///
/// A long map literal is a lookup table, and an unordered one has to be read
/// end to end to answer "is this key here?". Ordering also keeps a diff
/// honest: a new key lands in the middle where it can be seen, rather than
/// appended at the end beside a duplicate nobody noticed.
///
/// **Outside the `pedantic` preset, this rule reports nothing until
/// configured.** Many map literals are deliberately ordered by meaning — a
/// config map mirroring a form's field order, a theme map going from lightest
/// to darkest — and alphabetising those would be a regression. Set
/// `order: alphabetical` (or `by_length`, or
/// `alphabetical_case_sensitive`) where a mechanical order is wanted.
///
/// Only literals whose keys are *all* simple strings or identifiers are
/// checked; a computed key has no name to sort by, so such a map is skipped
/// entirely rather than partially ordered. `min_entries` (default 5) keeps
/// short maps, where order carries no cost, out of it.
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

/// Below this, a reader takes in the whole literal at once and order is free.
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
    // A spread, `if` or `for` element means the literal's contents are not
    // statically ordered at all, so there is nothing to check.
    if (entries.length != node.elements.length) return;
    if (entries.length < minEntries) return;

    final names = <String>[];
    for (final entry in entries) {
      final name = _keyName(entry.key);
      // One computed key makes the whole literal unsortable: ordering the
      // rest around it would produce an arrangement the user cannot reach.
      if (name == null) return;
      names.add(name);
    }

    final mode = OrderingMode.parse(configured);
    final index = firstUnorderedIndex(names, mode);
    if (index == null) return;

    rule.reportAtNode(entries[index].key, arguments: [names[index]]);
  }

  /// The sortable name of a key, or `null` when it is computed.
  String? _keyName(Expression key) => switch (key) {
    SimpleStringLiteral(:final value) => value,
    SimpleIdentifier(:final name) => name,
    PrefixedIdentifier(:final identifier) => identifier.name,
    PropertyAccess(:final propertyName) => propertyName.name,
    _ => null,
  };
}
