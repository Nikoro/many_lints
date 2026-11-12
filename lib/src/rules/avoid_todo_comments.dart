import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

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
  static const _defaultMarkers = {'TODO', 'FIXME', 'HACK', 'XXX'};

  static final _defaultReference = RegExp(r'#\d+|https?://\S+|[A-Z]+-\d+');

  static final _commentDelimiter = RegExp(r'^(///?/?|/\*+)');

  static final _leadingWordCharacter = RegExp(r'^[A-Za-z0-9_]');

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

  String? _markerIn(String text, Set<String> markers) {
    final body = text.replaceFirst(_commentDelimiter, '').trimLeft();

    for (final marker in markers) {
      if (!body.startsWith(marker)) continue;

      final rest = body.substring(marker.length);
      final continuesWord = _leadingWordCharacter.hasMatch(rest);
      if (!continuesWord) {
        return marker;
      }
    }

    return null;
  }

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
