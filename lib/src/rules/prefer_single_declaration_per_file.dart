import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../declaration_group.dart';
import '../many_lints_rule.dart';

/// Warns when a file declares more than one top-level declaration of the same
/// configured group.
///
/// Unconfigured, this is the general rule: classes, mixins, enums, extensions
/// and extension types all count together, and the second public one reports.
///
/// The `groups:` option is what makes the rule cover the type-specific
/// variants — "one notifier per file", "one bloc per file" — without shipping a
/// near-identical rule per framework. Each group carries its own budget, so a
/// project can state several limits that do not interfere:
///
/// ```yaml
/// rules:
///   prefer_single_declaration_per_file:
///     groups:
///       - types: [Bloc, Cubit]
///       - types: [Notifier, AsyncNotifier]
/// ```
///
/// A file holding one bloc and one notifier satisfies both. Folding them into
/// one count would report exactly the layout the project asked for.
class PreferSingleDeclarationPerFile extends ManyLintsRule {
  static const LintCode code = LintCode(
    'prefer_single_declaration_per_file',
    "Only one '{0}' declaration per file.{1}",
    correctionMessage: 'Move this declaration to its own file.',
  );

  PreferSingleDeclarationPerFile()
    : super(
        name: 'prefer_single_declaration_per_file',
        description:
            'Warns when a file contains more than one top-level declaration.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSingleDeclarationPerFile rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // Read config inside the callback: rule instances are long-lived
    // singletons shared across package roots, and `config` is only resolved
    // once the reporter for the current file has been set.
    final groups = readDeclarationGroups(rule.config);

    // One count per group, so the groups' budgets stay independent.
    final seen = List.filled(groups.length, 0);

    for (final declaration in node.declarations) {
      final element = declaration.declaredFragment?.element;

      for (var i = 0; i < groups.length; i++) {
        final group = groups[i];
        if (!group.counts(declaration, element)) continue;

        // A declaration matching several groups is counted by the first one
        // only. Counting it in every group would report a single declaration
        // repeatedly once overlapping groups are configured, and the first
        // match is the one the project listed first.
        if (seen[i]++ > 0) {
          final token = declarationNameToken(declaration);
          if (token != null) {
            rule.reportAtToken(
              token,
              arguments: [_label(group), _messageSuffix(group)],
            );
          }
        }
        break;
      }
    }
  }

  /// How a group names itself in its diagnostic.
  ///
  /// A typed group reads better as its type list ("Only one 'Bloc'
  /// declaration per file") than as the generic word, since the type is what
  /// the project actually limited.
  String _label(DeclarationGroup group) {
    if (group.types.isNotEmpty) return group.types.join("' / '");

    if (group.kinds.length == 1) return group.kinds.first.optionName;

    return 'top-level';
  }

  /// The group's own `message:`, as a sentence appended to the diagnostic.
  ///
  /// Passed as a message argument rather than baked into a per-access
  /// [LintCode]: the value varies per diagnostic once several groups are
  /// configured, and minting a new code object per report would break the fix
  /// registry and severity overrides, both of which key on the code.
  String _messageSuffix(DeclarationGroup group) {
    final message = group.message;
    return message == null ? '' : ' $message';
  }
}
