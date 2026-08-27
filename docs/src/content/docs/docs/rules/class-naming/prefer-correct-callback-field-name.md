---
title: prefer_correct_callback_field_name
description: "Name callbacks onSomething, the way Flutter does"
sidebar:
  label: prefer_correct_callback_field_name
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Class Naming</span>

Flags a function-typed field or parameter named `somethingCallback`, `somethingHandler`, `somethingListener` or `somethingAction` rather than `onSomething`.

`onTap`, `onChanged` and `onPressed` run through the whole Flutter API, so `on...` is what a reader recognises as "this fires when something happens". At the call site `MyWidget(tapCallback: ...)` reads as a value where `onTap:` reads as an event.

This rule is in the **`pedantic`** preset, and takes no configuration.

## Don't

```dart
class ConfirmButton extends StatelessWidget {
  const ConfirmButton({super.key, required this.tapCallback});

  final void Function() tapCallback;   // LINT
}
```

## Do

```dart
class ConfirmButton extends StatelessWidget {
  const ConfirmButton({super.key, required this.onTap});

  final void Function() onTap;
}
```

## Examples

### All four callback words are flagged

`callback`, `handler`, `listener` and `action` all describe *what* the value is instead of *when* it fires:

```dart
class Form {
  // Don't
  final void Function() submitHandler;      // LINT
  final void Function() changeListener;     // LINT
  final void Function() resetAction;        // LINT
  final void Function() saveCallback;       // LINT

  // Do
  final void Function() onSubmit;
  final void Function() onChange;
  final void Function() onReset;
  final void Function() onSave;

  const Form({
    required this.submitHandler,
    required this.changeListener,
    required this.resetAction,
    required this.saveCallback,
    required this.onSubmit,
    required this.onChange,
    required this.onReset,
    required this.onSave,
  });
}
```

### Plain parameters are checked too

Not just fields — any function-typed parameter:

```dart
// Don't
void register(void Function() errorHandler) {}   // LINT

// Do
void register(void Function() onError) {}
```

### A function named for what it computes is left alone

Only a name that *positively ends* in a callback word is considered. `builder`, `comparator` and `parse` say what they produce, not when they fire — renaming any of them to `on...` would be wrong:

```dart
class ListConfig {
  // All accepted
  final Widget Function(int) builder;
  final int Function(String, String) comparator;
  final int Function(String) parse;

  const ListConfig({
    required this.builder,
    required this.comparator,
    required this.parse,
  });
}
```

### A bare framework noun is left alone

The suffix has to *follow* something. A parameter named exactly `handler`, `listener` or `action` is the thing itself, not a callback for an event — `Handler middleware(Handler handler)` in dart_frog is the request handler, and `onHandler` would be nonsense:

```dart
// Accepted — the whole name is the noun
void use(void Function() handler) {}
void attach(void Function() listener) {}
```

### An override and a field-initialising parameter are skipped

An `@override` takes its name from the base declaration; `this.tapCallback` takes its name from the field the rule already checks, so reporting both would double up:

```dart
class Base {
  final void Function() tapCallback;

  const Base({required this.tapCallback});   // `this.tapCallback` not reported here
}

class Child extends Base {
  // Not reported — the name belongs to the base declaration
  @override
  final void Function() tapCallback;

  const Child({required this.tapCallback}) : super(tapCallback: tapCallback);
}
```

## Known limitations

**The type must resolve to a function.** An inline `void Function()`, a named typedef and an inferred parameter type all work. A field declared `dynamic` or `Object` does not, even when it holds a closure.

**No quick fix.** Turning `tapCallback` into `onTap` is not a mechanical transformation — the right event name is rarely the callback word with `on` bolted on the front.

**See also:** [Effective Dart: naming](https://dart.dev/effective-dart/design#naming)

## Enabling this rule

This rule is in the **`pedantic`** preset, so it is enabled by `preset: pedantic` or by name:

```yaml
# many_lints.yaml
rules:
  prefer_correct_callback_field_name:
    enabled: true
```

## Turning this rule off

To disable this rule:

```yaml
# many_lints.yaml
rules:
  prefer_correct_callback_field_name: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_correct_error_name`](/many_lints/docs/rules/class-naming/prefer-correct-error-name/) — Name exception and error classes with the matching suffix.
- [`prefer_correct_handler_name`](/many_lints/docs/rules/class-naming/prefer-correct-handler-name/) — Name event handlers after the event they answer.
- [`prefer_correct_setter_parameter_name`](/many_lints/docs/rules/class-naming/prefer-correct-setter-parameter-name/) — Use one parameter name in every setter.
- [`prefer_boolean_prefixes`](/many_lints/docs/rules/class-naming/prefer-boolean-prefixes/) — Name booleans as questions.
