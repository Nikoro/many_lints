import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a list literal contains the same element twice.
///
/// A hand-written literal listing the same value twice is almost always a
/// mistake — usually one entry was meant to be a different value.
///
/// Sets and maps are not checked here: the analyzer already reports
/// duplicate set elements and map keys natively.
class AvoidDuplicateCollectionElements extends AnalysisRule {
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
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addListLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidDuplicateCollectionElements rule;

  _Visitor(this.rule);

  @override
  void visitListLiteral(ListLiteral node) => _check(node.elements);

  void _check(NodeList<CollectionElement> elements) {
    final seen = <String>{};

    for (final element in elements) {
      // Only plain values are compared. A spread or an `if` contributes an
      // unknown set of elements, so nothing after it can be judged.
      if (element is! Expression) return;

      // Comparing by source is only sound for expressions that always
      // evaluate the same way; a call may differ between elements.
      if (!_isStable(element)) continue;

      final source = element.toSource();
      if (!seen.add(source)) {
        rule.reportAtNode(element, arguments: [source]);
      }
    }
  }

  /// Whether an expression denotes the same value everywhere it appears.
  bool _isStable(Expression expression) => switch (expression) {
    Literal() => true,
    SimpleIdentifier() => true,
    PrefixedIdentifier() => true,
    PropertyAccess(:final target) => target == null || _isStable(target),
    _ => false,
  };
}
