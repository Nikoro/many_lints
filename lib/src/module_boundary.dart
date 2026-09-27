import 'package:analyzer/file_system/file_system.dart';

import 'rule_config.dart';

class ModuleBoundary {
  const ModuleBoundary(this.directory, this.entryPoint);

  final String directory;
  final String entryPoint;

  static ModuleBoundary? forPath(String path, RuleConfig config) {
    final configured = config.stringListOption('module_roots');
    final roots = configured.isEmpty ? ['lib'] : configured;
    final matches = roots.where((root) => path.startsWith('$root/')).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final root in matches) {
      final segments = path.substring(root.length + 1).split('/');
      if (segments.length < 2) return null;
      final directory = '$root/${segments.first}';
      return ModuleBoundary(directory, '$directory/${segments.first}.dart');
    }
    return null;
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
