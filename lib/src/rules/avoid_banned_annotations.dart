import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../banned_entry.dart';
import '../many_lints_rule.dart';

/// Warns when a banned annotation is used in a file.
///
/// The motivating case is scope: `@visibleForTesting` is reasonable on a
/// helper but wrong in a production directory, and a `@deprecated` API should
/// stop appearing on newly written code. Nothing is banned until you configure
/// it.
///
/// Match on the bare annotation name, without the `@`.
///
/// **Configuration** (`many_lints.yaml`):
///
/// ```yaml
/// rules:
///   avoid_banned_annotations:
///     banned:
///       - deny: ['visibleForTesting']
///         in: ['lib/production/**']
///         message: 'Production code must not widen visibility for tests.'
/// ```
///
/// **BAD:**
/// ```dart
/// // in lib/production/service.dart
/// @visibleForTesting  // LINT
/// void reset() {}
/// ```
///
/// **GOOD:**
/// ```dart
/// // in lib/production/service.dart
/// void reset() {}
/// ```
class AvoidBannedAnnotations extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_banned_annotations',
    "The annotation '@{0}' is banned here.{1}",
    correctionMessage:
        'Remove the annotation or move this code out of the '
        'restricted directory.',
  );

  AvoidBannedAnnotations()
    : super(
        name: 'avoid_banned_annotations',
        description: 'Warns when a banned annotation is used in a file.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addAnnotation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidBannedAnnotations rule;

  _Visitor(this.rule);

  @override
  void visitAnnotation(Annotation node) {
    final entries = readBannedEntries(rule.config);
    if (entries.isEmpty) return;

    // `node.name` is the identifier as written, which for a prefixed
    // annotation (`@meta.visibleForTesting`) is the whole `meta.visibleForTesting`.
    // Take the last component so one spelling in config covers both forms.
    final name = switch (node.name) {
      PrefixedIdentifier(:final identifier) => identifier.name,
      final Identifier identifier => identifier.name,
    };
    if (name.isEmpty) return;

    final banned = findBannedEntry(
      entries: entries,
      value: name,
      relativePath: rule.relativePath,
    );
    if (banned == null) return;

    // Report the whole annotation including `@`, since that is what the user
    // deletes.
    rule.reportAtNode(node, arguments: [name, messageSuffix(banned)]);
  }
}
