---
title: prefer_correct_callback_field_name
description: "Name callbacks onSomething, the way Flutter does"
sidebar:
  label: prefer_correct_callback_field_name
---

<span class="rule-badge rule-badge--version">v0.10.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Class Naming</span>

This rule flags a callback field or parameter named `somethingCallback`, `somethingHandler`, `somethingListener` or `somethingAction` rather than `onSomething`.

## Why use this rule

`onTap`, `onChanged` and `onPressed` run through the whole Flutter API, so `on...` is what a reader recognises as "this fires when something happens". A field called `tapCallback` carries the same meaning in a spelling every codebase invents differently, and at the call site `MyWidget(tapCallback: ...)` reads as a value where `onTap:` reads as an event.

This rule is in **no preset**, because naming conventions are a house style rather than a correctness question.

**See also:** [Effective Dart: naming](https://dart.dev/effective-dart/design#naming)

## What is never reported

- **A function named for what it computes.** `builder`, `comparator` and `parse` say what they produce, not when they fire; renaming any of them to `on...` would be wrong. Only a name that positively ends in a callback word is considered.
- **A bare framework noun.** A parameter named exactly `handler`, `listener` or `action` is the thing itself rather than a callback for an event — `Handler middleware(Handler handler)` in dart_frog is the request handler, and `onHandler` would be nonsense. The suffix has to follow something.
- **An `@override`**, whose name belongs to the base declaration, and a **field-initialising parameter** (`this.onTap`), which takes its name from the field the rule already checks.

## Don't

```dart
class ConfirmButton extends StatelessWidget {
  const ConfirmButton({super.key, required this.tapCallback});

  final void Function() tapCallback;
}
```

## Do

```dart
class ConfirmButton extends StatelessWidget {
  const ConfirmButton({super.key, required this.onTap});

  final void Function() onTap;
}
```

## Enabling this rule

This rule is in no preset, so enable it by name:

```yaml
# many_lints.yaml
rules:
  prefer_correct_callback_field_name:
    enabled: true
```

## Turning this rule off

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_correct_callback_field_name: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).
