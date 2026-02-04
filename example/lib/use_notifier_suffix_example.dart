import 'package:riverpod/riverpod.dart';

// use_notifier_suffix
//
// Classes extending Notifier should have the 'Notifier' suffix.

// LINT: Missing 'Notifier' suffix
class CounterManager extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}
