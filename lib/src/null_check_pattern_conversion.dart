import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

class NullCheckGuard {
  final IfStatement ifStatement;

  final BinaryExpression condition;

  final Expression checked;

  final Statement guardedBranch;

  final Element target;

  NullCheckGuard._({
    required this.ifStatement,
    required this.condition,
    required this.checked,
    required this.guardedBranch,
    required this.target,
  });

  String get checkedSource => checked.toSource();

  static NullCheckGuard? tryRead(AstNode node) {
    final ifStatement = _enclosingIf(node);
    if (ifStatement == null) return null;

    if (ifStatement.caseClause != null) return null;

    final condition = ifStatement.expression;
    if (condition is! BinaryExpression) return null;
    if (condition.operator.lexeme != '!=') return null;

    final checked = switch ((condition.leftOperand, condition.rightOperand)) {
      (final Expression e, NullLiteral()) => e,
      (NullLiteral(), final Expression e) => e,
      _ => null,
    };
    if (checked == null) return null;

    // Edge case: the subject is evaluated again as the pattern subject, so calls are refused
    final target = _canonicalElement(checked);
    if (target == null) return null;

    final guardedBranch = ifStatement.thenStatement;

    return NullCheckGuard._(
      ifStatement: ifStatement,
      condition: condition,
      checked: checked,
      guardedBranch: guardedBranch,
      target: target,
    );
  }

  List<AstNode> get bangsInGuardedBranch {
    final finder = _UseFinder(target);
    guardedBranch.accept(finder);
    return finder.bangs;
  }

  List<AstNode> get plainReadsInGuardedBranch {
    final finder = _UseFinder(target);
    guardedBranch.accept(finder);
    return finder.plainReads;
  }

  String suggestedName() {
    final base = switch (checked) {
      SimpleIdentifier(:final name) => name,
      PrefixedIdentifier(:final identifier) => identifier.name,
      PropertyAccess(:final propertyName) => propertyName.name,
      _ => 'value',
    };

    return _isNameTaken(base) ? '${base}_' : base;
  }

  bool _isNameTaken(String name) {
    if (checked case SimpleIdentifier(name: final checkedName)) {
      // Edge case: `if (userData case final userData?)` leaves the outer name nullable
      if (checkedName == name) return true;
    }

    final finder = _NameFinder(name);
    ifStatement.accept(finder);
    return finder.found;
  }

  static IfStatement? _enclosingIf(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is IfStatement) return current;
      if (current is FunctionBody) return null;
    }
    return null;
  }
}

Element? _canonicalElement(Expression? expression) {
  var target = expression;
  while (target is ParenthesizedExpression) {
    target = target.expression;
  }

  final element = switch (target) {
    SimpleIdentifier(:final element) => element,
    PrefixedIdentifier(:final identifier) => identifier.element,
    PropertyAccess(target: ThisExpression(), :final propertyName) =>
      propertyName.element,
    _ => null,
  };

  return switch (element) {
    GetterElement(:final variable) => variable,
    SetterElement(:final variable) => variable,
    _ => element,
  };
}

class _UseFinder extends RecursiveAstVisitor<void> {
  final Element target;

  final List<AstNode> bangs = [];

  final List<AstNode> plainReads = [];

  _UseFinder(this.target);

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.lexeme == '!' &&
        _canonicalElement(node.operand) == target) {
      bangs.add(node);
      // Edge case: descending would record the operand again and double-edit its range
      return;
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final parent = node.parent;
    if (parent is PrefixedIdentifier && parent.identifier == node) return;
    if (parent is PropertyAccess && parent.propertyName == node) return;

    if (_canonicalElement(node) == target) plainReads.add(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_canonicalElement(node) == target) {
      plainReads.add(node);
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_canonicalElement(node) == target) {
      plainReads.add(node);
      return;
    }
    super.visitPropertyAccess(node);
  }
}

class _NameFinder extends RecursiveAstVisitor<void> {
  final String name;
  bool found = false;

  _NameFinder(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name) found = true;
  }
}
