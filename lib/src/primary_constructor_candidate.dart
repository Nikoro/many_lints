import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// A class or enum whose one generative constructor can move into the type
/// header as a Dart 3.13 primary constructor.
///
/// Shared by `prefer_primary_constructors` and its fix so the two cannot
/// disagree about what is convertible: the rule reports exactly the
/// declarations the fix knows how to rewrite.
///
/// Unlike the SDK's `use_primary_constructors`, a type that declares **no**
/// constructor is never a candidate. Converting one only adds an empty `()`
/// to the header (`enum Sport() {`, `abstract interface class Gateway() {`),
/// which says nothing a reader did not already know.
class PrimaryConstructorCandidate {
  /// The class or enum declaration.
  final CompilationUnitMember declaration;

  /// The plain name part (`Point<T>`) that becomes the primary constructor.
  final ClassNamePart namePart;

  /// The members of the declaration body.
  final NodeList<ClassMember> members;

  /// The constructor that moves into the header.
  final ConstructorDeclaration constructor;

  /// Every `this.x` parameter of [constructor], mapped to the field it
  /// initializes. Each becomes a declaring parameter and its field goes away.
  final Map<FieldFormalParameter, FieldDeclaration> declaringFields;

  /// Whether [declaration] is an enum, whose constructor is implicitly
  /// `const` and must not spell it in the header.
  final bool isEnum;

  const PrimaryConstructorCandidate._({
    required this.declaration,
    required this.namePart,
    required this.members,
    required this.constructor,
    required this.declaringFields,
    required this.isEnum,
  });

  /// Reads [node] as a convertible class or enum, or returns `null`.
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

    // Already migrated. The SDK's `use_declaring_parameters` owns that case.
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

    // A declaration of several fields moves only when the constructor
    // declares every one of them; splitting it is a bigger edit than this.
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

  /// Whether the constructor keeps work to do after its parameters moved: an
  /// initializer list or a non-empty body, which live on in a `this` block.
  bool get needsThisBlock =>
      constructor.initializers.isNotEmpty || _hasBlockBody(constructor);

  /// The only generative constructor that does not redirect, when every other
  /// constructor is a factory or redirects. Beside a primary constructor any
  /// second generative constructor must redirect, so two real ones cannot
  /// convert.
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
    // `this.cb(int)` has no declaring-parameter spelling, and an explicit type
    // on `this.x` may be narrower than the field's, so moving it changes the
    // field's type.
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

  static bool _hasBlockBody(ConstructorDeclaration constructor) {
    final body = constructor.body;
    return body is BlockFunctionBody && !_isEmptyBlock(body.block);
  }

  static bool _isEmptyBlock(Block block) =>
      block.statements.isEmpty && block.rightBracket.precedingComments == null;
}
