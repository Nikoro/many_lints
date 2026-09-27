import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../module_boundary.dart';

class RequireModuleBarrel extends ManyLintsRule {
  static const code = LintCode(
    'require_module_barrel',
    "The module is missing its public entry point '{0}'.",
    correctionMessage: 'Create a barrel exporting the module public API.',
  );

  RequireModuleBarrel()
    : super(
        name: 'require_module_barrel',
        description: 'Requires an entry point for each source module.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final RequireModuleBarrel rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = rule.relativePath;
    final root = context.package?.root;
    if (path == null || root == null || ModuleBoundary.isGenerated(path)) {
      return;
    }
    if (node.directives.any((directive) => directive is PartOfDirective)) {
      return;
    }
    final boundary = ModuleBoundary.forPath(path, rule.config);
    if (boundary == null || root.getFile(boundary.entryPoint).exists) return;
    rule.reportAtToken(node.beginToken, arguments: [boundary.entryPoint]);
  }
}
