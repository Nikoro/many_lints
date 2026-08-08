import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a collection literal contains the same element twice.
///
/// A hand-written literal listing the same value twice is almost always a
/// mistake — usually one entry was meant to be a different value. Three
/// shapes are reported: repeated plain values in a list, repeated spreads
/// (`...items` twice), and repeated `if` elements.
///
/// Plain values in sets and maps are left alone: the analyzer already
/// reports duplicate set elements and map keys natively.
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
  void visitListLiteral(ListLiteral node) => _check(node.elements);

  /// Sets and maps are checked for spreads and `if` elements only: the
  /// analyzer already reports duplicate set values and map keys natively.
  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    final seen = <String>{};

    for (final element in node.elements) {
      if (element is Expression || element is MapLiteralEntry) continue;
      if (!_isComparable(element)) continue;

      final source = element.toSource();
      if (!seen.add(source)) {
        rule.reportAtNode(element, arguments: [source]);
      }
    }
  }

  void _check(NodeList<CollectionElement> elements) {
    final seen = <String>{};

    for (final element in elements) {
      // A spread or an `if` element contributes an unknown number of values,
      // but writing the identical one twice is still a duplicate: the second
      // copy either repeats every value or is dead weight.
      if (!_isComparable(element)) continue;

      final source = element.toSource();
      if (!seen.add(source)) {
        rule.reportAtNode(element, arguments: [source]);
      }
    }
  }

  /// Whether [element] denotes the same contribution everywhere it appears.
  ///
  /// Comparing by source is only sound when re-evaluating the element yields
  /// the same result; a method call may return something different each time.
  bool _isComparable(CollectionElement element) => switch (element) {
    Expression() => _isStable(element),
    SpreadElement(:final expression) => _isStable(expression),
    IfElement(:final expression, :final thenElement, :final elseElement) =>
      _isStable(expression) &&
          _isComparable(thenElement) &&
          (elseElement == null || _isComparable(elseElement)),
    _ => false,
  };

  /// Whether an expression denotes the same value everywhere it appears.
  bool _isStable(Expression expression) => switch (expression) {
    Literal() => true,
    SimpleIdentifier() => true,
    PrefixedIdentifier() => true,
    PropertyAccess(:final target) => target == null || _isStable(target),
    _ => false,
  };
}
