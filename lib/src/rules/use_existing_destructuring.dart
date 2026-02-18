import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a property is accessed directly on an object that already has a
/// destructuring declaration in the same scope. The property should be added
/// to the existing destructuring instead.
///
/// ```dart
/// // Bad
/// final SomeClass(:value) = variable;
/// print(variable.another);
///
/// // Good
/// final SomeClass(:value, :another) = variable;
/// print(another);
/// ```
class UseExistingDestructuring extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_existing_destructuring',
    "Use existing destructuring of '{0}' instead of accessing '{1}' directly.",
    correctionMessage:
        "Add ':{1}' to the existing destructuring pattern and use '{1}' "
        'directly.',
  );

  UseExistingDestructuring()
    : super(
        name: 'use_existing_destructuring',
        description:
            'Warns when a property is accessed directly on an object that '
            'already has a destructuring declaration in the same scope.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addBlock(this, visitor);
  }
}

/// Info about a destructuring declaration in a block.
class _DestructuringInfo {
  /// The source expression name (the variable being destructured).
  final String sourceName;

  /// The element of the source expression (to match against property accesses).
  final Element? sourceElement;

  /// The field names already destructured.
  final Set<String> destructuredFields;

  /// The offset of the destructuring statement (to check ordering).
  final int statementOffset;

  _DestructuringInfo({
    required this.sourceName,
    required this.sourceElement,
    required this.destructuredFields,
    required this.statementOffset,
  });
}

class _Visitor extends SimpleAstVisitor<void> {
  final UseExistingDestructuring rule;

  _Visitor(this.rule);

  @override
  void visitBlock(Block node) {
    final destructurings = <_DestructuringInfo>[];

    for (final statement in node.statements) {
      // First, check property accesses in this statement against
      // already-collected destructurings
      if (destructurings.isNotEmpty) {
        final finder = _PropertyAccessFinder(destructurings);
        statement.accept(finder);
        for (final match in finder.matches) {
          rule.reportAtNode(
            match.accessNode,
            arguments: [match.sourceName, match.propertyName],
          );
        }
      }

      // Then, collect new destructuring declarations from this statement
      if (statement is PatternVariableDeclarationStatement) {
        final decl = statement.declaration;
        final info = _extractDestructuringInfo(decl, statement.offset);
        if (info != null) {
          destructurings.add(info);
        }
      }
    }
  }

  /// Extracts destructuring info from a PatternVariableDeclaration.
  static _DestructuringInfo? _extractDestructuringInfo(
    PatternVariableDeclaration decl,
    int statementOffset,
  ) {
    final pattern = decl.pattern;
    final expression = decl.expression;

    // Get the source variable name and element
    final String sourceName;
    final Element? sourceElement;

    if (expression is SimpleIdentifier) {
      sourceName = expression.name;
      sourceElement = expression.element;
    } else {
      // Only support simple identifier sources (not method calls, etc.)
      return null;
    }

    // Only handle local variables and parameters
    if (sourceElement is! LocalElement) return null;

    // Extract destructured field names
    final fields = <String>{};

    if (pattern is ObjectPattern) {
      for (final field in pattern.fields) {
        final name = field.effectiveName;
        if (name != null) fields.add(name);
      }
    } else if (pattern is RecordPattern) {
      for (final field in pattern.fields) {
        final name = field.effectiveName;
        if (name != null) fields.add(name);
      }
    } else {
      return null;
    }

    if (fields.isEmpty) return null;

    return _DestructuringInfo(
      sourceName: sourceName,
      sourceElement: sourceElement,
      destructuredFields: fields,
      statementOffset: statementOffset,
    );
  }
}

/// A match found by the property access finder.
class _PropertyAccessMatch {
  final AstNode accessNode;
  final String sourceName;
  final String propertyName;

  _PropertyAccessMatch({
    required this.accessNode,
    required this.sourceName,
    required this.propertyName,
  });
}

/// Finds property accesses on variables that have existing destructurings.
class _PropertyAccessFinder extends RecursiveAstVisitor<void> {
  final List<_DestructuringInfo> destructurings;
  final List<_PropertyAccessMatch> matches = [];

  _PropertyAccessFinder(this.destructurings);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_checkPropertyAccess(
      targetName: node.prefix.name,
      targetElement: node.prefix.element,
      propertyName: node.identifier.name,
      accessNode: node,
    )) {
      return; // Don't recurse into children if matched
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target is SimpleIdentifier) {
      if (_checkPropertyAccess(
        targetName: target.name,
        targetElement: target.element,
        propertyName: node.propertyName.name,
        accessNode: node,
      )) {
        return;
      }
    }
    super.visitPropertyAccess(node);
  }

  // Stop at nested function boundaries
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  /// Returns true if a match was found.
  bool _checkPropertyAccess({
    required String targetName,
    required Element? targetElement,
    required String propertyName,
    required AstNode accessNode,
  }) {
    // Skip if the parent is an assignment target (writing, not reading)
    final parent = accessNode.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == accessNode) {
      return false;
    }

    for (final info in destructurings) {
      // Match by element identity when possible, fall back to name
      final isMatch = targetElement != null
          ? targetElement == info.sourceElement
          : targetName == info.sourceName;

      if (!isMatch) continue;

      // Only flag if the property is NOT already destructured
      if (info.destructuredFields.contains(propertyName)) continue;

      matches.add(
        _PropertyAccessMatch(
          accessNode: accessNode,
          sourceName: info.sourceName,
          propertyName: propertyName,
        ),
      );
      return true;
    }
    return false;
  }
}
