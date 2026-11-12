import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../primary_constructor_candidate.dart';

class PreferPrimaryConstructorsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.preferPrimaryConstructors',
    DartFixKindPriority.standard,
    'Convert to a primary constructor',
  );

  PreferPrimaryConstructorsFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossFiles;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorMatching(
      (n) => n is ClassDeclaration || n is EnumDeclaration,
    );
    if (declaration is! CompilationUnitMember) return;
    final candidate = PrimaryConstructorCandidate.tryRead(declaration);
    if (candidate == null) return;

    final rewrite = _Rewrite(unitResult.content, candidate);
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.startOffsetEndOffset(candidate.namePart.offset, rewrite.bodyEnd),
        rewrite.render(),
      );
    });
  }
}

class _Edit {
  final int start;
  final int end;
  final String text;

  const _Edit(this.start, this.end, this.text);
}

class _Rewrite {
  final String content;
  final PrimaryConstructorCandidate candidate;

  _Rewrite(this.content, this.candidate);

  ConstructorDeclaration get _constructor => candidate.constructor;

  int get bodyStart => switch (candidate.declaration) {
    ClassDeclaration(:final body) => body.offset,
    EnumDeclaration(:final body) => body.offset,
    final other => other.end,
  };

  int get bodyEnd => switch (candidate.declaration) {
    ClassDeclaration(:final body) => body.end,
    EnumDeclaration(:final body) => body.end,
    final other => other.end,
  };

  String render() {
    final header = _header();
    final between = content.substring(candidate.namePart.end, bodyStart);
    final body = _slice(bodyStart, bodyEnd, _bodyEdits());

    if (candidate.declaration is ClassDeclaration && _isEmptyBraces(body)) {
      return '$header${between.trimRight()};';
    }
    return '$header$between$body';
  }

  String _header() {
    final namePart = candidate.namePart;
    final constPrefix = _constructor.constKeyword != null && !candidate.isEnum
        ? 'const '
        : '';
    final typeParameters = namePart.typeParameters?.toSource() ?? '';
    final constructorName = switch (_constructor.name) {
      final name? => '.${name.lexeme}',
      null => '',
    };
    return '$constPrefix${namePart.typeName.lexeme}$typeParameters'
        '$constructorName${_parameterList()}';
  }

  String _parameterList() {
    final list = _constructor.parameters;
    final edits = [
      for (final MapEntry(key: parameter, value: field)
          in candidate.declaringFields.entries)
        _Edit(parameter.offset, parameter.end, _declaring(parameter, field)),
    ];

    if (!candidate.needsThisBlock) {
      final comments = _leadingComments(_constructor);
      if (comments.isNotEmpty) {
        edits.add(_Edit(list.offset + 1, list.offset + 1, '\n$comments'));
      }
    }

    return _slice(list.offset, list.end, edits);
  }

  String _declaring(FieldFormalParameter parameter, FieldDeclaration field) {
    final fields = field.fields;
    final comments = _leadingComments(field);
    final buffer = StringBuffer(comments.isEmpty ? '' : '\n$comments');
    for (final annotation in field.metadata) {
      buffer.write('${annotation.toSource()} ');
    }
    buffer.write(
      content.substring(
        parameter.offset,
        parameter.firstTokenAfterCommentAndMetadata.offset,
      ),
    );
    if (parameter.requiredKeyword != null) buffer.write('required ');
    buffer.write(fields.isFinal ? 'final ' : 'var ');
    if (fields.type case final type?) buffer.write('${type.toSource()} ');
    buffer.write(parameter.name.lexeme);
    if (parameter.defaultClause case final defaultClause?) {
      buffer.write(' = ${defaultClause.value.toSource()}');
    }
    return buffer.toString();
  }

  List<_Edit> _bodyEdits() {
    final removals = [
      for (final field in candidate.declaringFields.values.toSet())
        _wholeLines(field),
      if (!candidate.needsThisBlock) _wholeLines(_constructor),
    ];

    return [
      ..._tidy(_merge(removals)),
      if (candidate.needsThisBlock)
        _Edit(
          _firstRealToken(_constructor).offset,
          _constructor.end,
          _thisBlock(),
        ),
    ];
  }

