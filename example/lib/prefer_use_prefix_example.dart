// ignore_for_file: unused_element, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// prefer_use_prefix
//
// Custom hooks (functions that call other hooks) should follow the
// naming convention of starting with the `use` prefix.
// This helps the hooks framework and other lint rules identify them.

// ❌ Bad: Top-level function calling hooks without 'use' prefix
String myCustomHook() {
  // LINT: Custom hooks should start with 'use' prefix.
  return useMemoized(() => 'hello');
}

// ❌ Bad: Private function calling hooks without '_use' prefix
int _myPrivateHook() {
  // LINT: Custom hooks should start with 'use' prefix.
  return useState(0);
}

// ❌ Bad: Method in HookWidget calling hooks without 'use' prefix
class BadWidget extends HookWidget {
  const BadWidget({super.key});

  int _fetchData() {
    // LINT: Custom hooks should start with 'use' prefix.
    return useState(42);
  }

  @override
  Widget build(BuildContext context) {
    final data = _fetchData();
    return Text('$data');
  }
}

// ✅ Good: Top-level function with 'use' prefix
String useCustomHook() {
  return useMemoized(() => 'hello');
}

// ✅ Good: Private function with '_use' prefix
int _usePrivateHook() {
  return useState(0);
}

// ✅ Good: Method in HookWidget with 'use' prefix
class GoodWidget extends HookWidget {
  const GoodWidget({super.key});

  int _useData() {
    return useState(42);
  }

  @override
  Widget build(BuildContext context) {
    final data = _useData();
    return Text('$data');
  }
}

// ✅ Good: Regular function that doesn't call hooks — no prefix needed
int regularFunction() {
  return 42;
}

// ✅ Good: build method in HookWidget — standard widget method, not a custom hook
class NormalWidget extends HookWidget {
  const NormalWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final value = useState(0);
    return Text('$value');
  }
}
