import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class PrimaryConstructorCandidate {
  final CompilationUnitMember declaration;

  final ClassNamePart namePart;

  final NodeList<ClassMember> members;

  final ConstructorDeclaration constructor;

  final Map<FieldFormalParameter, FieldDeclaration> declaringFields;

  final bool isEnum;

  const PrimaryConstructorCandidate._({
    required this.declaration,
    required this.namePart,
    required this.members,
    required this.constructor,
    required this.declaringFields,
    required this.isEnum,
  });

  static PrimaryConstructorCandidate? tryRead(CompilationUnitMember node) {
    final unit = node.thisOrAncestorOfType<CompilationUnit>();
    if (unit == null ||
        !unit.featureSet.isEnabled(Feature.primary_constructors)) {
      return null;
    }

    final ClassNamePart namePart;
    final NodeList<ClassMember> members;
    var isMixinClass = false;
    switch (node) {
      case ClassDeclaration(
        body: BlockClassBody(members: final classMembers),
        augmentKeyword: null,
      ):
        namePart = node.namePart;
        members = classMembers;
        isMixinClass = node.mixinKeyword != null;
      case EnumDeclaration(
        body: BlockEnumBody(members: final enumMembers),
        augmentKeyword: null,
      ):
        namePart = node.namePart;
        members = enumMembers;
      default:
        return null;
    }

    // Edge case: the SDK's use_declaring_parameters owns already migrated classes
    if (namePart is PrimaryConstructorDeclaration) return null;

    final constructor = _soleNonRedirectingGenerative(members);
    if (constructor == null) return null;
    if (constructor.metadata.isNotEmpty) return null;
    if (constructor.externalKeyword != null) return null;
    if (constructor.augmentKeyword != null) return null;

    final body = constructor.body;
    if (body is! EmptyFunctionBody && body is! BlockFunctionBody) return null;
    if (body is BlockFunctionBody && body.keyword != null) return null;

    final parameters = constructor.parameters.parameters;
    if (isMixinClass &&
        (parameters.isNotEmpty ||
            constructor.initializers.isNotEmpty ||
            _hasBlockBody(constructor))) {
      return null;
    }

    // Edge case: a field initializer sees primary parameters, so a shared name changes meaning
    final parameterNames = {
      for (final parameter in parameters)
        if (parameter.name case final name?) name.lexeme,
    };
    if (_initializersReferToAny(members, parameterNames)) return null;

    final fieldsByName = <String, FieldDeclaration>{};
    for (final field in members.whereType<FieldDeclaration>()) {
      if (field.isStatic) continue;
      for (final variable in field.fields.variables) {
        fieldsByName[variable.name.lexeme] = field;
      }
    }

    final declaringFields = <FieldFormalParameter, FieldDeclaration>{};
    for (final parameter in parameters) {
      if (parameter is! FieldFormalParameter) continue;
      final field = fieldsByName[parameter.name.lexeme];
      if (field == null || !_canBecomeDeclaring(parameter, field)) return null;
      declaringFields[parameter] = field;
    }

    for (final field in declaringFields.values.toSet()) {
      final declared = declaringFields.values.where((f) => f == field).length;
      if (declared != field.fields.variables.length) return null;
    }

    return PrimaryConstructorCandidate._(
      declaration: node,
      namePart: namePart,
      members: members,
      constructor: constructor,
      declaringFields: declaringFields,
      isEnum: node is EnumDeclaration,
    );
  }

  bool get needsThisBlock =>
      constructor.initializers.isNotEmpty || _hasBlockBody(constructor);

  static ConstructorDeclaration? _soleNonRedirectingGenerative(
    NodeList<ClassMember> members,
  ) {
    ConstructorDeclaration? found;
    for (final constructor in members.whereType<ConstructorDeclaration>()) {
      if (constructor.factoryKeyword != null) continue;
      if (constructor.redirectedConstructor != null) continue;
      if (constructor.initializers.any(
        (i) => i is RedirectingConstructorInvocation,
      )) {
        continue;
      }
      if (found != null) return null;
      found = constructor;
    }
    return found;
  }

  static bool _canBecomeDeclaring(
    FieldFormalParameter parameter,
    FieldDeclaration field,
  ) {
    // Edge case: an explicit type on `this.x` may be narrower than the field type
    if (parameter.functionTypedSuffix != null) return false;
    if (parameter.type != null) return false;

    final list = field.fields;
    if (list.isLate || list.isConst) return false;
    if (field.externalKeyword != null || field.abstractKeyword != null) {
      return false;
    }
    if (field.covariantKeyword != null) return false;
    return list.variables.every((v) => v.initializer == null);
  }

  static bool _initializersReferToAny(
    NodeList<ClassMember> members,
    Set<String> names,
  ) {
    if (names.isEmpty) return false;
    final finder = _NameReferenceFinder(names);
    for (final field in members.whereType<FieldDeclaration>()) {
      if (field.isStatic || field.fields.isLate) continue;
      for (final variable in field.fields.variables) {
        variable.initializer?.accept(finder);
      }
    }
    return finder.found;
  }

  static bool _hasBlockBody(ConstructorDeclaration constructor) {
    final body = constructor.body;
    return body is BlockFunctionBody && !_isEmptyBlock(body.block);
  }

  static bool _isEmptyBlock(Block block) =>
      block.statements.isEmpty && block.rightBracket.precedingComments == null;
}

class _NameReferenceFinder extends RecursiveAstVisitor<void> {
  _NameReferenceFinder(this.names);

  final Set<String> names;
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!names.contains(node.name)) return;
    final parent = node.parent;
    final isMemberName = switch (parent) {
      PropertyAccess(:final propertyName) => propertyName == node,
      PrefixedIdentifier(:final identifier) => identifier == node,
      MethodInvocation(:final methodName, :final target) =>
        methodName == node && target != null,
      Label() => true,
      _ => false,
    };
    if (!isMemberName) found = true;
  }
}
