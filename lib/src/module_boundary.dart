import 'package:analyzer/file_system/file_system.dart';

import 'rule_config.dart';

class ModuleBoundary {
  const ModuleBoundary(this.directory, this.entryPoint);

  final String directory;
  final String entryPoint;

  static ModuleBoundary? forPath(String path, RuleConfig config) {
    final configured = [
      for (final root in config.stringListOption('module_roots'))
        if (_normalize(root) case final normalized when normalized.isNotEmpty)
          normalized,
    ];
    final roots = configured.isEmpty ? ['lib'] : configured;
    final matches = roots.where((root) => path.startsWith('$root/')).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final root in matches) {
      final segments = path.substring(root.length + 1).split('/');
      // Edge case: `src` below a root is pub's private implementation
      // directory, not a feature module.
      if (segments.length < 2 || segments.first == 'src') return null;
      final directory = '$root/${segments.first}';
      return ModuleBoundary(directory, '$directory/${segments.first}.dart');
    }
    return null;
  }

  static String _normalize(String root) {
    var normalized = root.replaceAll(r'\', '/');
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static String? relativeTo(Folder root, String path) {
    final context = root.provider.pathContext;
    if (!context.isWithin(root.path, path)) return null;
    return context.split(context.relative(path, from: root.path)).join('/');
  }

  static bool isGenerated(String path) =>
      path.contains('/generated/') ||
      const [
        '.g.dart',
        '.freezed.dart',
        '.gr.dart',
        '.drift.dart',
        '.gen.dart',
        '.config.dart',
        '.mocks.dart',
        '.pb.dart',
      ].any(path.endsWith);
}
