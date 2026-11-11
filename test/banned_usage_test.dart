import 'package:many_lints/src/rule_config.dart';
import 'package:many_lints/src/rules/banned_usage.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'many_lints_rule_test_base.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(BannedUsageTest));
}

/// Member-level coverage for `banned_usage`: every syntactic way of referring
/// to a banned member is reported exactly once, and nothing that merely shares
/// its name is.
///
/// Config resolution and `in:` scoping run end-to-end through a real
/// `PluginServer` in `banned_rules_config_test.dart`; this file pins the
/// reported ranges.
@reflectiveTest
class BannedUsageTest extends ManyLintsRuleTest {
  /// A library declaring one member of every kind, imported by each test.
  static const _clock = r'''
class Clock {
  Clock();
  Clock.system();
  factory Clock.fixed() = Clock.system;

  static Clock now() => Clock();
  static Clock get current => Clock();
  static Clock instance = Clock();

  Clock tick() => this;
}

class Box<T> {
  Box.of(T value);
}

extension ClockMaker on Clock {
  static Clock make() => Clock();
}

Clock systemClock = Clock();

Clock makeClock() => Clock();
''';

  @override
  void setUp() {
    rule = BannedUsage();
    super.setUp();
    newFile('$testPackageLibPath/clock.dart', _clock);
  }

  void _deny(List<String> members) {
    ConfigLoader.clearCache();
    newFile('$testPackageRootPath/${ConfigLoader.fileName}', '''
rules:
  banned_usage:
    banned:
      - deny: [${members.map((m) => "'$m'").join(', ')}]
''');
  }

  /// Writes [banned] as the rule's `banned:` list, verbatim YAML.
  void _configure(String banned) {
    ConfigLoader.clearCache();
    newFile('$testPackageRootPath/${ConfigLoader.fileName}', '''
rules:
  banned_usage:
    banned:
$banned''');
  }

  /// Asserts one diagnostic over each `(needle, occurrence)` in [code]: the
  /// occurrence-th match of the needle, counting from zero.
  Future<void> _expectAt(String code, List<(String, int)> needles) {
    final expected = [
      for (final (needle, occurrence) in needles)
        lint(_offsetOf(code, needle, occurrence), needle.length),
    ];
    return assertDiagnostics(code, expected);
  }

  /// Asserts one diagnostic over the first match of each needle in [code].
  Future<void> _expect(String code, List<String> needles) =>
      _expectAt(code, [for (final needle in needles) (needle, 0)]);

  int _offsetOf(String code, String needle, int occurrence) {
    var offset = -1;
    for (var i = 0; i <= occurrence; i++) {
      offset = code.indexOf(needle, offset + 1);
      if (offset < 0) throw ArgumentError('`$needle` #$occurrence not found');
    }
    return offset;
  }

  // ---- Silent until configured ----

  Future<void> test_silentWithoutConfiguration() async {
    await assertNoDiagnostics('''
import 'clock.dart';

Clock f() => Clock.now();
''');
  }

  // ---- Invocations ----

  Future<void> test_staticMethodInvocation() async {
    _deny(['Clock.now']);
    await _expect(
      '''
import 'clock.dart';

Clock f() => Clock.now();
''',
      ['now'],
    );
  }

  Future<void> test_namedConstructorInvocation() async {
    _deny(['Clock.system']);
    await _expect(
      '''
import 'clock.dart';

Clock f() => Clock.system();
''',
      ['Clock.system'],
    );
  }

  Future<void> test_unnamedConstructorInvocation() async {
    _deny(['Clock.new']);
    const code = '''
import 'clock.dart';

Clock f() => Clock();
Clock g() => Clock.new();
''';
    await _expectAt(code, [('Clock', 1), ('Clock.new', 0)]);
  }

  Future<void> test_sdkConstructorInvocation() async {
    _deny(['DateTime.now']);
    await _expect(
      '''
DateTime f() => DateTime.now();
''',
      ['DateTime.now'],
    );
  }

