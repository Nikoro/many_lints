import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when an enum constant repeats the enum's own name.
///
/// `enum Status { statusActive }` reads as `Status.statusActive` at every call
/// site, where the type already says `Status`. The prefix is a habit carried
/// over from languages whose enum constants share one namespace; Dart scopes
/// them to the enum, so it buys nothing and lengthens every use.
class AvoidUnnecessaryEnumPrefix extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_enum_prefix',
    "The constant '{0}' repeats the enum name '{1}'.",
    correctionMessage:
        'Drop the prefix; the enum name is already part of every use.',
  );

  AvoidUnnecessaryEnumPrefix()
    : super(
        name: 'avoid_unnecessary_enum_prefix',
        description:
            "Warns when an enum constant is prefixed with its own enum's "
            'name, which every call site already carries.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addEnumDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryEnumPrefix rule;

  _Visitor(this.rule);

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    final enumName = node.namePart.typeName.lexeme;
    final prefix = _lowerFirst(enumName);

    for (final constant in node.body.constants) {
      final name = constant.name.lexeme;

      // The constant must start with the enum name *and* carry something
      // after it: a constant named exactly `status` is not a prefixed name,
      // it is the whole word.
      if (name.length <= prefix.length) continue;
      if (!name.startsWith(prefix)) continue;

      // The character after the prefix must begin a new word, or `statusable`
      // would count as prefixed by `status`.
      final next = name[prefix.length];
      if (next != next.toUpperCase()) continue;

      rule.reportAtToken(constant.name, arguments: [name, enumName]);
    }
  }

  String _lowerFirst(String value) =>
      value.isEmpty ? value : value[0].toLowerCase() + value.substring(1);
}
