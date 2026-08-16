import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a file imports more libraries than the configured budget.
///
/// The import list is the cheapest available measure of how much a file
/// depends on: a file reaching for twenty libraries is coupled to twenty
/// things that can change under it, and it is usually one that has taken on
/// several jobs.
///
/// The limit is `max_imports`, defaulting to 15. `export` directives are not
/// counted — a barrel file is exports by definition, and counting them would
/// report every barrel in the project — unless `count_exports: true`.
class MaxImports extends ManyLintsRule {
  static const LintCode code = LintCode(
    'max_imports',
    'This file has {0} imports, over the limit of {1}.',
    correctionMessage:
        'Split out the part with its own dependencies, or raise max_imports.',
  );

  MaxImports()
    : super(
        name: 'max_imports',
        description:
            'Warns when a file imports more libraries than the configured '
            'budget.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

/// Enough for a normal file; a file past it usually has several jobs.
const _defaultMaxImports = 15;

class _Visitor extends SimpleAstVisitor<void> {
  final MaxImports rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final maxImports = rule.config.intOption(
      'max_imports',
      defaultValue: _defaultMaxImports,
    );
    final countExports = rule.config.boolOption(
      'count_exports',
      defaultValue: false,
    );

    final directives = node.directives.where(
      (directive) =>
          directive is ImportDirective ||
          countExports && directive is ExportDirective,
    );

    final count = directives.length;
    if (count <= maxImports) return;

    // Reported at the first directive rather than the whole unit, so the
    // diagnostic lands on the import block it is about.
    rule.reportAtNode(directives.first, arguments: ['$count', '$maxImports']);
  }
}
