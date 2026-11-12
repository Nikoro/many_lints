import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';

import '../many_lints_rule.dart';

class RequireMirrorTest extends ManyLintsRule {
  static const LintCode code = LintCode(
    'require_mirror_test',
    "No test file found for this library; expected '{0}'.",
    correctionMessage:
        'Create the test file. This reports a missing file, not untested '
        'code.',
  );

  RequireMirrorTest()
    : super(
        name: 'require_mirror_test',
        description: 'Warns when a library under `lib/` has no test file.',
      );

  @override
  LintCode get diagnosticCode => code;

  Folder? packageRoot;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    packageRoot = context.package?.root;
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const _generatedSuffixes = [
    '.g.dart',
    '.freezed.dart',
    '.gr.dart',
    '.gen.dart',
    '.config.dart',
    '.mocks.dart',
    '.pb.dart',
  ];

  final RequireMirrorTest rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = rule.relativePath;
    final root = rule.packageRoot;
    if (path == null || root == null) return;

    if (!path.startsWith('lib/')) return;
    if (_isGenerated(path)) return;

    if (_isPartFile(node)) return;

    if (_isBarrel(node)) return;
    if (!_declaresPublicElement(node)) return;

    final testDir = rule.config.stringOption('test_dir', defaultValue: 'test');
    final suffix = rule.config.stringOption('suffix', defaultValue: '_test');

    final expected = _expectedPath(path, testDir: testDir, suffix: suffix);
    if (root.getFile(expected).exists) return;

    final fallbackAnywhere = rule.config.boolOption(
      'fallback_anywhere',
      defaultValue: true,
    );
    if (fallbackAnywhere &&
        _existsAnywhere(root, testDir, expected.split('/').last)) {
      return;
    }

    rule.reportAtToken(node.beginToken, arguments: [expected]);
  }

  String _expectedPath(
    String path, {
    required String testDir,
    required String suffix,
  }) {
    final withoutLib = path.substring('lib/'.length);
    final base = withoutLib.substring(0, withoutLib.length - '.dart'.length);

    return '$testDir/$base$suffix.dart';
  }

  bool _isPartFile(CompilationUnit node) =>
      node.directives.any((d) => d is PartOfDirective);

  bool _isGenerated(String path) =>
      _generatedSuffixes.any(path.endsWith) || path.contains('/generated/');

  bool _isBarrel(CompilationUnit node) {
    if (!node.directives.any((d) => d is ExportDirective)) return false;

    return node.declarations.isEmpty;
  }

  bool _declaresPublicElement(CompilationUnit node) =>
      node.declarations.any(_isPublicDeclaration);

  bool _isPublicDeclaration(CompilationUnitMember member) => switch (member) {
    ClassDeclaration(:final namePart) ||
    EnumDeclaration(:final namePart) ||
    ExtensionTypeDeclaration(
      :final namePart,
    ) => !namePart.typeName.lexeme.startsWith('_'),
    FunctionDeclaration(:final name) ||
    MixinDeclaration(:final name) ||
    TypeAlias(:final name) => !name.lexeme.startsWith('_'),
    // Edge case: an unnamed extension still applies in every importing library
    ExtensionDeclaration(:final name) =>
      name == null || !name.lexeme.startsWith('_'),
    TopLevelVariableDeclaration(:final variables) => variables.variables.any(
      (v) => !v.name.lexeme.startsWith('_'),
    ),
    _ => false,
  };

  bool _existsAnywhere(Folder root, String testDir, String fileName) {
    final start = root.getFolder(testDir);
    if (!start.exists) return false;

    return _search(start, fileName);
  }

  bool _search(Folder folder, String fileName) {
    final List<Resource> children;
    try {
      children = folder.getChildren();
    } on FileSystemException {
      return false;
    }

    for (final child in children) {
      if (child is File) {
        if (child.shortName == fileName) return true;
      } else if (child is Folder) {
        if (_search(child, fileName)) return true;
      }
    }

    return false;
  }
}
