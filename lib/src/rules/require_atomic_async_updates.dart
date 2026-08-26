import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a field is read before an `await` and written after it, using
/// the value read beforehand.
///
/// The read and the write are not atomic: anything else may run during the
/// suspension and assign to the same field, and this write then silently
/// discards that. Two concurrent calls both read `0`, both compute `1`, and
/// one increment is lost.
///
/// The report is limited to writes that *depend on* the stale read. A write
/// that overwrites the field unconditionally (`_value = await fetch()`) has
/// no lost-update hazard and is not reported.
///
/// **Bad:**
/// ```dart
/// Future<void> increment() async {
///   final current = _counter;
///   await Future<void>.delayed(Duration.zero);
///   _counter = current + 1; // the value read above may be stale
/// }
/// ```
///
/// **Good:**
/// ```dart
/// Future<void> increment() async {
///   await Future<void>.delayed(Duration.zero);
///   _counter = _counter + 1; // read after the await
/// }
/// ```
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

    // `include_local_variables: true` widens the rule to captured locals.
    // A local is only shared when a closure writes to it, which is rarer and
    // harder to confirm, so the default stays at fields only.
    final includeLocals = rule.config.boolOption(
      'include_local_variables',
      defaultValue: false,
    );

    _scan(body.block.statements, includeLocals: includeLocals);
  }

  /// Walks [statements] in order, remembering which fields were read before
  /// the first `await` and reporting a later write that reuses one.
  void _scan(List<Statement> statements, {required bool includeLocals}) {
    // Elements of fields read so far, mapped to the syntax of the read, so a
    // report can name the field.
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

      // Collect reads from this statement whether or not an await has been
      // seen: a read after one await is still stale relative to the next.
      final reads = _ReadCollector(includeLocals: includeLocals);
      statement.accept(reads);
      readBeforeAwait.addAll(reads.found);

      // A local initialized from a tracked read holds that value across the
      // await, so it inherits the staleness even though the local itself is
      // not shared. Without this the canonical shape — read into a local,
      // await, then write the local back — is missed, because the write's
      // right-hand side names only the local.
      _taintLocalsCapturingStaleReads(statement, readBeforeAwait);

      if (_containsAwait(statement)) seenAwait = true;
    }
  }

  /// Adds any local declared in [statement] whose initializer reads something
  /// already in [stale], so the captured value is tracked alongside its
  /// source.
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

/// Collects field (and optionally local) reads, stopping at closures.
class _ReadCollector extends RecursiveAstVisitor<void> {
  final bool includeLocals;
  final Map<Element, String> found = {};

  _ReadCollector({required this.includeLocals});

  void _record(SimpleIdentifier identifier) {
    // A write is not a read; `_x = 1` must not seed the stale set.
    if (identifier.inSetterContext() && !identifier.inGetterContext()) return;

    final element = identifier.element;
    if (element == null) return;
    if (!_isTrackable(element, includeLocals: includeLocals)) return;

    found[element] = identifier.name;
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) => _record(node);

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // Only `this.field` is tracked — `other.field` belongs to an object this
    // method does not control, so nothing can be concluded about it.
    if (node.target is ThisExpression) _record(node.propertyName);
    super.visitPropertyAccess(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

/// Reports assignments whose right-hand side reuses a value read before the
/// await.
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

    // On the left of an assignment a `SimpleIdentifier` resolves through
    // `writeElement`, not `element` — the latter is null for a compound
    // assignment such as `_value += 1`. Fall back to it so both forms resolve.
    final element = node.writeElement ?? target.element;
    if (element == null) return;
    if (!_isTrackable(element, includeLocals: includeLocals)) return;
    if (!_matchesStale(element)) return;

    // A plain `=` whose right-hand side ignores the stale value overwrites the
    // field outright, so no update can be lost. A compound assignment (`+=`)
    // always reads the field first, so it always depends on it.
    if (node.operator.lexeme == '=' &&
        !_dependsOnStaleValue(node.rightHandSide)) {
      return;
    }

    rule.reportAtNode(node, arguments: [target.name]);
  }

  /// Whether [element] names storage recorded as read before the await.
  ///
  /// Compared through [_canonicalElement] because the same field reaches this
  /// rule as different elements depending on position: a read resolves to the
  /// getter (or the field), while a write resolves to the setter.
  bool _matchesStale(Element element) {
    final canonical = _canonicalElement(element);

    return readBeforeAwait.keys.any(
      (stale) => _canonicalElement(stale) == canonical,
    );
  }

  /// Whether [expression] reads any value that was captured before the await.
  bool _dependsOnStaleValue(Expression expression) {
    final finder = _StaleReadFinder(readBeforeAwait.keys.toSet());
    expression.accept(finder);

    return finder.found;
  }

  /// The identifier being assigned to, for `field`, `this.field` forms.
  SimpleIdentifier? _targetIdentifier(Expression leftHandSide) =>
      switch (leftHandSide) {
        SimpleIdentifier() => leftHandSide,
        PropertyAccess(target: ThisExpression()) => leftHandSide.propertyName,
        _ => null,
      };

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

/// Detects a reference to any element in a given set, stopping at closures.
///
/// A closure is not part of the value being written; it is a callback the
/// write installs, and it runs later, on its own timeline. Descending into one
/// makes the rule read `_timer = Timer(d, () { _timer?.cancel(); })` as a
/// write that depends on the value read before the await, when the callback
/// merely names the same field. That shape — cancel a timer, then reassign it
/// with a callback that touches it — is ordinary and correct, so the whole
/// class of reports was false.
///
/// Every other visitor in this rule already stops at [visitFunctionExpression]
/// for the same reason.
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

/// Maps an element to a single identity shared by every way the same storage
/// can be referenced.
///
/// A field is reachable as a [FieldElement], and as the [GetterElement] /
/// [SetterElement] pair synthesized for it, depending on whether it is read or
/// written. Comparing the raw elements would treat `_value` on the left of an
/// assignment as different storage from `_value` on the right.
Element _canonicalElement(Element element) => switch (element) {
  GetterElement(:final variable) => variable,
  SetterElement(:final variable) => variable,
  _ => element,
};

/// Whether [element] names storage this rule tracks.
///
/// Fields are always tracked. Locals are opt-in: a local is only shared when a
/// closure captures and writes it, so tracking them by default would report
/// ordinary sequential code.
bool _isTrackable(Element element, {required bool includeLocals}) {
  // Canonicalize first so a field reaches the `isStatic` check whichever way
  // it was referenced; a setter-typed write would otherwise skip it and a
  // static field would be reported despite never being per-instance state.
  final canonical = _canonicalElement(element);

  if (canonical is FieldElement) return !canonical.isStatic;
  if (includeLocals && canonical is LocalVariableElement) return true;

  return false;
}

/// Whether [node] contains an `await`, stopping at function boundaries.
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