  // ---- Tear-offs ----

  Future<void> test_namedConstructorTearOff() async {
    _deny(['Clock.system']);
    await _expect(
      '''
import 'clock.dart';

final Clock Function() f = Clock.system;
''',
      ['Clock.system'],
    );
  }

  Future<void> test_unnamedConstructorTearOff() async {
    _deny(['Clock.new']);
    await _expect(
      '''
import 'clock.dart';

final Clock Function() f = Clock.new;
''',
      ['Clock.new'],
    );
  }

  Future<void> test_genericConstructorTearOff() async {
    _deny(['Box.of']);
    await _expect(
      '''
import 'clock.dart';

final Box<int> Function(int) f = Box<int>.of;
''',
      ['Box<int>.of'],
    );
  }

  Future<void> test_sdkConstructorTearOffAsArgument() async {
    _deny(['DateTime.now']);
    await _expect(
      '''
void run({required DateTime Function() now}) {}

void f() => run(now: DateTime.now);
''',
      ['DateTime.now'],
    );
  }

  Future<void> test_staticMethodTearOff() async {
    _deny(['Clock.now']);
    await _expect(
      '''
import 'clock.dart';

final Clock Function() f = Clock.now;
''',
      ['now'],
    );
  }

  Future<void> test_staticGetterRead() async {
    _deny(['Clock.current']);
    await _expect(
      '''
import 'clock.dart';

Clock f() => Clock.current;
''',
      ['current'],
    );
  }

  // ---- Dot shorthands ----

  Future<void> test_shorthandStaticMethod() async {
    _deny(['Clock.now']);
    await _expect(
      '''
import 'clock.dart';

Clock f() => .now();
''',
      ['now'],
    );
  }

  Future<void> test_shorthandNamedConstructor() async {
    _deny(['Clock.system']);
    await _expect(
      '''
import 'clock.dart';

Clock f() => .system();
''',
      ['system'],
    );
  }

  Future<void> test_shorthandUnnamedConstructor() async {
    _deny(['Clock.new']);
    await _expect(
      '''
import 'clock.dart';

Clock f() => .new();
''',
      ['new'],
    );
  }

  Future<void> test_shorthandStaticGetter() async {
    _deny(['Clock.current']);
    await _expect(
      '''
import 'clock.dart';

Clock f() => .current;
''',
      ['current'],
    );
  }

  Future<void> test_shorthandSdkConstructor() async {
    _deny(['DateTime.now']);
    await _expect(
      '''
DateTime f() => .now();
''',
      ['now'],
    );
  }

  // ---- Import prefixes ----

  Future<void> test_prefixedStaticMethodInvocation() async {
    _deny(['Clock.now']);
    await _expect(
      '''
import 'clock.dart' as c;

c.Clock f() => c.Clock.now();
''',
      ['now'],
    );
  }

  Future<void> test_prefixedConstructorInvocation() async {
    _deny(['Clock.system', 'Clock.new']);
    const code = '''
import 'clock.dart' as c;

c.Clock f() => c.Clock.system();
c.Clock g() => c.Clock();
''';
    await _expectAt(code, [('c.Clock.system', 0), ('c.Clock', 3)]);
  }

  Future<void> test_prefixedConstructorTearOffs() async {
    _deny(['Clock.system', 'Clock.new']);
    await _expect(
      '''
import 'clock.dart' as c;

final c.Clock Function() f = c.Clock.system;
final c.Clock Function() g = c.Clock.new;
''',
      ['c.Clock.system', 'c.Clock.new'],
    );
  }

  Future<void> test_prefixedStaticTearOffAndGetter() async {
    _deny(['Clock.now', 'Clock.current']);
    await _expect(
      '''
import 'clock.dart' as c;

final c.Clock Function() f = c.Clock.now;
c.Clock g() => c.Clock.current;
''',
      ['now', 'current'],
    );
  }

