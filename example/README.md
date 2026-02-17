# many_lints Examples

This directory contains example code demonstrating each lint rule provided by `many_lints`.

## Setup

Add to your `analysis_options.yaml`:

```yaml
plugins:
  many_lints: ^0.3.0
```

## Rules

### avoid_single_child_in_multi_child_widgets

Multi-child widgets like `Column`, `Row`, `Wrap` should not be used with only a single child.

❌ **Bad:**
```dart
Column(
  children: [Text('Only child')],
)
```

✅ **Good:**
```dart
Text('Only child')
```

---

### avoid_unnecessary_consumer_widgets

`ConsumerWidget` should only be used when the `WidgetRef` is actually used.

❌ **Bad:**
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref is never used
    return Text('Hello');
  }
}
```

✅ **Good:**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello');
  }
}
```

---

### avoid_unnecessary_hook_widgets

`HookWidget` should only be used when hooks are actually called.

❌ **Bad:**
```dart
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // No hooks called
    return Text('Hello');
  }
}
```

✅ **Good:**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello');
  }
}
```

---

### prefer_align_over_container

Use `Align` widget instead of `Container` when only alignment is set.

❌ **Bad:**
```dart
Container(
  alignment: Alignment.topLeft,
  child: Text('Hello'),
)
```

✅ **Good:**
```dart
Align(
  alignment: Alignment.topLeft,
  child: Text('Hello'),
)
```

---

### prefer_any_or_every

Use `.any()` instead of `.where().isNotEmpty` and `.every()` instead of `.where().isEmpty`.

❌ **Bad:**
```dart
final hasEven = numbers.where((n) => n.isEven).isNotEmpty;
final allPositive = numbers.where((n) => n < 0).isEmpty;
```

✅ **Good:**
```dart
final hasEven = numbers.any((n) => n.isEven);
final allPositive = numbers.every((n) => n >= 0);
```

---

### prefer_center_over_align

Use `Center` widget instead of `Align` when alignment is center.

❌ **Bad:**
```dart
Align(
  alignment: Alignment.center,
  child: Text('Hello'),
)
```

✅ **Good:**
```dart
Center(
  child: Text('Hello'),
)
```

---

### prefer_padding_over_container

Use `Padding` widget instead of `Container` when only margin is set.

❌ **Bad:**
```dart
Container(
  margin: EdgeInsets.all(16),
  child: Text('Hello'),
)
```

✅ **Good:**
```dart
Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
)
```

---

### use_bloc_suffix

Classes extending `Bloc` should have the `Bloc` suffix.

❌ **Bad:**
```dart
class CounterManager extends Bloc<CounterEvent, int> {}
```

✅ **Good:**
```dart
class CounterBloc extends Bloc<CounterEvent, int> {}
```

---

### use_cubit_suffix

Classes extending `Cubit` should have the `Cubit` suffix.

❌ **Bad:**
```dart
class Counter extends Cubit<int> {}
```

✅ **Good:**
```dart
class CounterCubit extends Cubit<int> {}
```

---

### use_dedicated_media_query_methods

Use dedicated `MediaQuery` methods to avoid unnecessary rebuilds.

❌ **Bad:**
```dart
final size = MediaQuery.of(context).size;
final padding = MediaQuery.of(context).padding;
final orientation = MediaQuery.of(context).orientation;
```

✅ **Good:**
```dart
final size = MediaQuery.sizeOf(context);
final padding = MediaQuery.paddingOf(context);
final orientation = MediaQuery.orientationOf(context);
```

---

### use_gap

Use `Gap` widget instead of `SizedBox` or `Padding` for spacing in multi-child widgets.

❌ **Bad:**
```dart
Column(
  children: [
    Text('First'),
    SizedBox(height: 16),
    Text('Second'),
  ],
)
```

✅ **Good:**
```dart
Column(
  children: [
    Text('First'),
    Gap(16),
    Text('Second'),
  ],
)
```

---

### use_notifier_suffix

Classes extending `Notifier` should have the `Notifier` suffix.

❌ **Bad:**
```dart
class CounterManager extends Notifier<int> {}
```

✅ **Good:**
```dart
class CounterNotifier extends Notifier<int> {}
```

---

## Suppressing Diagnostics

To suppress a specific lint, use comments:

```dart
// ignore: many_lints/prefer_center_over_align
const Align(...);

// ignore_for_file: many_lints/use_bloc_suffix
```

## More Information

See the individual example files in `lib/` for complete, runnable code samples.
