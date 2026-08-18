import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';

import '../many_lints_rule.dart';

/// Warns when a library under `lib/` has no matching test file.
///
/// ```
/// lib/src/core/version.dart   ->   test/src/core/version_test.dart
/// lib/parser.dart             ->   test/parser_test.dart
/// ```
///
/// ## What this proves, and what it does not
///
/// It cannot show a test was written first — that needs git history, and is
/// gameable. It cannot show the test exercises anything — that is coverage's
/// job, and coverage has its own gaming problem. What it shows is that no
/// production file shipped without somebody creating a place for its tests,
/// which is the load-bearing half in practice: the common failure is not a
/// weak test but no test at all.
///
/// The message says a test file is missing, not that the code is untested.
/// The rule cannot tell the difference and should not imply it can.
///
/// ## What it skips without being asked
///
/// - Generated files (`.g.dart`, `.freezed.dart`, anything under `generated/`).
/// - Barrel files, detected from the AST rather than the filename — a barrel
///   is not always named after its directory.
/// - Files declaring nothing public. A file of private helpers has no surface
///   a test could target, and demanding one produces empty test files, which
///   is worse than no rule.
///
/// `fallback_anywhere`, on by default, accepts a file of the right name
/// anywhere under the test directory. It matters more than it looks: projects
/// reorganise test trees, and a rule that fails because a test moved teaches
/// people to switch the rule off.
///
/// This rule is in no preset. Whether a project mirrors its test tree is a
/// project decision, and a rule this structural should be opted into by name.
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

  /// The package root of the library being analyzed, for the visitor's
  /// filesystem lookups.
  ///
  /// [ManyLintsRule] captures the root privately for configuration; this rule
  /// is the one case that needs it to answer the question it asks, since the
  /// evidence lives in a *different* file.
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
  /// Suffixes whose files are written by a builder, not a person.
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

    // Only library code is mirrored. A test has no test of its own, and
    // anything outside `lib/` is not the package's published surface.
    if (!path.startsWith('lib/')) return;
    if (_isGenerated(path)) return;

    // A part file's declarations belong to its library, which is checked on
    // its own defining unit.
    if (node.directives.any((d) => d is PartOfDirective)) return;

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

    // Reporting at the first token keeps the diagnostic at the top of the
    // file: the finding is about the file as a whole, and no single
    // declaration inside it is more responsible than any other.
    rule.reportAtToken(node.beginToken, arguments: [expected]);
  }

  /// The mirrored test path for a `lib/`-relative [path].
  String _expectedPath(
    String path, {
    required String testDir,
    required String suffix,
  }) {
    final withoutLib = path.substring('lib/'.length);
    final base = withoutLib.substring(0, withoutLib.length - '.dart'.length);

    return '$testDir/$base$suffix.dart';
  }

  bool _isGenerated(String path) =>
      _generatedSuffixes.any(path.endsWith) || path.contains('/generated/');

  /// Whether every meaningful declaration in [node] is an export.
  ///
  /// Read from the AST rather than the filename, because a barrel is not
  /// always named after its directory. A file with exports *and* declarations
  /// is not a barrel — it has code of its own to test.
  bool _isBarrel(CompilationUnit node) {
    if (!node.directives.any((d) => d is ExportDirective)) return false;

    return node.declarations.isEmpty;
  }

  /// Whether [node] declares anything a test could reach.
  ///
  /// This is the exclusion that makes the rule usable: without it, a file of
  /// private helpers for its library demands a test file that can only be
  /// written empty.
  bool _declaresPublicElement(CompilationUnit node) =>
      node.declarations.any(_isPublicDeclaration);

  /// Whether [member] declares a public name.
  ///
  /// The subtypes are matched individually because analyzer 14 removed
  /// `NamedCompilationUnitMember`: each declaration now carries its own `name`
  /// token with no shared supertype to read it from.
  bool _isPublicDeclaration(CompilationUnitMember member) => switch (member) {
    // Class-like declarations name themselves through `namePart`, the others
    // through a plain `name` token. There is no shared supertype carrying
    // either, so both shapes are matched explicitly.
    ClassDeclaration(:final namePart) ||
    EnumDeclaration(:final namePart) ||
    ExtensionTypeDeclaration(
      :final namePart,
    ) => !namePart.typeName.lexeme.startsWith('_'),
    FunctionDeclaration(:final name) ||
    MixinDeclaration(:final name) ||
    TypeAlias(:final name) => !name.lexeme.startsWith('_'),
    // An unnamed extension is reachable by anyone importing the library, so
    // it counts as public surface even though it has no name of its own.
    ExtensionDeclaration(:final name) =>
      name == null || !name.lexeme.startsWith('_'),
    TopLevelVariableDeclaration(:final variables) => variables.variables.any(
      (v) => !v.name.lexeme.startsWith('_'),
    ),
    _ => false,
  };

  /// Whether a file named [fileName] exists anywhere under [testDir].
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
