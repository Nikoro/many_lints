import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class PreferCorrectErrorName extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_correct_error_name',
    "'{0}' is {1} but does not end with '{2}'.",
    correctionMessage:
        "Rename it to end with '{2}', so the call site can tell whether it is "
        'meant to be caught.',
  );

  PreferCorrectErrorName()
    : super(
        name: 'prefer_correct_error_name',
        description:
            'Warns when an exception or error class is not named with the '
            'matching suffix.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferCorrectErrorName rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    final name = node.namePart.typeName;
    final kind = _kindOf(element);
    if (kind == null) return;

    final suffix = switch (kind) {
      _ErrorKind.exception => rule.config.stringOption(
        'exception_suffix',
        defaultValue: 'Exception',
      ),
      _ErrorKind.error => rule.config.stringOption(
        'error_suffix',
        defaultValue: 'Error',
      ),
    };

    final allowed = [suffix, ...rule.config.stringListOption('allow_suffixes')];
    if (allowed.any(name.lexeme.endsWith)) return;

    rule.reportAtToken(
      name,
      arguments: [name.lexeme, kind.description, suffix],
    );
  }

  _ErrorKind? _kindOf(InterfaceElement element) {
    for (final type in element.allSupertypes) {
      final name = type.element.name;
      if (name == 'Error') return _ErrorKind.error;
    }

    for (final type in element.allSupertypes) {
      final name = type.element.name;
      if (name == 'Exception') return _ErrorKind.exception;
    }

    return null;
  }
}

enum _ErrorKind {
  exception('an exception'),
  error('an error');

  const _ErrorKind(this.description);

  final String description;
}
