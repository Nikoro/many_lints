import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../pattern_entry.dart';

/// Reports code matching a project-supplied pattern, optionally offering the
/// project's own replacement as a quick fix.
///
/// Every project accumulates conventions that no general-purpose lint will
/// ever ship — "use our `Clock` seam, not `DateTime.now()`", "use our trailing
/// `.unawaited()`, not the SDK free function", "use `context.theme`, not
/// `Theme.of(context)`". Today those live in a bash grep in a pre-commit hook,
/// which has no fix, no IDE integration, no `// ignore:` support and no idea
/// where a node begins or ends. This rule gives a one-off convention the same
/// ergonomics as a built-in lint.
///
/// **This rule reports nothing until configured.**
///
/// ```yaml
/// rules:
///   match_pattern:
///     patterns:
///       - find: '^unawaited\((.+)\)$'
///         replace: '$1.unawaited()'
///         message: 'Prefer the trailing form from many_extensions.'
///         in: ['lib/**']
/// ```
///
/// **BAD:**
/// ```dart
/// unawaited(repository.refresh());  // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// repository.refresh().unawaited();
/// ```
///
/// The pattern is matched against the **source text** of one AST node, named
/// by `node:` — `methodInvocation` (the default) or `propertyAccess`. Matching
/// a node rather than a raw line is what bounds the match: a pattern cannot
/// run past the end of the expression it was written for. It also means the
/// match is textual, so a call split across lines will not match a pattern
/// written on one, and nothing here knows types — `unawaited` from any library
/// looks the same.
///
/// `replace:` is optional, and omitting it is how an entry says "report only".
/// A replacement is offered as a fix only when the result parses; see
/// `MatchPatternFix`.
class MatchPattern extends ManyLintsRule {
  static const LintCode code = LintCode(
    'match_pattern',
    "'{0}' matches a pattern this project rewrites.{1}",
    correctionMessage: 'Use the form this project prefers.',
  );

  MatchPattern()
    : super(
        name: 'match_pattern',
        description:
            'Reports code matching a project-supplied pattern, with the '
            "project's own replacement offered as a fix.",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MatchPattern rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) =>
      _check(node, PatternNode.methodInvocation);

  @override
  void visitPropertyAccess(PropertyAccess node) =>
      _check(node, PatternNode.propertyAccess);

  void _check(AstNode node, PatternNode kind) {
    final entries = readPatternEntries(rule.config);
    if (entries.isEmpty) return;

    final source = node.toSource();
    final entry = findPatternEntry(
      entries: entries,
      node: kind,
      source: source,
      relativePath: rule.relativePath,
    );
    if (entry == null) return;

    rule.reportAtNode(node, arguments: [source, patternMessageSuffix(entry)]);
  }
}