  Future<void> test_prefixedSdkTearOff() async {
    _deny(['DateTime.now']);
    await _expect(
      '''
import 'dart:core' as core;

final core.DateTime Function() f = core.DateTime.now;
''',
      ['core.DateTime.now'],
    );
  }

  // ---- Unqualified references inside the declaring class ----

  Future<void> test_unqualifiedStaticMembersInsideTheirClass() async {
    _deny(['Holder.now', 'Holder.current']);
    const code = '''
class Holder {
  static int now() => 0;
  static int get current => 0;

  int a() => now();
  int b() => current;
  int Function() c() => now;
}
''';
    await _expectAt(code, [('now', 1), ('current', 1), ('now', 2)]);
  }

  // ---- Constructor redirection ----

  Future<void> test_redirectingFactoryTarget() async {
    _deny(['Impl.create']);
    await _expect(
      '''
class Base {
  Base();
  factory Base.make() = Impl.create;
}

class Impl extends Base {
  Impl.create();
}
''',
      ['Impl.create'],
    );
  }

  Future<void> test_superConstructorInvocation() async {
    _deny(['Clock.system']);
    await _expect(
      '''
import 'clock.dart';

class Fake extends Clock {
  Fake() : super.system();
}
''',
      ['system'],
    );
  }

  Future<void> test_redirectingGenerativeConstructor() async {
    _deny(['Point.origin', 'Point.new']);
    const code = '''
class Point {
  Point();
  Point.origin();
  Point.zero() : this.origin();
  Point.base() : this();
}
''';
    await _expectAt(code, [('origin', 1), ('this()', 0)]);
  }

  Future<void> test_unnamedSuperConstructorInvocation() async {
    _deny(['Clock.new']);
    await _expect(
      '''
import 'clock.dart';

class Fake extends Clock {
  Fake() : super();
}
''',
      ['super()'],
    );
  }

  // ---- Top-level and extension members ----

  Future<void> test_topLevelVariableAndFunctionByBareName() async {
    _deny(['systemClock', 'makeClock']);
    const code = '''
import 'clock.dart';

Clock a() => systemClock;
Clock b() => makeClock();
final Clock Function() c = makeClock;
''';
    await _expectAt(code, [
      ('systemClock', 0),
      ('makeClock', 0),
      ('makeClock', 1),
    ]);
  }

  Future<void> test_assignmentThroughASetter() async {
    _deny(['Clock.instance', 'systemClock']);
    await _expect(
      '''
import 'clock.dart';

void f() {
  Clock.instance = Clock();
  systemClock = Clock();
}
''',
      ['instance', 'systemClock'],
    );
  }

  Future<void> test_incrementThroughASetter() async {
    _deny(['Counter.count']);
    const code = '''
class Counter {
  static int count = 0;
}

void f() {
  Counter.count++;
}
''';
    await _expectAt(code, [('count', 1)]);
  }

  Future<void> test_extensionStaticMember() async {
    _deny(['ClockMaker.make']);
    await _expect(
      '''
import 'clock.dart';

Clock f() => ClockMaker.make();
''',
      ['make'],
    );
  }

  // ---- Library-qualified entries ----

  Future<void> test_libraryQualifiedTopLevelDeclarations() async {
    _deny([
      'package:test/clock.dart#systemClock',
      'package:test/clock.dart#makeClock',
    ]);
    const code = '''
import 'clock.dart';

Clock a() => systemClock;
Clock b() => makeClock();
final Clock Function() c = makeClock;
''';
    await _expectAt(code, [
      ('systemClock', 0),
      ('makeClock', 0),
      ('makeClock', 1),
    ]);
  }

  Future<void> test_libraryQualifiedTopLevelThroughAnImportPrefix() async {
    _deny(['package:test/clock.dart#systemClock']);
    const code = '''
import 'clock.dart' as c;

c.Clock a() => c.systemClock;
''';
    await _expectAt(code, [('systemClock', 0)]);
  }

