import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class AvoidDuplicateCollectionElements extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_collection_elements',
    "The element '{0}' already appears in this list.",
    correctionMessage:
        'Remove the duplicate, or check whether it was meant to be a '
        'different value.',
  );

  AvoidDuplicateCollectionElements()
    : super(
        name: 'avoid_duplicate_collection_elements',
        description:
            'Warns when the same element appears more than once in a list '
            'literal.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addListLiteral(this, visitor);
    registry.addSetOrMapLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidDuplicateCollectionElements rule;

  _Visitor(this.rule);

  @override
  void visitListLiteral(ListLiteral node) => _checkListElements(node.elements);

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    final seen = <String>{};

    for (final element in node.elements) {
      // Edge case: the analyzer already reports duplicate set values and map keys
      if (element is Expression || element is MapLiteralEntry) continue;
      if (!_isComparable(element)) continue;

      final source = element.toSource();
      if (!seen.add(source)) {
        rule.reportAtNode(element, arguments: [source]);
      }
    }
  }

  void _checkListElements(NodeList<CollectionElement> elements) {
    final seen = <String>{};

    final ignoreLiterals = rule.config.boolOption(
      'ignore_literals',
      defaultValue: false,
    );

    for (final element in elements) {
      if (!_isComparable(element)) continue;
      if (ignoreLiterals && element is Literal) continue;

      final source = element.toSource();
      if (!seen.add(source)) {
        rule.reportAtNode(element, arguments: [source]);
      }
    }
  }

  bool _isComparable(CollectionElement element) => switch (element) {
    Expression() => _isStable(element),
    SpreadElement(:final expression) => _isStable(expression),
    IfElement(:final expression, :final thenElement, :final elseElement) =>
      _isStable(expression) &&
          _isComparable(thenElement) &&
          (elseElement == null || _isComparable(elseElement)),
    _ => false,
  };

  // Edge case: a method call may yield a different value on each evaluation
  bool _isStable(Expression expression) => switch (expression) {
    Literal() => true,
    SimpleIdentifier() => true,
    PrefixedIdentifier() => true,
    PropertyAccess(:final target) => target == null || _isStable(target),
    _ => false,
  };
}
