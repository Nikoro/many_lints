// ignore_for_file: implementation_imports
import 'package:analysis_server_plugin/src/registry.dart';
import 'package:many_lints/many_lints.dart';
import 'package:test/test.dart';

void main() {
  late ManyLintsPlugin plugin;
  late PluginRegistryImpl registry;

  setUp(() {
    plugin = ManyLintsPlugin();
    registry = PluginRegistryImpl('many_lints');
  });

  test('plugin has correct name', () {
    expect(plugin.name, 'Many Lints');
  });

  test('register() completes without error', () {
    expect(() => plugin.register(registry), returnsNormally);
  });

  test('all rule names are unique', () {
    plugin.register(registry);

    final allNames = [
      ...registry.warningRules.keys,
      ...registry.lintRules.keys,
    ];

    final duplicates = <String>[];
    final seen = <String>{};
    for (final name in allNames) {
      if (!seen.add(name)) {
        duplicates.add(name);
      }
    }

    expect(duplicates, isEmpty, reason: 'Duplicate rule names: $duplicates');
  });

  test('expected number of rules are registered', () {
    plugin.register(registry);
    final totalRules = registry.warningRules.length + registry.lintRules.length;
    expect(
      totalRules,
      greaterThanOrEqualTo(90),
      reason: 'Expected at least 90 rules, got $totalRules',
    );
  });

  test('fixes are registered', () {
    plugin.register(registry);
    final totalFixes = registry.fixKinds.values.fold<int>(
      0,
      (sum, v) => sum + v.length,
    );
    expect(
      totalFixes,
      greaterThanOrEqualTo(60),
      reason: 'Expected at least 60 fixes, got $totalFixes',
    );
  });

  test('assists are registered', () {
    plugin.register(registry);
    expect(registry.assistKinds.length, greaterThanOrEqualTo(1));
  });
}
