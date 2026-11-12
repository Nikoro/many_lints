import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferCorrectHandlerName extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_correct_handler_name',
    "The handler '{0}' should be named {1}.",
    correctionMessage:
        'Name a handler after the event it answers, so the call site reads as '
        'a pairing.',
  );

  PreferCorrectHandlerName()
    : super(
        name: 'prefer_correct_handler_name',
        description:
            'Warns when a method used as an event handler is not named with '
            'an on/handle prefix.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addNamedArgument(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferCorrectHandlerName rule;

  _Visitor(this.rule);

  @override
  void visitNamedArgument(NamedArgument node) {
    if (!node.name.lexeme.startsWith('on')) return;

    final expression = node.argumentExpression;
    if (expression is! SimpleIdentifier) return;

    final element = expression.element;
    if (element == null || element is! MethodElement) return;

    final name = expression.name;
    final prefixes = rule.config.nameSetOption(
      'prefixes',
      defaultValue: const {'on', 'handle'},
    );
    final requirePrivate = rule.config.boolOption(
      'require_private',
      defaultValue: true,
    );

    if (_matches(name, prefixes: prefixes, requirePrivate: requirePrivate)) {
      return;
    }

    final expected = prefixes.map((p) => requirePrivate ? '_$p...' : '$p...');

    rule.reportAtNode(expression, arguments: [name, expected.join(' or ')]);
  }

  bool _matches(
    String name, {
    required Set<String> prefixes,
    required bool requirePrivate,
  }) {
    final isPrivate = name.startsWith('_');
    if (requirePrivate && !isPrivate) return false;

    final bare = isPrivate ? name.substring(1) : name;

    // Edge case: `online` must not satisfy the `on` prefix
    return prefixes.any(
      (prefix) =>
          bare.length > prefix.length &&
          bare.startsWith(prefix) &&
          _isUpperCase(bare[prefix.length]),
    );
  }

  bool _isUpperCase(String character) =>
      character.toUpperCase() == character &&
      character.toLowerCase() != character;
}
