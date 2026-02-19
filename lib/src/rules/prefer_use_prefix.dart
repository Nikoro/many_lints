import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:many_lints/src/hook_detection.dart';

/// Warns when a function that calls hooks does not follow the `use` prefix
/// naming convention.
///
/// Custom hooks must start with `use` (or `_use` for private functions) so
/// that the hooks framework and other lint rules can identify them as hooks.
class PreferUsePrefix extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_use_prefix',
    "Custom hooks should start with 'use' prefix.",
    correctionMessage:
        "Rename the function to start with 'use' (or '_use' "
        'for private functions).',
  );

  PreferUsePrefix()
    : super(
        name: 'prefer_use_prefix',
        description:
            'Warns when a function that calls hooks does not '
            "follow the 'use' prefix naming convention.",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferUsePrefix rule;

  _Visitor(this.rule);

  static final _hasUsePrefix = RegExp('^_?use[0-9A-Z]');

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _check(node.name.lexeme, node.name, node.functionExpression.body);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Skip overridden methods (e.g., build in HookWidget)
    if (node.metadata.any((a) => a.name.name == 'override')) return;

    _check(node.name.lexeme, node.name, node.body);
  }

  void _check(String name, Token nameToken, FunctionBody body) {
    // Already has the use prefix — nothing to report
    if (_hasUsePrefix.hasMatch(name)) return;

    // Check if the function body contains hook calls
    final hookCalls = getAllInnerHookExpressions(body);
    if (hookCalls.isEmpty) return;

    rule.reportAtToken(nameToken);
  }
}
