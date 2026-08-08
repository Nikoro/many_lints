import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../banned_entry.dart';
import '../many_lints_rule.dart';

/// Warns when a file re-exports a library banned for its location.
///
/// Barrel files decide a package's public surface, and an accidental
/// `export` there leaks an internal library to every consumer — a breaking
/// change to remove later. Banning specific exports keeps that surface
/// deliberate. Nothing is banned until you configure it.
///
/// Kept separate from [avoid_banned_imports] because importing a library for
/// internal use and re-exporting it to consumers are different decisions: a
/// package is often free to depend on something it must not expose.
///
/// **Configuration** (`many_lints.yaml`):
///
/// ```yaml
/// rules:
///   avoid_banned_exports:
///     banned:
///       - deny_pattern: ['src/internal/.*']
///         in: ['lib/*.dart']
///         message: 'Internal libraries must not be part of the public API.'
/// ```
///
/// **BAD:**
/// ```dart
/// // in lib/my_package.dart
/// export 'src/internal/cache.dart';  // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// // in lib/my_package.dart
/// export 'src/api/client.dart';
/// ```
class AvoidBannedExports extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_banned_exports',
    "The export '{0}' is banned here.{1}",
    correctionMessage:
        'Remove the export to keep this library out of the public API.',
  );

  AvoidBannedExports()
    : super(
        name: 'avoid_banned_exports',
        description:
            'Warns when a file re-exports a library banned for its location.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addExportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidBannedExports rule;

  _Visitor(this.rule);

  @override
  void visitExportDirective(ExportDirective node) {
    final entries = readBannedEntries(rule.config);
    if (entries.isEmpty) return;

    final uri = node.uri.stringValue;
    if (uri == null) return;

    final banned = findBannedEntry(
      entries: entries,
      value: uri,
      relativePath: rule.relativePath,
    );
    if (banned == null) return;

    rule.reportAtNode(node.uri, arguments: [uri, messageSuffix(banned)]);
  }
}
