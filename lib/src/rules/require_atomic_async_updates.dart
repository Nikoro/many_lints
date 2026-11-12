import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class RequireAtomicAsyncUpdates extends ManyLintsRule {
  static const LintCode code = LintCode(
    'require_atomic_async_updates',
    "Field '{0}' is read before an await and written after it.",
    correctionMessage:
        'Re-read the field after the await, since another call may have '
        'assigned to it while this one was suspended.',
  );

  RequireAtomicAsyncUpdates()
    : super(
        name: 'require_atomic_async_updates',
        description:
            'Warns when a field is read before an await and updated after '
            'it, which can lose a concurrent update.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final RequireAtomicAsyncUpdates rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) => _checkBody(node.body);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _checkBody(node.functionExpression.body);

  void _checkBody(FunctionBody body) {
    if (!body.isAsynchronous) return;
    if (body is! BlockFunctionBody) return;

    final includeLocals = rule.config.boolOption(
      'include_local_variables',
      defaultValue: false,
    );

    _scan(body.block.statements, includeLocals: includeLocals);
  }

  void _scan(List<Statement> statements, {required bool includeLocals}) {
    final readBeforeAwait = <Element, String>{};
    var seenAwait = false;

    for (final statement in statements) {
      if (seenAwait) {
        statement.accept(
          _StaleWriteFinder(
            rule,
            readBeforeAwait,
            includeLocals: includeLocals,
          ),
        );
      }

      // Edge case: reads after one await are still stale relative to the next await
      final reads = _ReadCollector(includeLocals: includeLocals);
      statement.accept(reads);
      readBeforeAwait.addAll(reads.found);

      _taintLocalsCapturingStaleReads(statement, readBeforeAwait);

      if (_containsAwait(statement)) seenAwait = true;
    }
  }

  void _taintLocalsCapturingStaleReads(
    Statement statement,
    Map<Element, String> stale,
  ) {
    if (statement is! VariableDeclarationStatement) return;

    for (final variable in statement.variables.variables) {
      final initializer = variable.initializer;
      if (initializer == null) continue;

      final finder = _StaleReadFinder(stale.keys.toSet());
      initializer.accept(finder);
      if (!finder.found) continue;

      final element = variable.declaredFragment?.element;
      if (element != null) stale[element] = variable.name.lexeme;
    }
  }
}

class _ReadCollector extends RecursiveAstVisitor<void> {
  final bool includeLocals;
  final Map<Element, String> found = {};

  _ReadCollector({required this.includeLocals});

  void _record(SimpleIdentifier identifier) {
    if (_isPureWrite(identifier)) return;

    final element = identifier.element;
    if (element == null) return;
    if (!_isTrackable(element, includeLocals: includeLocals)) return;

    found[element] = identifier.name;
  }

  static bool _isPureWrite(SimpleIdentifier identifier) =>
      identifier.inSetterContext() && !identifier.inGetterContext();

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) => _record(node);

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target is ThisExpression) _record(node.propertyName);
    super.visitPropertyAccess(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

class _StaleWriteFinder extends RecursiveAstVisitor<void> {
  final RequireAtomicAsyncUpdates rule;
  final Map<Element, String> readBeforeAwait;
  final bool includeLocals;

  _StaleWriteFinder(
    this.rule,
    this.readBeforeAwait, {
    required this.includeLocals,
  });

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    super.visitAssignmentExpression(node);

    final target = _targetIdentifier(node.leftHandSide);
    if (target == null) return;

    // Edge case: `element` is null on the left of a compound assignment like `_value += 1`
    final element = node.writeElement ?? target.element;
    if (element == null) return;
    if (!_isTrackable(element, includeLocals: includeLocals)) return;
    if (!_matchesStale(element)) return;

    if (_overwritesWithoutReading(node)) return;

    rule.reportAtNode(node, arguments: [target.name]);
  }

  bool _matchesStale(Element element) {
    final canonical = _canonicalElement(element);

    return readBeforeAwait.keys.any(
      (stale) => _canonicalElement(stale) == canonical,
    );
  }

  bool _overwritesWithoutReading(AssignmentExpression node) =>
      node.operator.lexeme == '=' && !_dependsOnStaleValue(node.rightHandSide);

  bool _dependsOnStaleValue(Expression expression) {
    final finder = _StaleReadFinder(readBeforeAwait.keys.toSet());
    expression.accept(finder);

    return finder.found;
  }

  SimpleIdentifier? _targetIdentifier(Expression leftHandSide) =>
      switch (leftHandSide) {
        SimpleIdentifier() => leftHandSide,
        PropertyAccess(target: ThisExpression()) => leftHandSide.propertyName,
        _ => null,
      };

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

class _StaleReadFinder extends RecursiveAstVisitor<void> {
  final Set<Element> stale;
  bool found = false;

  _StaleReadFinder(Set<Element> stale)
    : stale = stale.map(_canonicalElement).toSet();

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    if (element != null && stale.contains(_canonicalElement(element))) {
      found = true;
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

Element _canonicalElement(Element element) => switch (element) {
  GetterElement(:final variable) => variable,
  SetterElement(:final variable) => variable,
  _ => element,
};

bool _isTrackable(Element element, {required bool includeLocals}) {
  final canonical = _canonicalElement(element);

  if (canonical is FieldElement) return !canonical.isStatic;
  if (includeLocals && canonical is LocalVariableElement) return true;

  return false;
}

bool _containsAwait(AstNode node) {
  final finder = _AwaitFinder();
  node.accept(finder);

  return finder.found;
}

class _AwaitFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitAwaitExpression(AwaitExpression node) => found = true;

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
