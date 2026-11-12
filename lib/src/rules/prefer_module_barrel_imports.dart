import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/analysis/uri_converter.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';

import '../many_lints_rule.dart';
import '../module_boundary.dart';

class PreferModuleBarrelImports extends ManyLintsRule {
  static const code = LintCode(
    'prefer_module_barrel_imports',
    "Import the public entry point '{0}' instead of crossing this module boundary.",
    correctionMessage:
        'Use the entry point after checking its exported symbols.',
  );

  static const ownEntryPointCode = LintCode(
    'prefer_module_barrel_imports',
    "Import the entry point of the module you need instead of this package's own entry point '{0}'.",
    correctionMessage:
        "Code inside 'lib' reaches other modules through their own barrels.",
  );

  PreferModuleBarrelImports()
    : super(
        name: 'prefer_module_barrel_imports',
        description: 'Requires module entry points across module boundaries.',
      );

  LintCode _reportedCode = code;

  @override
  LintCode get diagnosticCode => _reportedCode;

  @override
  List<DiagnosticCode> get diagnosticCodes => const [code, ownEntryPointCode];

  void _report(AstNode node, LintCode reported, String argument) {
    _reportedCode = reported;
    reportAtNode(node, arguments: [argument]);
    _reportedCode = code;
  }

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry
      ..addImportDirective(this, visitor)
      ..addExportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final PreferModuleBarrelImports rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) => _checkDirective(node);

  @override
  void visitExportDirective(ExportDirective node) => _checkDirective(node);

  void _checkDirective(NamespaceDirective node) {
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
    final targetUri = converter.pathToUri(target);
    final targetPackage = targetUri?.scheme == 'package'
        ? targetUri?.pathSegments.first
        : null;
    final ownPackage =
        targetPackage != null &&
        _isPackageAt(converter, targetPackage, root.getFolder('lib'));
    if (targetPackage != null) {
      final entries = [
        for (final entry in rule.config.stringListOption(
          'package_entry_points',
        ))
          if (Uri.tryParse(entry) case final entryUri?
              when entryUri.scheme == 'package' &&
                  entryUri.pathSegments.first == targetPackage)
            (entry, converter.uriToPath(entryUri)),
      ];
      if (entries.isNotEmpty) {
        final isEntry = entries.any((entry) => entry.$2 == target);
        if (!ownPackage || !source.startsWith('lib/')) {
          if (!isEntry) {
            final names = entries.map((entry) => entry.$1).join("' or '");
            rule._report(literal, PreferModuleBarrelImports.code, names);
          }
          return;
        }
        if (isEntry) {
          rule._report(
            literal,
            PreferModuleBarrelImports.ownEntryPointCode,
            entries.firstWhere((entry) => entry.$2 == target).$1,
          );
          return;
        }
      }
      if (!ownPackage) return;
    }
    final relative = ModuleBoundary.relativeTo(root, target);
    if (relative == null) return;
    final boundary = ModuleBoundary.forPath(relative, rule.config);
    if (boundary == null) return;
    final owner = ModuleBoundary.forPath(source, rule.config);
    if (owner?.directory == boundary.directory ||
        relative == boundary.entryPoint) {
      return;
    }
    rule._report(literal, PreferModuleBarrelImports.code, boundary.entryPoint);
  }

  bool _isPackageAt(UriConverter converter, String name, Folder lib) {
    final path = converter.uriToPath(Uri.parse('package:$name/'));
    return path != null && lib.provider.pathContext.equals(path, lib.path);
  }
}
