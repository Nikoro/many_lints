import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../many_lints_rule.dart';

/// Warns when a map literal keyed by an enum omits some of its constants.
///
/// A map from an enum is almost always meant to be a total lookup table.
/// When a constant is missing, `map[value]` silently returns `null` instead
/// of failing, so the gap surfaces as a null-check crash or a blank UI far
/// from the map itself.
///
/// Unlike a `switch`, the compiler performs no exhaustiveness check here,
/// so adding a new enum constant later leaves every such map quietly
/// incomplete.
class AvoidMissingEnumConstantInMap extends ManyLintsRule {
  static const LintCode code = LintCode(
    'avoid_missing_enum_constant_in_map',
    "This map is missing the enum constant(s): {0}.",
    correctionMessage:
        'Add the missing entries, since a lookup for them returns null '
        'rather than failing where the gap was introduced.',
  );

  AvoidMissingEnumConstantInMap()
    : super(
        name: 'avoid_missing_enum_constant_in_map',
        description:
            'Warns when a map literal keyed by an enum does not cover every '
            'constant of that enum.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerManyLintsProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addSetOrMapLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidMissingEnumConstantInMap rule;

  _Visitor(this.rule);

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (!node.isMap) return;

    // An empty map is a deliberate starting point, not an oversight.
    if (node.elements.isEmpty) return;

    final keyType = _mapKeyType(node);
    if (keyType is! InterfaceType) return;

    final enumElement = keyType.element;
    if (enumElement is! EnumElement) return;

    final allConstants = enumElement.constants
        .map((constant) => constant.name)
        .nonNulls
        .toSet();
    if (allConstants.isEmpty) return;

    final presentKeys = <String>{};
    for (final element in node.elements) {
      // Any non-literal entry (a spread, an `if`, a computed key) means the
      // contents cannot be enumerated statically — stay silent.
      if (element is! MapLiteralEntry) return;

      final name = _enumConstantName(element.key, enumElement);
      if (name == null) return;
      presentKeys.add(name);
    }

    final missing = allConstants.difference(presentKeys);
    if (missing.isEmpty) return;

    final sorted = missing.toList()..sort();
    rule.reportAtNode(node, arguments: [sorted.join(', ')]);
  }

  /// Resolves the map's key type, preferring an explicit type argument and
  /// falling back to the inferred static type.
  DartType? _mapKeyType(SetOrMapLiteral node) {
    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments != null && typeArguments.length == 2) {
      return typeArguments.first.type;
    }

    final staticType = node.staticType;
    if (staticType is InterfaceType && staticType.typeArguments.length == 2) {
      return staticType.typeArguments.first;
    }
    return null;
  }

  /// Returns the constant name if [key] names a constant of [enumElement].
  String? _enumConstantName(Expression key, EnumElement enumElement) {
    final element = switch (key) {
      PrefixedIdentifier(:final identifier) => identifier.element,
      PropertyAccess(:final propertyName) => propertyName.element,
      SimpleIdentifier(:final element) => element,
      _ => null,
    };

    if (element is! GetterElement) return null;
    final variable = element.variable;
    if (variable is! FieldElement) return null;
    if (variable.enclosingElement != enumElement) return null;

    return variable.name;
  }
}
