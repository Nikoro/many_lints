import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a method passed as an event handler is not named `_onSomething`
/// or `_handleSomething`.
///
/// A handler is the other half of the `onTap:`/`onChanged:` convention that
/// [PreferCorrectCallbackFieldName] enforces on the parameter. When the
/// parameter is `onTap:` and the method behind it is `submit`, the call site
/// reads `onTap: submit` and the reader has to hold the mapping themselves;
/// `onTap: _onTap` states it once.
///
/// Only a method *referenced as a callback* is considered — a bare method
/// tear-off passed to a parameter whose type is a function. A method called
/// normally is not a handler and is never reported.
///
/// The accepted prefixes are `on` and `handle` by default, configurable with
/// `prefixes`. `require_private` (default `true`) additionally asks for the
/// leading underscore, since a handler is an implementation detail of the
/// widget that owns it.
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
    // Only a named argument whose own name is `on...` establishes that the
    // value is a handler. Without that anchor the rule would have to guess
    // from the type alone, and every function-typed argument would qualify.
    if (!node.name.lexeme.startsWith('on')) return;

    final expression = node.argumentExpression;
    // A tear-off, not a closure: `onTap: _submit`, not `onTap: () {...}`.
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

    // The character after the prefix must start a new word, or `online` would
    // satisfy the `on` prefix.
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
