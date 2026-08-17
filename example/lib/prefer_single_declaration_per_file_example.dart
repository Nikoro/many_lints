// ignore_for_file: many_lints/avoid_bloc_public_methods
// ignore_for_file: unused_element
import 'package:bloc/bloc.dart';
import 'package:riverpod/riverpod.dart';

// prefer_single_declaration_per_file
//
// Warns when a file declares more than one top-level declaration.
//
// Unconfigured, classes, mixins, enums, extensions and extension types all
// count together and private declarations are skipped. The `groups:` option
// narrows the rule by base type and gives each group its own budget, which is
// how one rule covers "one bloc per file" and "one notifier per file" at once.
//
// This file is configured in `many_lints.yaml` with two groups — one for
// Bloc/Cubit, one for Notifier — so the counts below are independent.

// ✅ Good: the first bloc in the file is fine.
class CounterBloc extends Bloc<int, int> {
  CounterBloc() : super(0);
}

// LINT: a second Bloc lands in the same group as CounterBloc.
// The group's own `message:` is appended: "One bloc per file."
class SettingsBloc extends Bloc<String, String> {
  SettingsBloc() : super('');
}

// ✅ Good: a Notifier belongs to the *other* configured group, so it does not
// count against the blocs above. This is the whole point of `groups:` — a file
// holding one bloc and one notifier satisfies both budgets.
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

// LINT: a second Notifier does count against the notifier group.
// Appended message: "One notifier per file."
class SettingsNotifier extends Notifier<String> {
  @override
  String build() => '';
}

// ✅ Good: matched by no configured group, so it is never counted.
// With the default (unconfigured) rule this plain class *would* count, since
// no `types:` narrowing is in effect.
class CounterRepository {
  int load() => 0;
}

// ✅ Good: private declarations are skipped by default (`ignore_private`).
// They are invisible outside the file, so they cannot be what forces a reader
// to open it. Set `ignore_private: false` to count them too.
class _CounterCache {
  int? value;
}

// ✅ Good: top-level functions, variables and typedefs are not declarations
// this rule counts, whatever the configuration.
typedef CounterCallback = void Function(int value);

const initialCounter = 0;

void resetCounter() {}
// ignore_for_file: many_lints/prefer_getter_over_method
