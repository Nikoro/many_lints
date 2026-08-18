import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a catch clause does nothing with the exception it caught.
///
/// An empty catch converts a failure into silence. The release continues, the
/// upload never arrived, and the first sign of trouble is an unreadable stack
/// trace weeks later in a part of the system that did nothing wrong.
///
/// ## How this differs from the SDK's `empty_catches`
///
/// The SDK rule permits the two shapes that cause most of the damage:
///
/// ```dart
/// try { ... } catch (_) {}          // OK for empty_catches, LINT here
/// try { ... } catch (e) { /* meh */ }  // OK for empty_catches, LINT here
/// ```
///
/// Both are ways of writing "I have decided this failure does not matter", and
/// `catch (_) {}` is the more common of the two precisely because the SDK rule
/// blesses it. A comment is not an escape hatch either: it tells a reader who
/// is already looking at this line, which is not who needs to know.
///
/// The body has to do something observable — log, rethrow, wrap, or return a
/// fallback the caller can see. `allow_with_comment: true` restores the SDK's
/// laxer policy for projects that want it.
///
/// This is the missing half of `avoid_only_rethrow`, which flags the opposite
/// shape: a catch that does nothing *but* rethrow.
///
/// **BAD:**
/// ```dart
/// try {
///   await _uploadSymbols();
/// } catch (_) {}                    // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// try {
///   await _uploadSymbols();
/// } on UploadFailure catch (e, s) {
///   _log.warning('symbol upload failed', e, s);
/// }
/// ```
class AvoidEmptyCatch extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_empty_catch',
    'This catch clause silently discards the failure.',
    correctionMessage:
        'Log it, rethrow it, wrap it, or return a fallback the caller can '
        'see.',
  );

  AvoidEmptyCatch()
    : super(
        name: 'avoid_empty_catch',
        description:
            'Warns when a catch clause does nothing with the exception it '
            'caught.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addTryStatement(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidEmptyCatch rule;

  _Visitor(this.rule);

  @override
  void visitTryStatement(TryStatement node) {
    final allowWithComment = rule.config.boolOption(
      'allow_with_comment',
      defaultValue: false,
    );

    for (final catchClause in node.catchClauses) {
      final body = catchClause.body;
      if (body.statements.isNotEmpty) continue;

      if (allowWithComment && _hasComment(body)) continue;

      rule.reportAtNode(catchClause);
    }
  }

  /// Whether [body] holds a comment between its braces.
  ///
  /// A comment is attached to the token that *follows* it, and for an empty
  /// block the only token after the comment is the closing brace — so that is
  /// where to look, not on the block or the opening brace.
  bool _hasComment(Block body) => body.rightBracket.precedingComments != null;
}
