import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// A utility to check if a Dart type or element matches a specific type.
///
/// This is a simplified replacement for `TypeChecker` from custom_lint_builder.
class TypeChecker {
  const TypeChecker.fromName(this._name, {required String packageName})
    : _packageName = packageName,
      _url = null,
      _checkers = null;

  const TypeChecker.fromUrl(String url)
    : _url = url,
      _name = null,
      _packageName = null,
      _checkers = null;

  const TypeChecker.any(this._checkers)
    : _name = null,
      _packageName = null,
      _url = null;

  final String? _name;
  final String? _packageName;
  final String? _url;
  final List<TypeChecker>? _checkers;

  /// Checks if [element] is exactly the type this checker represents.
  bool isExactly(Element element) {
    if (_checkers != null) {
      return _checkers.any((c) => c.isExactly(element));
    }

    if (_url != null) {
      return _matchesByUrl(element);
    }

    if (element is! InterfaceElement) return false;

    return element.name == _name && _isFromPackage(element);
  }

  /// Checks if [type] is exactly the type this checker represents.
  bool isExactlyType(DartType type) {
    if (_checkers != null) {
      return _checkers.any((c) => c.isExactlyType(type));
    }

    if (type is! InterfaceType) return false;
    return isExactly(type.element);
  }

  /// Checks if [element] is a subtype of the type this checker represents.
  bool isSuperOf(Element element) {
    if (_checkers != null) {
      return _checkers.any((c) => c.isSuperOf(element));
    }

    if (element is! InterfaceElement) return false;

    // Check the element itself
    if (isExactly(element)) return true;

    // Check all supertypes
    for (final supertype in element.allSupertypes) {
      if (isExactlyType(supertype)) return true;
    }

    return false;
  }

  /// Checks if [type] is assignable from the type this checker represents.
  bool isAssignableFromType(DartType type) {
    if (_checkers != null) {
      return _checkers.any((c) => c.isAssignableFromType(type));
    }

    if (type is! InterfaceType) return false;

    // Check the type itself
    if (isExactlyType(type)) return true;

    // Check all supertypes
    for (final supertype in type.element.allSupertypes) {
      if (isExactlyType(supertype)) return true;
    }

    return false;
  }

  bool _matchesByUrl(Element element) {
    if (_url == null) return false;
    if (element is! InterfaceElement) return false;

    // Parse URL like 'dart:core#Iterable' or 'package:flutter/widgets.dart#Widget'
    final parts = _url.split('#');
    if (parts.length != 2) return false;

    final expectedUri = parts[0];
    final expectedName = parts[1];

    if (element.name != expectedName) return false;

    final libraryUri = element.library.identifier;
    return libraryUri.startsWith(expectedUri);
  }

  bool _isFromPackage(InterfaceElement element) {
    if (_packageName == null) return false;

    final libraryUri = element.library.identifier;

    // Check for dart: libraries
    if (_packageName == 'dart') {
      return libraryUri.startsWith('dart:');
    }

    // Check for package: libraries
    return libraryUri.startsWith('package:$_packageName/');
  }
}
