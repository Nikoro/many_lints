import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../declaration_group.dart';
import '../many_lints_rule.dart';

class PreferSingleDeclarationPerFile extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_single_declaration_per_file',
    "Only one '{0}' declaration per file.{1}",
    correctionMessage: 'Move this declaration to its own file.',
  );

  PreferSingleDeclarationPerFile()
    : super(
        name: 'prefer_single_declaration_per_file',
        description:
            'Warns when a file contains more than one top-level declaration.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSingleDeclarationPerFile rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // Edge case: config resolves only once the reporter for this file is set.
    final groups = readDeclarationGroups(rule.config);

    final countPerGroup = List.filled(groups.length, 0);

    for (final declaration in node.declarations) {
      final element = declaration.declaredFragment?.element;

      for (var i = 0; i < groups.length; i++) {
        final group = groups[i];
        if (!group.counts(declaration, element)) continue;

        if (countPerGroup[i]++ > 0) {
          final token = declarationNameToken(declaration);
          if (token != null) {
            rule.reportAtToken(
              token,
              arguments: [_label(group), _messageSuffix(group)],
            );
          }
        }
        // Edge case: overlapping groups would report one declaration repeatedly.
        break;
      }
    }
  }

  String _label(DeclarationGroup group) {
    if (group.types.isNotEmpty) return group.types.join("' / '");

    if (group.kinds.length == 1) return group.kinds.first.optionName;

    return 'top-level';
  }

  // Edge case: a per-report LintCode would break the fix registry and severity overrides.
  String _messageSuffix(DeclarationGroup group) {
    final message = group.message;
    return message == null ? '' : ' $message';
  }
}
