import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../pattern_entry.dart';
import '../rule_config.dart';

/// Applies the `replace:` template of the `match_pattern` entry that reported.
///
/// The template comes from the project's own configuration, so this fix is
/// held to guard rails the hand-written fixes do not need:
///
/// - **Opt-in.** An entry with no `replace:` offers nothing.
/// - **Parsed before offering.** A template that produces source which does
///   not parse is dropped and the diagnostic is left alone, so a wrong pattern
///   cannot turn working code into a syntax error.
/// - **Never bulk-applied.** [applicability] is `singleLocation`, so
///   `dart fix --apply` will not sweep a hand-written regex across a project.
class MatchPatternFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.matchPattern',
    DartFixKindPriority.standard,
    'Apply the configured replacement',
  );

  MatchPatternFix({required super.context});

  /// A configured rewrite is only ever offered where it was reported.
  ///
  /// The template is an unreviewed regex substitution rather than a shape this
  /// package understands, so bulk application is exactly the footgun to avoid.
  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final target = coveringNode;
    if (target == null) return;

    final source = target.toSource();
    final replacement = _resolveReplacement(target, source);
    if (replacement == null) return;

    // A template that produces unparsable source is dropped rather than
    // offered: the diagnostic still stands, and the author is not handed a
    // lightbulb that breaks the file.
    if (!_parses(replacement)) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(target), replacement);
    });
  }

  /// Re-resolves the rule's `patterns:` for this file and expands the template
  /// of the entry matching [source].
  String? _resolveReplacement(AstNode target, String source) {
    final resolved = ResolvedRuleConfig.forPath(
      packageRoot: unitResult.session.analysisContext.contextRoot.root,
      path: unitResult.path,
      ruleName: 'match_pattern',
    );

    final entries = readPatternEntries(resolved.config);
    if (entries.isEmpty) return null;

    final kind = switch (target) {
      MethodInvocation() => PatternNode.methodInvocation,
      PropertyAccess() => PatternNode.propertyAccess,
      _ => null,
    };
    if (kind == null) return null;

    final entry = findPatternEntry(
      entries: entries,
      node: kind,
      source: source,
      relativePath: unitResult.session.analysisContext.contextRoot.root
          .relativeIfContains(unitResult.path)
          ?.replaceAll(r'\', '/'),
    );
    if (entry == null) return null;

    return entry.replacementFor(source);
  }

  /// Whether [replacement] parses as a Dart expression.
  ///
  /// Wrapped in a trivial declaration because the analyzer parses compilation
  /// units, not bare expressions. Syntax errors anywhere in the wrapper can
  /// only come from the replacement.
  static bool _parses(String replacement) {
    final result = parseString(
      content: 'void _p() { $replacement; }',
      throwIfDiagnostics: false,
    );

    return result.errors.isEmpty;
  }
}
