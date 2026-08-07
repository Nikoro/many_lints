import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when an operation that throws on an empty collection is used
/// without an emptiness check.
///
/// `first`, `last`, `single` and `reduce` all throw a `StateError` on an
/// empty iterable. The stack trace points into `dart:core`, so the crash
/// reads as a framework bug rather than a missing guard.
///
/// Detection is intentionally narrow: only a directly named collection —
/// a local, parameter, or field — with no emptiness check anywhere in the
/// enclosing function is reported.
class AvoidUnsafeCollectionMethods extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unsafe_collection_methods',
    "'{0}' throws if the collection is empty.",
    correctionMessage:
        "Guard with an 'isNotEmpty' check, or use a safe alternative such "
        "as 'firstOrNull', 'lastOrNull', 'singleOrNull' or 'fold'.",
  );

  AvoidUnsafeCollectionMethods()
    : super(
        name: 'avoid_unsafe_collection_methods',
        description:
            'Warns when first, last, single or reduce is used on a '
            'collection without checking that it is not empty.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addPrefixedIdentifier(this, visitor);
    registry.addPropertyAccess(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnsafeCollectionMethods rule;

  _Visitor(this.rule);

  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');

  /// Properties that throw on an empty iterable.
  static const _unsafeProperties = {'first', 'last', 'single'};

  /// Methods that throw on an empty iterable.
  ///
  /// `singleWhere` is deliberately excluded: it throws when no element
  /// matches, which an emptiness guard would not prevent.
  static const _unsafeMethods = {'reduce'};

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // `items.first` where `items` is a simple identifier.
    _check(node, node.prefix, node.identifier.name, _unsafeProperties);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target == null) return;
    _check(node, target, node.propertyName.name, _unsafeProperties);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.realTarget;
    if (target == null) return;
    _check(node, target, node.methodName.name, _unsafeMethods);
  }

  void _check(
    AstNode node,
    Expression target,
    String memberName,
    Set<String> unsafeMembers,
  ) {
    if (!unsafeMembers.contains(memberName)) return;

    // The receiver must be a plain name we can look for in guards. A chained
    // expression (`a.where(...).first`) has no name to match against, so it
    // is left alone rather than guessed at.
    final receiverName = switch (target) {
      SimpleIdentifier(:final name) => name,
      _ => null,
    };
    if (receiverName == null) return;

    final targetType = target.staticType;
    if (targetType == null) return;
    if (!_iterableChecker.isAssignableFromType(targetType)) return;

    // A collection literal with elements is provably non-empty.
    if (_isNonEmptyLiteral(target)) return;

    final enclosingFunction = _enclosingFunctionBody(node);
    if (enclosingFunction == null) return;

    // Any emptiness check on this receiver anywhere in the function is
    // treated as a guard. This over-accepts (the check may be in an
    // unrelated branch) on purpose, to keep false positives near zero.
    final guardFinder = _EmptinessCheckFinder(receiverName);
    enclosingFunction.accept(guardFinder);
    if (guardFinder.found) return;

    rule.reportAtNode(node, arguments: [memberName]);
  }

  bool _isNonEmptyLiteral(Expression expression) => switch (expression) {
    ListLiteral(:final elements) => elements.isNotEmpty,
    SetOrMapLiteral(:final elements) => elements.isNotEmpty,
    _ => false,
  };

  AstNode? _enclosingFunctionBody(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is FunctionBody) return current;
    }
    return null;
  }
}

/// Looks for any emptiness or length check mentioning [receiverName].
class _EmptinessCheckFinder extends RecursiveAstVisitor<void> {
  final String receiverName;
  bool found = false;

  _EmptinessCheckFinder(this.receiverName);

  static const _guardMembers = {
    'isEmpty',
    'isNotEmpty',
    'length',
    'firstOrNull',
    'lastOrNull',
    'singleOrNull',
  };

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == receiverName &&
        _guardMembers.contains(node.identifier.name)) {
      found = true;
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target case SimpleIdentifier(name: final name)
        when name == receiverName &&
            _guardMembers.contains(node.propertyName.name)) {
      found = true;
      return;
    }
    super.visitPropertyAccess(node);
  }
}
