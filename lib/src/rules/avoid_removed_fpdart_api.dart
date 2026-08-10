import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Names removed in fpdart 1.0.0, mapped to what replaced them.
///
/// Everything here comes from the 1.0.0 changelog. The value is the
/// replacement, or an empty string when the answer is "use plain Dart".
const _removedApi = {
  'Tuple2': 'a Dart record, (a, b)',
  'Tuple3': 'a Dart record, (a, b, c)',
  'Predicate': 'the function extensions (negate, and, or, contramap)',
  'idFuture': 'identity',
  'concatMap': 'flatMap',
  'bindWithIndex': 'flatMapWithIndex',
  'plus': 'concat',
};

/// Warns when code uses an fpdart name that was removed in 1.0.0.
///
/// These do not compile against a 1.x fpdart, so the rule is aimed squarely at
/// migration: a codebase moving off 0.x, or a snippet copied from one of the
/// many pre-2023 tutorials that still rank well. Reading "undefined name
/// `Tuple2`" tells you something is wrong; reading "use a Dart record" tells
/// you what to do.
///
/// It is also a guard for the reverse trap. `bind` and `concat` still exist in
/// 1.x but mean *different things* than they did in 0.x, so copied code can
/// compile and quietly do the wrong thing. Those are not reported by default —
/// a rule that fires on a valid, current API is worse than the confusion it
/// prevents — but a project mid-migration can add them.
///
/// **Bad:**
/// ```dart
/// final pair = Tuple2(1, 'a');
/// ```
///
/// **Good:**
/// ```dart
/// final pair = (1, 'a');
/// ```
///
/// ## Options
///
/// - `additional_removed`: extra names to report, for a project mid-migration
///   that wants `bind`/`concat` flagged too.
class AvoidRemovedFpdartApi extends ManyLintsRule {
  static const LintCode code = LintCode(
    "avoid_removed_fpdart_api",
    "'{0}' was removed in fpdart 1.0.0.",
    correctionMessage: 'Use {1} instead.',
  );

  AvoidRemovedFpdartApi()
    : super(
        name: 'avoid_removed_fpdart_api',
        description:
            'Warns when code uses an fpdart name that was removed in 1.0.0, '
            'such as Tuple2 or the Predicate class.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidRemovedFpdartApi rule;

  _Visitor(this.rule);

  /// Gate the whole file on an fpdart import.
  ///
  /// A removed name resolves to nothing, so without this gate the rule would
  /// fire on any unresolved identifier that happens to share a name — a
  /// project with its own `Tuple2`, or a plain typo in a file that has never
  /// heard of fpdart. Every other rule in this family gates on a resolved
  /// fpdart *type*; this one cannot, precisely because its subject no longer
  /// exists, so the import is the closest available signal.
  @override
  void visitCompilationUnit(CompilationUnit node) {
    final importsFpdart = node.directives.any(
      (directive) =>
          directive is ImportDirective &&
          (directive.uri.stringValue?.startsWith('package:fpdart/') ?? false),
    );
    if (!importsFpdart) return;

    node.accept(_IdentifierVisitor(rule));
  }
}

class _IdentifierVisitor extends RecursiveAstVisitor<void> {
  final AvoidRemovedFpdartApi rule;

  _IdentifierVisitor(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final name = node.name;

    final replacement = _removedApi[name];
    final isConfigured = rule.config
        .stringListOption('additional_removed')
        .contains(name);

    if (replacement == null && !isConfigured) return;

    // A removed name cannot resolve to anything in fpdart 1.x, so anything
    // that *does* resolve is the project's own declaration and none of this
    // rule's business. A configured name is exempt from this test: a project
    // adds one precisely because it still resolves, to a 1.x API that changed
    // meaning.
    if (!isConfigured && node.element != null) return;

    // Skip a declaration's own name — a project declaring its own `Tuple2` is
    // not using fpdart's.
    //
    // Testing `parent is Declaration` is not enough: the initializer of
    // `final p = Predicate;` also hangs off a `VariableDeclaration`, so that
    // test would swallow the very usage this rule exists to find. Only the
    // node that *is* the declared name counts.
    // Both spellings carry the declared name as a `Token`, so identity is
    // checked against the identifier's own token rather than the node.
    final parent = node.parent;
    if (parent is VariableDeclaration && parent.name == node.token) return;
    if (parent is NamedType && parent.name == node.token) return;

    rule.reportAtNode(
      node,
      arguments: [name, replacement ?? 'the 1.x replacement'],
    );
  }
}
