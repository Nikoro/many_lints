import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AvoidGenericsShadowingFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'many_lints.fix.avoidGenericsShadowing',
    DartFixKindPriority.standard,
    'Rename type parameter',
  );

  AvoidGenericsShadowingFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! TypeParameter) return;

    final typeParamList = targetNode.parent;
    if (typeParamList is! TypeParameterList) return;

    final usedNames = <String>{
      for (final tp in typeParamList.typeParameters) tp.name.lexeme,
    };

    final scope = _findDeclaringScope(targetNode);
    if (scope != null) {
      final scopeNames = _collectNamedTypes(scope);
      usedNames.addAll(scopeNames);
    }

    final unit = targetNode.thisOrAncestorOfType<CompilationUnit>();
    if (unit != null) {
      for (final declaration in unit.declarations) {
        final declName = switch (declaration) {
          ClassDeclaration(:final namePart) => namePart.typeName.lexeme,
          MixinDeclaration(:final name) => name.lexeme,
          EnumDeclaration(:final namePart) => namePart.typeName.lexeme,
          GenericTypeAlias(:final name) => name.lexeme,
          FunctionTypeAlias(:final name) => name.lexeme,
          FunctionDeclaration(:final name) => name.lexeme,
          TopLevelVariableDeclaration(:final variables) =>
            variables.variables.firstOrNull?.name.lexeme,
          _ => null,
        };
        if (declName != null) usedNames.add(declName);
      }
    }

    final candidates = ['T', 'R', 'E', 'S', 'U', 'V', 'W'];
    final replacement = candidates.firstWhere(
      (c) => !usedNames.contains(c),
      orElse: () {
        for (var i = 0; ; i++) {
          final name = 'T$i';
          if (!usedNames.contains(name)) return name;
        }
      },
    );

    final oldName = targetNode.name.lexeme;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(targetNode.name.offset, targetNode.name.length),
        replacement,
      );

      final scope = _findDeclaringScope(targetNode);
      if (scope != null) {
        final usages = _findUsages(scope, oldName);
        for (final token in usages) {
          builder.addSimpleReplacement(
            SourceRange(token.offset, token.length),
            replacement,
          );
        }
      }
    });
  }

  Set<String> _collectNamedTypes(AstNode scope) {
    final names = <String>{};
    final visitor = _NamedTypeCollector(names);
    scope.visitChildren(visitor);
    return names;
  }

  AstNode? _findDeclaringScope(TypeParameter typeParam) {
    for (
      AstNode? current = typeParam.parent;
      current != null;
      current = current.parent
    ) {
      if (current is ClassDeclaration ||
          current is MixinDeclaration ||
          current is EnumDeclaration ||
          current is ExtensionTypeDeclaration ||
          current is MethodDeclaration ||
          current is FunctionDeclaration ||
          current is GenericTypeAlias ||
          current is FunctionTypeAlias) {
        return current;
      }
    }
    return null;
  }

  List<Token> _findUsages(AstNode scope, String name) {
    final usages = <Token>[];
    final visitor = _UsageFinder(name, usages);
    scope.visitChildren(visitor);
    return usages;
  }
}

class _UsageFinder extends RecursiveAstVisitor<void> {
  final String name;
  final List<Token> usages;

  _UsageFinder(this.name, this.usages);

  @override
  void visitNamedType(NamedType node) {
    if (node.name.lexeme == name && node.importPrefix == null) {
      usages.add(node.name);
    }
    super.visitNamedType(node);
  }
}

class _NamedTypeCollector extends RecursiveAstVisitor<void> {
  final Set<String> names;

  _NamedTypeCollector(this.names);

  @override
  void visitNamedType(NamedType node) {
    if (node.importPrefix == null) {
      names.add(node.name.lexeme);
    }
    super.visitNamedType(node);
  }
}
