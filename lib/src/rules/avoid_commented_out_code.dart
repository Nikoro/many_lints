import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';

import '../many_lints_rule.dart';

/// Warns when commented-out code is found.
///
/// Commented-out code is a sign of technical debt. Use version control
/// instead of keeping old code in comments.
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
    // The visitor is reused across files; drop the previous unit's tokens.
    _precedingCode.clear();

    final allComments = _collectAllComments(node);
    final lineInfo = node.lineInfo;
    final groups = _groupConsecutiveComments(allComments, lineInfo);

    for (final group in groups) {
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

  /// Maximum number of single-line comments to collect before bailing out.
  /// Prevents stalling the analysis server on auto-generated files with
  /// thousands of comment lines.
  static const _maxComments = 500;

  /// Collects all single-line comment tokens (`//`) from the token stream,
  /// excluding doc comments (`///`) and ignore directives.
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

    // Also check the EOF token's preceding comments.
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

  /// Returns true if the token is a single-line `//` comment (not `///`).
  bool _isSingleLineComment(Token token) {
    if (token.type != TokenType.SINGLE_LINE_COMMENT) return false;
    final lexeme = token.lexeme;
    // Exclude doc comments (///) and ignore directives.
    if (lexeme.startsWith('///')) return false;
    if (lexeme.contains('ignore:') || lexeme.contains('ignore_for_file:')) {
      return false;
    }
    return true;
  }

  /// Groups comment tokens that appear on directly consecutive lines with
  /// nothing but whitespace between them.
  ///
  /// Two comments belong together only when the second starts on the line
  /// right after the first ends. A blank line ends the group, and so does
  /// any code between them — otherwise unrelated comments elsewhere in the
  /// file would merge into one block and dilute the code-vs-prose ratio,
  /// hiding real detections.
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

      // A comment that trails code starts its own group: `} // note` is a
      // remark about that line, not part of the block below it.
      if (currLine == prevLine + 1 &&
          !_hasCodeBetween(prev, curr) &&
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

  /// Whether [comment] follows code on its own line.
  ///
  /// A trailing comment annotates the code beside it, so it does not belong
  /// to a block of full-line comments above or below it. The token the
  /// comment hangs off is recorded while collecting, and the code before it
  /// is on the same line exactly when that token's predecessor ends there.
  bool _trailsCode(Token comment, LineInfo lineInfo) {
    final previous = _precedingCode[comment];
    if (previous == null) return false;

    final commentLine = lineInfo.getLocation(comment.offset).lineNumber;
    final previousLine = lineInfo.getLocation(previous.end).lineNumber;
    return previousLine == commentLine;
  }

  /// Maps each collected comment to the last real token before it.
  final Map<Token, Token> _precedingCode = {};

  /// Whether a real token sits between two comment tokens.
  ///
  /// Comments hang off the token that follows them, so two comments attached
  /// to different tokens have code between them — even when they land on
  /// adjacent lines, as in `} // trailing` followed by `// next`.
  bool _hasCodeBetween(Token a, Token b) {
    // Comments in the same `precedingComments` chain share a parent token
    // and therefore have nothing but whitespace between them.
    for (Token? comment = a.next; comment != null; comment = comment.next) {
      if (identical(comment, b)) return false;
    }
    return true;
  }

  /// Strips the `//` prefix and optional leading space from a comment.
  String _stripCommentPrefix(String lexeme) {
    if (lexeme.startsWith('// ')) return lexeme.substring(3);
    if (lexeme.startsWith('//')) return lexeme.substring(2);
    return lexeme;
  }

  /// Heuristic check: does the stripped comment text look like Dart code?
  bool _looksLikeCode(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return false;

    var codeLineCount = 0;
    for (final line in lines) {
      if (_lineIsLikelyCode(line.trim())) {
        codeLineCount++;
      }
    }

    // If more than half the non-empty lines look like code, flag it.
    return codeLineCount > 0 && codeLineCount >= (lines.length + 1) ~/ 2;
  }

  /// Checks if a single line of text looks like Dart code.
  bool _lineIsLikelyCode(String line) {
    // Empty lines are neutral.
    if (line.isEmpty) return false;

    // Ignore typical prose and note comments.
    if (_isProse(line)) return false;

    // Lines ending with ; or { or } or , are very likely code.
    if (line.endsWith(';') ||
        line.endsWith('{') ||
        line.endsWith('}') ||
        line.endsWith('},') ||
        line.endsWith(');') ||
        line.endsWith('),')) {
      return true;
    }

    // Lines starting with common Dart keywords followed by code patterns.
    if (_startsWithCodeKeyword(line)) return true;

    // Lines that are just a closing brace.
    if (line == '}' || line == '};' || line == '},') return true;

    // Lines that look like function/method calls: word( or word.word(
    if (_looksLikeFunctionCall(line)) return true;

    // Lines that look like annotations: @override, @required, etc.
    if (_annotationPattern.hasMatch(line)) return true;

    // Lines that look like assignments: word = ...
    if (_assignmentPattern.hasMatch(line)) return true;

    // Lines that look like return statements
    if (_returnPattern.hasMatch(line)) return true;

    // Lines that are just a single statement with a dot chain
    if (_cascadePattern.hasMatch(line)) return true;

    return false;
  }

  /// Returns true if the line looks like natural language / prose.
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

    // Lines that are just prose (no code-like characters).
    // Prose tends to have spaces and no special code characters.
    if (!line.contains(';') &&
        !line.contains('{') &&
        !line.contains('}') &&
        !line.contains('(') &&
        !line.contains(')') &&
        !line.contains('=') &&
        !line.startsWith('@') &&
        !line.startsWith('import ') &&
        !line.startsWith('export ')) {
      // If it's mostly words with spaces and no code markers, it's prose.
      final words = line.split(_whitespacePattern);
      if (words.length >= 3) return true;
    }

    return false;
  }

  /// Checks if the line starts with a common Dart code keyword.
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
      // Anchored on the `@`: bare `override` also opens ordinary prose such as
      // "override this in subclasses", and the annotation is what code uses.
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

  /// Checks if a line looks like a function or method call.
  bool _looksLikeFunctionCall(String line) {
    return _functionCallPattern.hasMatch(line);
  }
}
