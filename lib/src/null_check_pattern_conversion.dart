import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/// An `if (x != null)` guard that can be rewritten as a pattern.
///
/// Shared by `ConvertNullCheckToPattern` and
/// `InlineNullCheckIntoPattern` so the two cannot drift on which shapes they
/// accept or on how they find the uses inside the guarded branch.
class NullCheckGuard {
  /// The `if` being converted.
  final IfStatement ifStatement;

  /// The condition to replace, i.e. `x != null`.
  final BinaryExpression condition;

  /// The expression checked against null, i.e. `x`.
  final Expression checked;

  /// The branch the check proves non-null.
  final Statement guardedBranch;

  /// The element [checked] resolves to, canonicalized across getter/setter.
  final Element target;

  NullCheckGuard._({
    required this.ifStatement,
    required this.condition,
    required this.checked,
    required this.guardedBranch,
    required this.target,
  });

  /// The source text of the checked expression, for the pattern's subject.
  String get checkedSource => checked.toSource();

  /// Reads the guard the cursor sits in, or `null` when there is none.
  ///
  /// Only `x != null` is accepted, never `x == null`. The `==` form guards its
  /// *else* branch, and an early-return `if (x == null) return;` promotes the
  /// code *after* the `if` — neither is expressible as a single `case`
  /// pattern, so both are declined rather than mistranslated.
  static NullCheckGuard? tryRead(AstNode node) {
    final ifStatement = _enclosingIf(node);
    if (ifStatement == null) return null;

    // An `if` that already has a pattern is not a plain null check.
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

    // The subject is re-evaluated once as the pattern's subject, so it must be
    // a plain read. A call could have side effects or return a different value
    // the second time, which the original code never risked.
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

  /// Every `checked!` inside the guarded branch, as the node to replace.
  ///
  /// The bang and its operand are replaced together — `field!` becomes the
  /// bound name — so the returned nodes are the whole [PostfixExpression].
  List<AstNode> get bangsInGuardedBranch {
    final finder = _UseFinder(target);
    guardedBranch.accept(finder);
    return finder.bangs;
  }

  /// Every bare read of the checked storage inside the guarded branch.
  ///
  /// These must be rewritten alongside the bangs: leaving one behind would mix
  /// the original nullable expression with the new pattern variable, which
  /// reads as if they were different values.
  List<AstNode> get plainReadsInGuardedBranch {
    final finder = _UseFinder(target);
    guardedBranch.accept(finder);
    return finder.plainReads;
  }

  /// A name for the bound variable, derived from the checked expression.
  ///
  /// `userData` → `userData`, `a.field` → `field`. When that name is already
  /// taken in the enclosing scope — which it always is for a local, since the
  /// local *is* the checked expression — a `_` suffix keeps it distinct
  /// without inventing an unrelated word. The result is offered as a linked
  /// edit, so the author renames it in place.
  String suggestedName() {
    final base = switch (checked) {
      SimpleIdentifier(:final name) => name,
      PrefixedIdentifier(:final identifier) => identifier.name,
      PropertyAccess(:final propertyName) => propertyName.name,
      _ => 'value',
    };

    return _isNameTaken(base) ? '${base}_' : base;
  }

  /// Whether [name] already resolves to something in the guarded branch.
  ///
  /// A local checked by the guard shadows nothing new, but reusing its own
  /// name would make the pattern variable indistinguishable from the field or
  /// local it was bound from.
  bool _isNameTaken(String name) {
    if (checked case SimpleIdentifier(name: final checkedName)) {
      // `if (userData case final userData?)` is legal but confusing, and the
      // outer `userData` stays nullable — keep them visibly distinct.
      if (checkedName == name) return true;
    }

    final finder = _NameFinder(name);
    ifStatement.accept(finder);
    return finder.found;
  }

  /// The nearest enclosing `if`, stopping at a function boundary.
  static IfStatement? _enclosingIf(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is IfStatement) return current;
      if (current is FunctionBody) return null;
    }
    return null;
  }
}

/// The element an expression refers to, canonicalized so a read and a write of
/// the same storage compare equal.
///
/// Returns `null` for anything that is not a plain read of a variable, field or
/// property — a method call must not be duplicated into a pattern subject.
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

/// Collects uses of one element inside a statement.
class _UseFinder extends RecursiveAstVisitor<void> {
  final Element target;

  /// `checked!` occurrences, as whole postfix expressions.
  final List<AstNode> bangs = [];

  /// Reads of `checked` not already covered by [bangs].
  final List<AstNode> plainReads = [];

  _UseFinder(this.target);

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.lexeme == '!' &&
        _canonicalElement(node.operand) == target) {
      bangs.add(node);
      // Do not descend: the operand is part of what is being replaced, so
      // recording it again as a plain read would double-edit the same range.
      return;
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // Only whole expressions count. `a.field` arrives as a PrefixedIdentifier
    // and is handled there; its `field` half must not also be recorded.
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

/// Detects whether a bare name is already used inside a subtree.
class _NameFinder extends RecursiveAstVisitor<void> {
  final String name;
  bool found = false;

  _NameFinder(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name) found = true;
  }
}
