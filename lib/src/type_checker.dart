import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

class TypeChecker {
  const TypeChecker.fromName(this._name, {String? packageName})
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

  bool isExactlyType(DartType type) {
    if (_checkers != null) {
      return _checkers.any((c) => c.isExactlyType(type));
    }

    if (type is! InterfaceType) return false;
    return isExactly(type.element);
  }

  bool isSuperOf(Element element) {
    if (_checkers != null) {
      return _checkers.any((c) => c.isSuperOf(element));
    }

    if (element is! InterfaceElement) return false;

    if (isExactly(element)) return true;

    for (final supertype in element.allSupertypes) {
      if (isExactlyType(supertype)) return true;
    }

    return false;
  }

  bool isAssignableFromType(DartType type) {
    if (_checkers != null) {
      return _checkers.any((c) => c.isAssignableFromType(type));
    }

    if (type is! InterfaceType) return false;

    if (isExactlyType(type)) return true;

    for (final supertype in type.element.allSupertypes) {
      if (isExactlyType(supertype)) return true;
    }

    return false;
  }

  bool _matchesByUrl(Element element) {
    if (_url == null) return false;
    if (element is! InterfaceElement) return false;

    final hashIndex = _url.indexOf('#');
    if (hashIndex < 0 || hashIndex == _url.length - 1) return false;

    final expectedUri = _url.substring(0, hashIndex);
    final expectedName = _url.substring(hashIndex + 1);

    if (element.name != expectedName) return false;

    final libraryUri = element.library.identifier;
    return libraryUri.startsWith(expectedUri);
  }

  bool _isFromPackage(InterfaceElement element) {
    // Edge case: the analyzed package itself has no `package:` URI to match
    if (_packageName == null) return true;

    final libraryUri = element.library.identifier;

    if (_packageName == 'dart') {
      return libraryUri.startsWith('dart:');
    }

    return libraryUri.startsWith('package:$_packageName/');
  }
}
