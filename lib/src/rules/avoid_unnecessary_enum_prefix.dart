import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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
      if (!_isPrefixedWord(name, prefix)) continue;

      rule.reportAtToken(constant.name, arguments: [name, enumName]);
    }
  }

  bool _isPrefixedWord(String name, String prefix) {
    if (name.length <= prefix.length || !name.startsWith(prefix)) return false;
    final firstLetterAfterPrefix = name[prefix.length];
    return firstLetterAfterPrefix == firstLetterAfterPrefix.toUpperCase();
  }

  String _lowerFirst(String value) =>
      value.isEmpty ? value : value[0].toLowerCase() + value.substring(1);
}
