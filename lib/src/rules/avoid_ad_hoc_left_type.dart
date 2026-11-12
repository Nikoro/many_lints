import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../fpdart_type_checkers.dart';
import '../many_lints_rule.dart';
import '../type_checker.dart';

class AvoidAdHocLeftType extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_ad_hoc_left_type',
    "'{0}' is not one of this project's failure types.",
    correctionMessage:
        "Use {1} in the error channel, so every step of a pipeline composes "
        'without bridging.',
  );

  AvoidAdHocLeftType()
    : super(
        name: 'avoid_ad_hoc_left_type',
        description:
            'Warns when an fpdart error channel carries a type outside the '
            'project-configured failure hierarchy. Reports nothing until '
            'error_types is set.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addNamedType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidAdHocLeftType rule;

  _Visitor(this.rule);

  @override
  void visitNamedType(NamedType node) {
    final allowed = rule.config.stringListOption('error_types');
    if (allowed.isEmpty) return;

    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.length != 2) return;

    final type = node.type;
    if (type == null) return;
    if (!failableFpdartChecker.isAssignableFromType(type)) return;

    final errorType = typeArguments.first;
    final resolved = errorType.type;
    if (resolved == null) return;

    if (_isAllowed(resolved, allowed)) return;

    rule.reportAtNode(
      errorType,
      arguments: [
        resolved.getDisplayString(),
        allowed.length == 1 ? "'${allowed.single}'" : _joinNames(allowed),
      ],
    );
  }

  bool _isAllowed(DartType type, List<String> allowed) {
    final allowSubtypes = rule.config.boolOption(
      'allow_subtypes',
      defaultValue: true,
    );

    for (final name in allowed) {
      // Edge case: no package pin, since a project's own failure types have no package: URI to match
      final checker = TypeChecker.fromName(name);
      if (allowSubtypes) {
        if (checker.isAssignableFromType(type)) return true;
      } else if (checker.isExactlyType(type)) {
        return true;
      }
    }

    return false;
  }

  String _joinNames(List<String> names) =>
      names.map((name) => "'$name'").join(' or ');
}
