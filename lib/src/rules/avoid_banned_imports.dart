import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../banned_entry.dart';
import '../many_lints_rule.dart';

/// Warns when a file imports a library banned for its location.
///
/// This is architecture enforcement: it keeps a Clean Architecture domain
/// layer free of Flutter, stops `dart:io` reaching shared code that also
/// targets the web, and confines a legacy package to the module still using
/// it. Nothing is banned until you configure it — installing this package
/// never restricts an import on its own.
///
/// **Configuration** (`many_lints.yaml`):
///
/// ```yaml
/// rules:
///   avoid_banned_imports:
///     banned:
///       - deny: ['package:flutter/material.dart']
///         in: ['lib/domain/**', 'lib/data/**']
///         message: 'The domain layer must not depend on Flutter.'
///       - deny_pattern: ['package:legacy_.*']
///         message: 'Legacy packages are being removed.'
/// ```
///
/// **BAD:**
/// ```dart
/// // in lib/domain/user.dart
/// import 'package:flutter/material.dart';  // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// // in lib/domain/user.dart
/// import 'package:meta/meta.dart';
/// ```
class AvoidBannedImports extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_banned_imports',
    "The import '{0}' is banned here.{1}",
    correctionMessage:
        'Remove the import or move this code out of the '
        'restricted directory.',
  );

  AvoidBannedImports()
    : super(
        name: 'avoid_banned_imports',
        description:
            'Warns when a file imports a library banned for its '
            'location.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidBannedImports rule;

  _Visitor(this.rule);

  @override
  void visitImportDirective(ImportDirective node) {
    // Read config inside the callback: rule instances are long-lived
    // singletons reused across package roots, so this cannot be cached.
    final entries = readBannedEntries(rule.config);
    if (entries.isEmpty) return;

    // The URI as written, so `deny:` reads exactly like the import line the
    // user wants to ban. Resolving to an absolute file URI instead would make
    // every entry unwriteable by hand.
    final uri = node.uri.stringValue;
    if (uri == null) return;

    final banned = findBannedEntry(
      entries: entries,
      value: uri,
      relativePath: rule.relativePath,
    );
    if (banned == null) return;

    // The URI and the explanation vary per diagnostic, so they travel as
    // message arguments — the LintCode must stay one stable instance.
    rule.reportAtNode(node.uri, arguments: [uri, messageSuffix(banned)]);
  }
}
