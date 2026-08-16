import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../ordering_check.dart';

/// Warns when a constructor's field initializers are not in the same order as
/// the fields they assign.
///
/// Unlike its ordering siblings this rule has a **useful default**: it matches
/// the initializer list against the class's own field declaration order rather
/// than against an alphabet. That order is already a decision the class made,
/// so following it costs nothing and makes a missing initializer visible as a
/// gap rather than as a name buried in a differently-ordered list.
///
/// Set `order: alphabetical` (or `by_length`, or
/// `alphabetical_case_sensitive`) to sort by name instead. Initializers that
/// are not plain field assignments — `super()`, `assert()`, a redirect — are
/// skipped, since their position is fixed by the language or by intent.
class InitializersOrdering extends ManyLintsRule {
  static const LintCode code = LintCode(
    'initializers_ordering',
    "The initializer for '{0}' is out of order.",
    correctionMessage:
        'Move it so the initializers stay in the configured order.',
  );

  InitializersOrdering()
    : super(
        name: 'initializers_ordering',
        description: 'Warns when initializers are not in the configured order.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addConstructorDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final InitializersOrdering rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final assignments = node.initializers
        .whereType<ConstructorFieldInitializer>()
        .toList(growable: false);
    if (assignments.length < 2) return;

    final names = assignments
        .map((initializer) => initializer.fieldName.name)
        .toList(growable: false);

    final configured = rule.config.options['order'];
    if (configured is String) {
      final mode = OrderingMode.parse(configured);
      final index = firstUnorderedIndex(names, mode);
      if (index != null) {
        rule.reportAtNode(
          assignments[index].fieldName,
          arguments: [names[index]],
        );
      }
      return;
    }

    // The default: follow the class's own field declaration order, which is a
    // decision the class already made.
    final declared = _declaredFieldOrder(node);
    if (declared.isEmpty) return;

    final positions = <int>[];
    for (final name in names) {
      final position = declared.indexOf(name);
      // An initializer for something the class does not declare as a field —
      // an inherited field, a setter — has no position to compare.
      if (position < 0) return;
      positions.add(position);
    }

    for (var i = 1; i < positions.length; i++) {
      if (positions[i - 1] <= positions[i]) continue;

      rule.reportAtNode(assignments[i].fieldName, arguments: [names[i]]);
      return;
    }
  }

  /// The names of the fields the enclosing class declares, in source order.
  List<String> _declaredFieldOrder(ConstructorDeclaration node) {
    final body = node.parent;
    if (body is! BlockClassBody) return const [];

    return [
      for (final member in body.members.whereType<FieldDeclaration>())
        for (final variable in member.fields.variables) variable.name.lexeme,
    ];
  }
}
