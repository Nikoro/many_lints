import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';
import '../module_boundary.dart';

class PreferModuleBarrelImports extends ManyLintsRule {
  static const code = LintCode(
    'prefer_module_barrel_imports',
    "Import the public entry point '{0}' instead of crossing this module boundary.",
    correctionMessage:
        'Use the entry point after checking its exported symbols.',
  );

  PreferModuleBarrelImports()
    : super(
        name: 'prefer_module_barrel_imports',
        description: 'Requires module entry points across module boundaries.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addImportDirective(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final PreferModuleBarrelImports rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) {
    final source = rule.relativePath;
    if (source == null || ModuleBoundary.isGenerated(source)) return;
    _check(node.uri, source);
    for (final configuration in node.configurations) {
      _check(configuration.uri, source);
    }
  }

  void _check(StringLiteral literal, String source) {
    final root = context.package?.root;
    final library = context.libraryElement;
    final value = literal.stringValue;
    if (root == null || library == null || value == null) return;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme == 'dart') return;
    final converter = library.session.uriConverter;
    final sourceUri = root.getFile(source).toUri();
    final target = converter.uriToPath(sourceUri.resolveUri(uri));
    if (target == null || !root.provider.getFile(target).exists) return;
    final relative = ModuleBoundary.relativeTo(root, target);
    final entries = rule.config.stringListOption('package_entry_points');
    for (final entry in entries) {
      final entryUri = Uri.tryParse(entry);
      if (entryUri == null || entryUri.scheme != 'package') continue;
      final entryPath = converter.uriToPath(entryUri);
      if (entryPath == null) continue;
      final packageLib = converter.uriToPath(
        Uri.parse('package:${entryUri.pathSegments.first}/'),
      );
      if (packageLib == null ||
          !root.provider.pathContext.isWithin(packageLib, target)) {
        continue;
      }
      if (relative == null || !source.startsWith('lib/')) {
        if (target != entryPath) rule.reportAtNode(literal, arguments: [entry]);
        return;
      }
      if (target == entryPath) {
        rule.reportAtNode(literal, arguments: ['the owning module barrel']);
        return;
      }
    }
    if (relative == null) return;
    final boundary = ModuleBoundary.forPath(relative, rule.config);
    if (boundary == null) return;
    final owner = ModuleBoundary.forPath(source, rule.config);
    if (owner?.directory == boundary.directory ||
        relative == boundary.entryPoint) {
      return;
    }
    rule.reportAtNode(literal, arguments: [boundary.entryPoint]);
  }
}
