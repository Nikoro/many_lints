import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';

/// The `tryParse` receivers fpdart ships an extension for, mapped to the
/// getter that replaces the whole expression.
const _parseGetters = {
  'int': 'toIntOption',
  'double': 'toDoubleOption',
  'num': 'toNumOption',
  'bool': 'toBoolOption',
};

/// Warns when `Option.fromNullable(int.tryParse(s))` is written by hand.
///
/// fpdart defines `'42'.toIntOption` as exactly that expression, plus
/// `toDoubleOption`, `toNumOption`, `toBoolOption` and the `...Either`
/// variants that take a failure. Writing the composition out puts the parse
/// and its null handling at opposite ends of the line, which is where the
/// mismatch hides: `Option.fromNullable(int.tryParse(a))` inside a pipeline
/// that meant to parse `b` reads as correct.
///
/// **Bad:**
/// ```dart
/// final parsed = Option.fromNullable(int.tryParse(input));
/// ```
///
/// **Good:**
/// ```dart
/// final parsed = input.toIntOption;
/// ```
///
/// ## Options
///
/// - `additional_parsers`: extra `Type.tryParse` receivers to recognise, for
///   projects that define their own `toXOption` extension alongside fpdart's.
class PreferStringParseExtensions extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_string_parse_extensions',
    "Use '{0}' instead of wrapping '{1}.tryParse'.",
    correctionMessage:
        'The extension is defined as exactly this expression, and keeps the '
        'parse and its null handling together.',
  );

  PreferStringParseExtensions()
    : super(
        name: 'prefer_string_parse_extensions',
        description:
            "Warns when Option.fromNullable wraps a tryParse call that "
            "fpdart's string extensions already express.",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferStringParseExtensions rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    if (constructorName.name?.name != 'fromNullable') return;

    final element = constructorName.element;
    if (element == null) return;
    if (!optionChecker.isExactly(element.enclosingElement)) return;

    final arguments = node.argumentList.arguments;
    if (arguments.length != 1) return;

    final argument = arguments.first;
    if (argument is! Expression) return;

    final parsed = _parseCall(argument.unParenthesized);
    if (parsed == null) return;

    rule.reportAtNode(node, arguments: [parsed.getter, parsed.receiver]);
  }

  /// The `Type.tryParse(...)` shape of [expression], or null when it is
  /// something else.
  ({String receiver, String getter})? _parseCall(Expression expression) {
    if (expression is! MethodInvocation) return null;
    if (expression.methodName.name != 'tryParse') return null;

    // A second argument (`radix:`) changes what the call does, and no
    // extension covers it.
    if (expression.argumentList.arguments.length != 1) return null;

    final target = expression.realTarget;
    if (target is! Identifier) return null;

    final receiver = target.name;
    final getters = {
      ..._parseGetters,
      for (final extra in rule.config.stringListOption('additional_parsers'))
        extra: 'to${extra[0].toUpperCase()}${extra.substring(1)}Option',
    };

    final getter = getters[receiver];
    if (getter == null) return null;

    return (receiver: receiver, getter: getter);
  }
}
