---
title: avoid_unnecessary_call
description: "Invoke a function directly instead of through .call()"
sidebar:
  label: avoid_unnecessary_call
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Code Quality</span>

This rule flags a function invoked through an explicit `.call()`.

`callback.call()` and `callback()` do the same thing, and the shorter one is how a function is invoked everywhere else in the language. Spelling out `.call` makes a plain invocation look like a method on an object, so a reader stops to check whether the receiver is a callable class.

This rule is in the **`opinionated`** preset and takes no configuration.

## Don't

```dart
class Uploader {
  const Uploader({required this.onDone});

  final void Function(int) onDone;

  void finish(int count) {
    onDone.call(count);
  }
}
```

## Do

```dart
class Uploader {
  const Uploader({required this.onDone});

  final void Function(int) onDone;

  void finish(int count) {
    onDone(count);
  }
}
```

## More examples

### A null-aware invocation is left alone

`callback?()` does not parse, so `.call` is the only spelling and is never reported:

```dart
class Uploader {
  const Uploader({this.onDone});

  final void Function(int)? onDone;

  // Not reported — there is no shorter form.
  void finish(int count) => onDone?.call(count);
}
```

If you want the shorter form anyway, promote first:

```dart
void finish(int count) {
  final onDone = this.onDone;
  if (onDone != null) onDone(count);
}
```

### A class with its own `call` method is not a function

The rule reads the receiver's static type: only a value whose type is a
function type has an implicit `call`. On a callable class, `.call` is the
method's real name:

```dart
class Formatter {
  String call(String input) => input.trim();
}

// Not reported — this is Formatter.call, spelled out.
String tidy(Formatter formatter, String input) => formatter.call(input);
```

Both spellings work there; `formatter(input)` is usually the point of writing a
callable class, but the rule does not insist.

## Known limitations

Only an invocation with an explicit target is reported. A bare `call()` inside a
callable class — invoking its own `call` — has no target and is left alone.

## Turning this rule off

This rule is in the **`opinionated`** preset.

To disable this rule:

```yaml
# many_lints.yaml
rules:
  avoid_unnecessary_call: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`avoid_accessing_other_classes_private_members`](/many_lints/docs/rules/code-quality/avoid-accessing-other-classes-private-members/) — Make the underscore mean what everyone reads it as.
- [`avoid_commented_out_code`](/many_lints/docs/rules/code-quality/avoid-commented-out-code/) — Detect and flag commented-out code.
- [`avoid_complex_conditions`](/many_lints/docs/rules/code-quality/avoid-complex-conditions/) — Keep boolean conditions within an operand budget.
- [`avoid_deep_nesting`](/many_lints/docs/rules/code-quality/avoid-deep-nesting/) — Keep control flow within a nesting budget.