  Future<void> test_libraryQualifiedEntryIgnoresAnotherLibrarysName() async {
    // The point of the qualified form: a same-named declaration elsewhere,
    // here a local top-level function and a static member, stays allowed.
    _deny([
      'package:test/clock.dart#makeClock',
      'package:test/other.dart#systemClock',
    ]);
    await assertNoDiagnostics('''
import 'clock.dart';

class Factory {
  static Clock makeClock() => Clock.system();
}

Clock a() => systemClock;
Clock b() => Factory.makeClock();
''');
  }

  Future<void> test_libraryQualifiedMember() async {
    _deny([
      'package:test/clock.dart#Clock.now',
      'package:test/x.dart#Clock.system',
    ]);
    const code = '''
import 'clock.dart';

Clock f() => Clock.now();
Clock g() => Clock.system();
''';
    await _expectAt(code, [('now', 0)]);
  }

  Future<void> test_libraryQualifiedMemberOfASupertype() async {
    _deny(['dart:core#Iterable.first']);
    await _expect(
      '''
int f(List<int> values) => values.first;
''',
      ['first'],
    );
  }

  Future<void> test_denyPatternIsNotTriedAgainstTheLibrarySpelling() async {
    // A pattern written before library spellings existed must keep matching
    // exactly what it matched then.
    _configure('''
      - deny_pattern: ['package:.*', '.*#.*']
''');
    await assertNoDiagnostics('''
import 'clock.dart';

Clock f() => makeClock();
''');
  }

  // ---- Per-entry exceptions ----

  Future<void> test_exceptLiftsOnlyItsOwnEntry() async {
    // The test file is lib/test.dart: excepted from the first entry, still
    // covered by the second.
    _configure('''
      - deny: ['Clock.now']
        in: ['lib/**']
        except: ['lib/test.dart']
      - deny: ['makeClock']
        in: ['lib/**']
''');
    const code = '''
import 'clock.dart';

Clock f() => Clock.now();
Clock g() => makeClock();
''';
    await _expectAt(code, [('makeClock', 0)]);
  }

  Future<void> test_exceptElsewhereStillReports() async {
    _configure('''
      - deny: ['package:test/clock.dart#systemClock']
        in: ['lib/**']
        except: ['lib/clock.dart', 'lib/main.dart']
''');
    await _expect(
      '''
import 'clock.dart';

Clock f() => systemClock;
''',
      ['systemClock'],
    );
  }

  // ---- Not banned ----

  Future<void> test_instanceMemberWithTheSameNameOnAnotherType() async {
    _deny(['Clock.now', 'DateTime.now']);
    await assertNoDiagnostics('''
class Other {
  int now() => 0;
  static int current() => 0;
}

int f(Other o) => o.now();
int Function() g(Other o) => o.now;
''');
  }

  Future<void> test_localFunctionNamedLikeTheMember() async {
    _deny(['Clock.now', 'now']);
    await assertNoDiagnostics('''
int f() {
  int now() => 0;
  final g = now;
  return now() + g();
}
''');
  }

  Future<void> test_parameterAndNamedArgumentNamedLikeTheMember() async {
    _deny(['now']);
    await assertNoDiagnostics('''
void run({required int now}) => print(now);

void f() => run(now: 1);
''');
  }

  Future<void> test_docCommentReference() async {
    _deny(['Clock.now', 'Clock.system']);
    await assertNoDiagnostics('''
import 'clock.dart';

/// Unlike [Clock.now] or [Clock.system], this takes a seed.
int f() => 0;
''');
  }

  Future<void> test_showCombinatorIsNotAUse() async {
    _deny(['systemClock']);
    const code = '''
import 'clock.dart' show systemClock;

Object f() => systemClock;
''';
    await _expectAt(code, [('systemClock', 1)]);
  }

  Future<void> test_otherMembersOfTheBannedType() async {
    _deny(['Clock.now']);
    await assertNoDiagnostics('''
import 'clock.dart';

Clock f(Clock c) => Clock.system().tick();
Clock g() => .system();
''');
  }
}
