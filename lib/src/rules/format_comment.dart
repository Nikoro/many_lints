import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

class FormatComment extends ManyLintsRule {
  static const LintCode code = LintCode(
    'format_comment',
    'This comment {0}.',
    correctionMessage: 'Write it as a sentence, or delete it.',
  );

  FormatComment()
    : super(
        name: 'format_comment',
        description:
            'Warns when a comment is not written as a capitalised, '
            'terminated sentence.',
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
  // Edge case: `part` and `dart` stay out, `part` matched the prose "part of what happened."
  static const _toolKeywords = {
    'ignore',
    'ignore_for_file',
    'TODO',
    'FIXME',
    'HACK',
    'NOTE',
    'coverage',
    'expect',
  };

  static final _urlOrPath = RegExp(
    r'(https?://|www\.|\S+\.(dart|md|yaml|json))',
  );
  static final _macro = RegExp(r'^\{@\w+');

  // Edge case: closers may follow, as in `(see §3.5).` or a code span ending in a backtick
  static final _endsSentence = RegExp(r'[.!?:][`")\]*_]*$');

  final FormatComment rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final checkRegular = rule.config.boolOption(
      'check_regular_comments',
      defaultValue: false,
    );

    for (final block in _commentBlocks(node, checkRegular: checkRegular)) {
      _checkBlock(block);
    }
  }

  List<List<Token>> _commentBlocks(
    CompilationUnit node, {
    required bool checkRegular,
  }) {
    final blocks = <List<Token>>[];
    var current = <Token>[];
    var previousLine = -2;

    Token? token = node.beginToken;
    while (token != null && !token.isEof) {
      Token? comment = token.precedingComments;
      while (comment != null) {
        final lexeme = comment.lexeme;
        final isDoc = lexeme.startsWith('///');
        final isRegular = lexeme.startsWith('//') && !isDoc;

        if (isDoc || (checkRegular && isRegular)) {
          final line = node.lineInfo.getLocation(comment.offset).lineNumber;
          if (line != previousLine + 1 && current.isNotEmpty) {
            blocks.add(current);
            current = <Token>[];
          }
          current.add(comment);
          previousLine = line;
        }

        comment = comment.next;
      }

      token = token.next;
    }

    if (current.isNotEmpty) blocks.add(current);

    return blocks;
  }

  void _checkBlock(List<Token> block) {
    final lines = block.map((t) => _stripPrefix(t.lexeme)).toList();

    if (lines.every((line) => line.isEmpty || _isExempt(line))) return;

    var inCodeFence = false;
    String? firstProse;
    String? lastProse;
    Token? firstToken;
    Token? lastToken;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('```')) {
        inCodeFence = !inCodeFence;
        continue;
      }
      if (inCodeFence || line.isEmpty || _isExempt(line)) continue;

      firstProse ??= line;
      firstToken ??= block[i];
      lastProse = line;
      lastToken = block[i];
    }

    if (firstProse == null || lastProse == null) return;

    if (!_startsCapitalised(firstProse)) {
      rule.reportAtToken(
        firstToken!,
        arguments: ['does not start with a capital letter'],
      );
      return;
    }

    if (!_endsSentence.hasMatch(lastProse)) {
      rule.reportAtToken(lastToken!, arguments: ['does not end with a period']);
    }
  }

  String _stripPrefix(String lexeme) {
    final withoutSlashes = lexeme.startsWith('///')
        ? lexeme.substring(3)
        : lexeme.substring(2);

    return withoutSlashes.trim();
  }

  bool _isExempt(String line) =>
      _macro.hasMatch(line) ||
      _isBareUrlOrPath(line) ||
      _isIndentedCodeSample(line) ||
      _startsWithToolKeyword(line);

  bool _isBareUrlOrPath(String line) =>
      _urlOrPath.hasMatch(line) && !line.contains(' ');

  bool _isIndentedCodeSample(String line) => line.startsWith('    ');

  bool _startsWithToolKeyword(String line) {
    final firstWord = line.split(RegExp(r'[\s(:]')).first;

    return _toolKeywords.contains(firstWord);
  }

  bool _startsCapitalised(String line) {
    final opensOnCodeReference = line.startsWith('`') || line.startsWith('[');
    if (opensOnCodeReference) return true;

    final first = line[0];
    if (first.toUpperCase() == first) return true;

    final firstWord = line.split(RegExp(r'[\s(,.]')).first;

    return _hasIdentifierShape(firstWord);
  }

  bool _hasIdentifierShape(String word) {
    if (word.contains('_')) return true;
    if (word.length <= 1) return false;

    final afterFirst = word.substring(1);

    return afterFirst != afterFirst.toLowerCase();
  }
}
