import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../file_name_utils.dart';
import '../many_lints_rule.dart';

/// Warns when a file's name does not match the first public declaration in it.
///
/// `user_repository.dart` declaring `class UserRepository` is the convention
/// the SDK's own `file_names` rule assumes but never checks: that rule only
/// validates the *spelling* of the name, not whether it describes the contents.
/// Matching them is what lets a reader find a type from a directory listing,
/// and what makes a rename of the type show up as a rename of the file.
///
/// Only the **first** public declaration is checked. A file legitimately holds
/// several declarations — a class plus its extension, a sealed hierarchy — and
/// only one of them can name the file, so the rest are not evidence of a
/// problem. That also means this rule stays useful beside
/// `prefer_single_declaration_per_file` rather than duplicating it.
///
/// A file with no public declaration is skipped: a private-only file has no
/// name to match, and a barrel of `export` directives declares nothing at all.
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
  /// Names a framework demands of a file, which therefore cannot name it.
  ///
  /// `main` is the language's own; `onRequest` and `middleware` are dart_frog's
  /// route contract, where the file's *path* is the API.
  static const _defaultEntrypoints = {'main', 'onRequest', 'middleware'};

  final PreferMatchFileName rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = rule.relativePath;
    if (path == null) return;

    // A part file's name belongs to the composite widget or class it is part
    // of (`_header.dart` inside `profile_page/`), so it is deliberately not
    // held to its own declaration's name.
    if (node.directives.any((d) => d is PartOfDirective)) return;

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
        // An extension carries a name only when it is not anonymous; an
        // anonymous one cannot name a file, so it is skipped rather than
        // reported.
        ExtensionDeclaration() => declaration.name,
        FunctionDeclaration() => declaration.name,
        TypeAlias() => declaration.name,
        _ => null,
      };

      if (name == null) continue;
      if (name.lexeme.startsWith('_')) continue;
      // An entrypoint is not the file's subject: it is a name the language or
      // a framework demands, so it can never name the file. `main` is the
      // language's (every test file has one); `onRequest` and `middleware` are
      // dart_frog's, where the route's *path* is the API. On a real codebase
      // these were 183 of 206 reports, all wrong.
      if (declaration is FunctionDeclaration &&
          entrypoints.contains(name.lexeme)) {
        continue;
      }

      return name;
    }

    return null;
  }
}
