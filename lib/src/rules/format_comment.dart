import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a comment does not start with a capital letter or does not end
/// with a period.
///
/// Effective Dart asks for exactly this of doc comments — "start with a
/// one-sentence summary", where a sentence is capitalised and terminated — and
/// the same reads better for ordinary comments. The value is not the
/// punctuation itself but the discipline behind it: a fragment that cannot be
/// punctuated as a sentence is usually a label restating the code, which is a
/// comment worth deleting rather than fixing.
///
/// By default only doc comments (`///`) are checked, since that is where the
/// convention is documented and where the text is rendered for readers who do
/// not have the code in front of them. Set `check_regular_comments: true` to
/// include `//` too.
///
/// A great deal is deliberately exempt, because a comment is also the place
/// people legitimately put things that are not prose:
///
/// - Anything the tools read: `// ignore:`, `// TODO(user):`, `// coverage:`.
/// - A URL, a file path, or a fenced code block inside a doc comment.
/// - A macro or directive line (`{@template ...}`, `part of`).
/// - A continuation line, since only the first line of a comment block starts
///   the sentence and only the last one ends it.
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
  /// First words a tool reads rather than a reader, so they are not prose.
  ///
  /// Deliberately short. Every entry here is a word that stops being ordinary
  /// English, and `part` and `dart` were removed after `part` matched "part of
  /// what happened." in a real doc comment.
  static const _directives = {
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

  /// A sentence terminator, allowing the closers that legitimately follow it.
  ///
  /// The naive `[.!?:]$` reports a correctly written sentence that happens to
  /// end inside a parenthetical or a code span — `... (see §3.5).` and
  /// ``... a decider, `8:7` in the fourth.`` were both real false positives.
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

  /// Consecutive comment tokens of the same kind, grouped into blocks.
  ///
  /// The block rather than the line is the unit: a sentence spanning three
  /// `///` lines is capitalised on the first and terminated on the last, so
  /// checking each line alone would report both middle lines for nothing.
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

    // A block that is entirely non-prose — a fenced example, a bare URL, a
    // directive — has nothing to capitalise or terminate.
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

  bool _isExempt(String line) {
    if (_macro.hasMatch(line)) return true;
    // Only a line that IS a bare URL, not one that mentions a file. A sentence
    // ending "(`plan.md` §3.5)." is prose, and exempting it dropped it from
    // its block — which then reported the line above it for missing a period.
    if (_urlOrPath.hasMatch(line) && !line.contains(' ')) return true;
    // An indented line inside a doc comment is a code sample rather than prose.
    if (line.startsWith('    ')) return true;

    // Matched on the first WORD only. A `startsWith` over the raw line makes
    // every directive a prefix of ordinary English: `part` matched "part of
    // what happened.", silently making that the wrong last line of its block
    // and reporting the line above it for missing a period.
    final firstWord = line.split(RegExp(r'[\s(:]')).first;

    return _directives.contains(firstWord);
  }

  bool _startsCapitalised(String line) {
    // A line opening on an identifier — `foo()` returns null — is describing
    // code, and Dart identifiers are conventionally lowercase. Requiring a
    // capital there would ask for a wrong name.
    if (line.startsWith('`')) return true;
    if (line.startsWith('[')) return true;

    final first = line[0];
    if (first.toUpperCase() == first) return true;

    // A bare identifier opening the sentence is the same case without the
    // backticks: `dart_frog mounts a dynamic route...` is naming a package,
    // and capitalising it would falsify the name. Recognised by the shape no
    // English word has — an underscore or an inner capital.
    final firstWord = line.split(RegExp(r'[\s(,.]')).first;
    if (firstWord.contains('_')) return true;
    if (firstWord.length > 1 &&
        firstWord.substring(1) != firstWord.substring(1).toLowerCase()) {
      return true;
    }

    return false;
  }
}
