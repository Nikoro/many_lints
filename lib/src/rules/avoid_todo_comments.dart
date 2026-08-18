import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a comment marks work that was never done.
///
/// A `TODO` marks a known missing case that ships anyway. That has always been
/// true; what changed is how cheap the marker became. Leaving one is the
/// fastest way for generated code to look finished — it reads as
/// work-in-progress rather than as a defect, and nothing downstream fails on
/// it.
///
/// The escape hatch that keeps this from being merely annoying is
/// `require_reference`, on by default: a marker naming a tracked issue passes,
/// a bare one does not. That turns "I will get to it" into something a person
/// who is not you can find, which is the entire difference between a note and
/// a plan.
///
/// ## How this differs from the SDK's `flutter_style_todos`
///
/// That rule enforces the *shape* `TODO(username): message` and has no opinion
/// on whether the TODO should exist. It also accepts a username, which
/// identifies who has context, not whether the work is tracked anywhere. This
/// rule asks the other question, and the default
/// [reference_pattern] accepts either an issue number or a URL. The two
/// compose without conflict.
///
/// **BAD:**
/// ```dart
/// // TODO: handle the 409 conflict case          // LINT
/// ```
///
/// **GOOD:**
/// ```dart
/// // TODO(#42): handle the 409 conflict case
/// ```
class AvoidTodoComments extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_todo_comments',
    "This '{0}' comment marks work that was never done.{1}",
    correctionMessage: 'Do the work, or file an issue and reference it here.',
  );

  AvoidTodoComments()
    : super(
        name: 'avoid_todo_comments',
        description: 'Warns when a comment marks work that was never done.',
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
  /// The markers reported by default.
  static const _defaultMarkers = {'TODO', 'FIXME', 'HACK', 'XXX'};

  /// Accepts an issue number or a URL, in either the parenthesised Flutter
  /// style or after the colon.
  ///
  /// Deliberately permissive about placement and strict about content: what
  /// matters is that a tracked identifier is present, not where the author put
  /// it.
  static final _defaultReference = RegExp(r'#\d+|https?://\S+|[A-Z]+-\d+');

  final AvoidTodoComments rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final markers = rule.config.nameSetOption(
      'markers',
      defaultValue: _defaultMarkers,
    );
    if (markers.isEmpty) return;

    final requireReference = rule.config.boolOption(
      'require_reference',
      defaultValue: true,
    );
    final reference = rule.config.patternOption(
      'reference_pattern',
      defaultValue: _defaultReference,
    )!;

    for (final comment in _comments(node)) {
      final text = comment.lexeme;
      final marker = _markerIn(text, markers);
      if (marker == null) continue;

      if (requireReference && reference.hasMatch(text)) continue;

      rule.reportAtToken(
        comment,
        arguments: [
          marker,
          requireReference ? ' It references no tracked issue.' : '',
        ],
      );
    }
  }

  /// The marker [text] opens with, or `null`.
  ///
  /// Anchoring at the start of the comment body is what separates a marker
  /// from prose that happens to contain the word — "the TODO above explains
  /// why" is a comment about a marker, not one.
  String? _markerIn(String text, Set<String> markers) {
    // Strip the comment delimiter and any leading whitespace, handling `//`,
    // `///` and `/*` alike.
    final body = text.replaceFirst(RegExp(r'^(///?/?|/\*+)'), '').trimLeft();

    for (final marker in markers) {
      if (!body.startsWith(marker)) continue;

      // Require a boundary so `TODOS.md` and `HACKATHON` are not markers.
      final rest = body.substring(marker.length);
      if (rest.isEmpty || !RegExp(r'^[A-Za-z0-9_]').hasMatch(rest)) {
        return marker;
      }
    }

    return null;
  }

  /// Every comment token in the unit, in source order.
  ///
  /// Comments are not AST nodes: each hangs off the token that follows it, so
  /// the only way to see all of them is to walk the token stream.
  Iterable<Token> _comments(CompilationUnit node) sync* {
    Token? token = node.beginToken;
    while (token != null) {
      Token? comment = token.precedingComments;
      while (comment != null) {
        yield comment;
        comment = comment.next;
      }

      if (token.isEof) break;
      token = token.next;
    }
  }
}
