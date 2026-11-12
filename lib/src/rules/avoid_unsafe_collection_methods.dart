import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

class AvoidUnsafeCollectionMethods extends ManyLintsRule {
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
  void registerManyLintsProcessors(
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

  static const _unsafeProperties = {'first', 'last', 'single'};

  static const _unsafeMethods = {'reduce'};

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
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

    final receiverName = switch (target) {
      SimpleIdentifier(:final name) => name,
      _ => null,
    };
    if (receiverName == null) return;

    final targetType = target.staticType;
    if (targetType == null) return;
    if (!_iterableChecker.isAssignableFromType(targetType)) return;

    if (_isNonEmptyLiteral(target)) return;

    final enclosingFunction = enclosingOfType<FunctionBody>(node);
    if (enclosingFunction == null) return;

    // Edge case: a check in an unrelated branch counts too, to keep false positives near zero
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
}

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
