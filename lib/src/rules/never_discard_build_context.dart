import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_type_checkers.dart';
import '../many_lints_rule.dart';

/// Warns when a `BuildContext` parameter is discarded by naming it `_`.
///
/// Discarding the context does not remove the need for one — it removes the
/// *closest* one. The body then reaches for a `context` from an enclosing
/// scope, and that context sits higher in the tree, so `Theme.of`,
/// `MediaQuery.of` and `Navigator.of` resolve against the wrong element. The
/// result is a value from the wrong subtree, or a lookup that throws once the
/// outer element is deactivated.
///
/// This is easy to introduce with a builder whose context is not needed *yet*,
/// and hard to spot later: the code compiles and usually appears to work.
///
/// **Bad:**
/// ```dart
/// Builder(builder: (_) => Text(Theme.of(context).toString()));
/// ```
///
/// **Good:**
/// ```dart
/// Builder(builder: (context) => Text(Theme.of(context).toString()));
/// ```
class NeverDiscardBuildContext extends ManyLintsRule {
  static const LintCode code = LintCode(
    'never_discard_build_context',
    "A 'BuildContext' parameter is discarded.",
    correctionMessage:
        "Name the parameter 'context' and use it, so lookups resolve against "
        'the closest element rather than an ancestor.',
  );

  NeverDiscardBuildContext()
    : super(
        name: 'never_discard_build_context',
        description:
            'Warns when a BuildContext parameter is named with a wildcard, '
            'which pushes lookups onto an outer context.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addRegularFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final NeverDiscardBuildContext rule;

  _Visitor(this.rule);

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    final name = node.name;
    if (name == null) return;

    // Only a pure wildcard discards the parameter. `_context` is a private
    // name, not a discard, and remains usable.
    if (!_isWildcard(name.lexeme)) return;

    final element = node.declaredFragment?.element;
    if (element == null) return;
    if (!buildContextChecker.isExactlyType(element.type)) return;

    rule.reportAtToken(name);
  }

  /// Whether [lexeme] is made up only of underscores (`_`, `__`, ...), the
  /// spellings Dart treats as a discard.
  static bool _isWildcard(String lexeme) =>
      lexeme.isNotEmpty && lexeme.split('').every((c) => c == '_');
}
