import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';

import '../many_lints_rule.dart';

class AvoidCommentedOutCode extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_commented_out_code',
    'This comment looks like commented-out code.',
    correctionMessage:
        'Remove commented-out code. Use version control to '
        'track old code instead.',
  );

  AvoidCommentedOutCode()
    : super(
        name: 'avoid_commented_out_code',
        description: 'Warns when commented-out code is found.',
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
  final AvoidCommentedOutCode rule;

  _Visitor(this.rule);

  static final _annotationPattern = RegExp(r'^@[a-zA-Z]+');
  static final _assignmentPattern = RegExp(
    r'^[a-zA-Z_]\w*(\.\w+)*\s*[+\-*/]?=\s',
  );
  static final _returnPattern = RegExp(r'^return\s');
  static final _cascadePattern = RegExp(r'^\.\.[a-zA-Z]');
  static final _functionCallPattern = RegExp(
    r'^[a-zA-Z_]\w*(\.\w+)*\s*(<[^>]*>)?\s*\(',
  );
  static final _whitespacePattern = RegExp(r'\s+');

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // Edge case: the visitor is reused across files, so the previous unit's tokens must go
    _precedingCode.clear();

    final allComments = _collectAllComments(node);
    final lineInfo = node.lineInfo;
    final groups = _groupConsecutiveComments(allComments, lineInfo);

    final minLines = rule.config.intOption('min_lines', defaultValue: 1);

    for (final group in groups) {
      if (group.length < minLines) continue;

      final stripped = group
          .map((t) => _stripCommentPrefix(t.lexeme))
          .join('\n')
          .trim();

      if (stripped.isEmpty) continue;

      if (_looksLikeCode(stripped)) {
        final first = group.first;
        final last = group.last;
        final offset = first.offset;
        final length = last.end - first.offset;
        rule.reportAtOffset(offset, length);
      }
    }
  }

  // Edge case: generated files with thousands of comment lines would stall the analysis server
  static const _maxComments = 500;

  List<Token> _collectAllComments(CompilationUnit node) {
    final comments = <Token>[];
    Token? token = node.beginToken;
    Token? lastCode;

    while (token != null && !token.isEof) {
      Token? comment = token.precedingComments;
      while (comment != null) {
        if (_isSingleLineComment(comment)) {
          comments.add(comment);
          if (lastCode != null) _precedingCode[comment] = lastCode;
          if (comments.length >= _maxComments) return comments;
        }
        comment = comment.next;
      }
      lastCode = token;
      token = token.next;
    }

    if (token != null && token.isEof) {
      Token? comment = token.precedingComments;
      while (comment != null) {
        if (_isSingleLineComment(comment)) {
          comments.add(comment);
          if (lastCode != null) _precedingCode[comment] = lastCode;
          if (comments.length >= _maxComments) return comments;
        }
        comment = comment.next;
      }
    }

    return comments;
  }

  bool _isSingleLineComment(Token token) {
    if (token.type != TokenType.SINGLE_LINE_COMMENT) return false;
    final lexeme = token.lexeme;
    if (lexeme.startsWith('///')) return false;
    if (lexeme.contains('ignore:') || lexeme.contains('ignore_for_file:')) {
      return false;
    }
    return true;
  }

  List<List<Token>> _groupConsecutiveComments(
    List<Token> comments,
    LineInfo lineInfo,
  ) {
    if (comments.isEmpty) return [];

    final groups = <List<Token>>[];
    var currentGroup = <Token>[comments.first];

    for (var i = 1; i < comments.length; i++) {
      final prev = comments[i - 1];
      final curr = comments[i];

      final prevLine = lineInfo.getLocation(prev.end).lineNumber;
      final currLine = lineInfo.getLocation(curr.offset).lineNumber;

      if (currLine == prevLine + 1 &&
          !_hasCodeBetween(prev, curr) &&
          // Edge case: a trailing comment remarks on its own line, not on the block below it
          !_trailsCode(prev, lineInfo) &&
          !_trailsCode(curr, lineInfo)) {
        currentGroup.add(curr);
      } else {
        groups.add(currentGroup);
        currentGroup = [curr];
      }
    }
    groups.add(currentGroup);
    return groups;
  }

  bool _trailsCode(Token comment, LineInfo lineInfo) {
    final previous = _precedingCode[comment];
    if (previous == null) return false;

    final commentLine = lineInfo.getLocation(comment.offset).lineNumber;
    final previousLine = lineInfo.getLocation(previous.end).lineNumber;
    return previousLine == commentLine;
  }

  final Map<Token, Token> _precedingCode = {};

  bool _hasCodeBetween(Token a, Token b) {
    for (Token? comment = a.next; comment != null; comment = comment.next) {
      if (identical(comment, b)) return false;
    }
    return true;
  }

  String _stripCommentPrefix(String lexeme) {
    if (lexeme.startsWith('// ')) return lexeme.substring(3);
    if (lexeme.startsWith('//')) return lexeme.substring(2);
    return lexeme;
  }

  bool _looksLikeCode(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return false;

    var codeLineCount = 0;
    for (final line in lines) {
      if (_lineIsLikelyCode(line.trim())) {
        codeLineCount++;
      }
    }

    return codeLineCount > 0 && codeLineCount >= (lines.length + 1) ~/ 2;
  }

  bool _lineIsLikelyCode(String line) {
    if (line.isEmpty) return false;

    if (_isProse(line)) return false;

    if (line.endsWith(';') ||
        line.endsWith('{') ||
        line.endsWith('}') ||
        line.endsWith('},') ||
        line.endsWith(');') ||
        line.endsWith('),')) {
      return true;
    }

    if (_startsWithCodeKeyword(line)) return true;

    if (line == '}' || line == '};' || line == '},') return true;

    if (_looksLikeFunctionCall(line)) return true;

    if (_annotationPattern.hasMatch(line)) return true;

    if (_assignmentPattern.hasMatch(line)) return true;

    if (_returnPattern.hasMatch(line)) return true;

    if (_cascadePattern.hasMatch(line)) return true;

    return false;
  }

  bool _isProse(String line) {
    final lower = line.toLowerCase();
    if (lower.startsWith('todo') ||
        lower.startsWith('fixme') ||
        lower.startsWith('hack') ||
        lower.startsWith('note:') ||
        lower.startsWith('note ') ||
        lower.startsWith('see ') ||
        lower.startsWith('ref:') ||
        lower.startsWith('bug:') ||
        lower.startsWith('warning:')) {
      return true;
    }

    if (!line.contains(';') &&
        !line.contains('{') &&
        !line.contains('}') &&
        !line.contains('(') &&
        !line.contains(')') &&
        !line.contains('=') &&
        !line.startsWith('@') &&
        !line.startsWith('import ') &&
        !line.startsWith('export ')) {
      final words = line.split(_whitespacePattern);
      if (words.length >= 3) return true;
    }

    return false;
  }

  bool _startsWithCodeKeyword(String line) {
    const keywords = [
      'final ',
      'var ',
      'const ',
      'class ',
      'abstract ',
      'enum ',
      'void ',
      'int ',
      'double ',
      'String ',
      'bool ',
      'List<',
      'Map<',
      'Set<',
      'Future<',
      'Stream<',
      'if (',
      'if(',
      'else {',
      'else{',
      'for (',
      'for(',
      'while (',
      'while(',
      'switch (',
      'switch(',
      'try {',
      'try{',
      'catch (',
      'catch(',
      'throw ',
      'import ',
      'export ',
      'part ',
      'late ',
      'static ',
      '@override',
      'Widget ',
      'State<',
      'BuildContext ',
    ];

    for (final keyword in keywords) {
      if (line.startsWith(keyword)) return true;
    }
    return false;
  }

  bool _looksLikeFunctionCall(String line) {
    return _functionCallPattern.hasMatch(line);
  }
}
