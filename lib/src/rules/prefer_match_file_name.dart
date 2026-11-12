import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../file_name_utils.dart';
import '../many_lints_rule.dart';

class PreferMatchFileName extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_match_file_name',
    "The file name does not match '{0}'.",
    correctionMessage: "Rename the file to '{1}.dart'.",
  );

  PreferMatchFileName()
    : super(
        name: 'prefer_match_file_name',
        description:
            'Warns when a file name does not match the first public '
            'declaration in it.',
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

class _Visitor extends SimpleAstVisitor<void> {
  static const _defaultEntrypoints = {'main', 'onRequest', 'middleware'};

  final PreferMatchFileName rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = rule.relativePath;
    if (path == null) return;

    final isPartFile = node.directives.any((d) => d is PartOfDirective);
    if (isPartFile) return;

    final ignoredSuffixes = rule.config.stringListOption('ignored_suffixes');
    if (hasIgnoredSuffix(path, ignoredSuffixes)) return;

    final entrypoints = rule.config.nameSetOption(
      'entrypoints',
      defaultValue: _defaultEntrypoints,
    );

    final token = _firstPublicDeclarationName(node, entrypoints);
    if (token == null) return;

    final expected = toSnakeCase(token.lexeme);
    if (fileBaseName(path) == expected) return;

    rule.reportAtToken(token, arguments: [token.lexeme, expected]);
  }

  Token? _firstPublicDeclarationName(
    CompilationUnit node,
    Set<String> entrypoints,
  ) {
    for (final declaration in node.declarations) {
      final name = switch (declaration) {
        ClassDeclaration() => declaration.namePart.typeName,
        EnumDeclaration() => declaration.namePart.typeName,
        ExtensionTypeDeclaration() => declaration.namePart.typeName,
        MixinDeclaration() => declaration.name,
        ExtensionDeclaration() => declaration.name,
        FunctionDeclaration() => declaration.name,
        TypeAlias() => declaration.name,
        _ => null,
      };

      if (name == null) continue;
      if (name.lexeme.startsWith('_')) continue;
      final isEntrypoint =
          declaration is FunctionDeclaration &&
          entrypoints.contains(name.lexeme);
      if (isEntrypoint) continue;

      return name;
    }

    return null;
  }
}