  String _thisBlock() {
    final initializers = _constructor.initializers;
    final buffer = StringBuffer('this');
    if (initializers.isNotEmpty) {
      final source = content.substring(
        initializers.first.offset,
        initializers.last.end,
      );
      buffer.write(' : $source');
    }
    final body = _constructor.body;
    if (body is BlockFunctionBody &&
        (body.block.statements.isNotEmpty ||
            body.block.rightBracket.precedingComments != null)) {
      buffer.write(' ${content.substring(body.offset, body.end)}');
    } else {
      buffer.write(';');
    }
    return buffer.toString();
  }

  _Edit _wholeLines(AnnotatedNode member) {
    final start = _leadingStart(member);
    var end = member.end;
    final lineEnd = content.indexOf('\n', end);
    if (lineEnd >= 0 && content.substring(end, lineEnd).trim().isEmpty) {
      end = lineEnd + 1;
    }
    return _Edit(start, end, '');
  }

  List<_Edit> _merge(List<_Edit> removals) {
    removals.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_Edit>[];
    for (final removal in removals) {
      final last = merged.lastOrNull;
      if (last != null &&
          content.substring(last.end, removal.start).trim().isEmpty) {
        merged[merged.length - 1] = _Edit(last.start, removal.end, '');
      } else {
        merged.add(removal);
      }
    }
    return merged;
  }

  List<_Edit> _tidy(List<_Edit> removals) => [
    for (final removal in removals) _tidyOne(removal),
  ];

  _Edit _tidyOne(_Edit removal) {
    var start = removal.start;
    var end = removal.end;
    final before = _lineBefore(start);
    final opensBlock = before.trimRight().endsWith('{');
    if ((before.trim().isEmpty || opensBlock) && _isBlankLineAt(end)) {
      end = content.indexOf('\n', end) + 1;
    }
    if (content.substring(end).trimLeft().startsWith('}')) {
      while (start > 0 && _lineBefore(start).trim().isEmpty) {
        start = content.lastIndexOf('\n', start - 2) + 1;
      }
    }
    return _Edit(start, end, '');
  }

  String _leadingComments(AnnotatedNode member) => content
      .substring(_leadingStart(member), _firstRealToken(member).offset)
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) => '$line\n')
      .join();

  int _leadingStart(AnnotatedNode member) {
    final first = _firstRealToken(member);
    final previousEnd = first.previous?.end ?? 0;
    final lineBreak = content.indexOf('\n', previousEnd);
    if (lineBreak < 0 || lineBreak >= member.offset) return member.offset;
    var start = lineBreak + 1;
    while (_isBlankLineAt(start) && start < member.offset) {
      start = content.indexOf('\n', start) + 1;
    }
    return start;
  }

  Token _firstRealToken(AnnotatedNode member) =>
      member.metadata.firstOrNull?.beginToken ??
      member.firstTokenAfterCommentAndMetadata;

  String _lineBefore(int lineStart) {
    if (lineStart < 2) return '';
    final start = content.lastIndexOf('\n', lineStart - 2) + 1;
    return content.substring(start, lineStart - 1);
  }

  bool _isBlankLineAt(int offset) {
    final lineEnd = content.indexOf('\n', offset);
    return lineEnd >= 0 && content.substring(offset, lineEnd).trim().isEmpty;
  }

  String _slice(int start, int end, List<_Edit> edits) {
    final sorted = [...edits]..sort((a, b) => b.start.compareTo(a.start));
    var result = content.substring(start, end);
    for (final edit in sorted) {
      result = result.replaceRange(
        edit.start - start,
        edit.end - start,
        edit.text,
      );
    }
    return result;
  }

  static bool _isEmptyBraces(String body) =>
      body.startsWith('{') &&
      body.endsWith('}') &&
      body.substring(1, body.length - 1).trim().isEmpty;
}
