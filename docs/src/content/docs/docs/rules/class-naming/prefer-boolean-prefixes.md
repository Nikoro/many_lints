---
title: prefer_boolean_prefixes
description: "Name booleans as questions"
sidebar:
  label: prefer_boolean_prefixes
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Class Naming</span>

This rule flags a boolean field, getter or method whose name does not read as a yes-or-no question.

## Why use this rule

`if (user.admin)` reads as though `admin` might be an object, and the reader has to check. `if (user.isAdmin)` can only be a condition. The verb is what tells you at the call site that nothing further is needed to get a boolean out of it, and it is why `isEmpty`, `hasListeners` and `canPop` read the way they do throughout the SDK.

This rule is in the **`pedantic`** preset. Naming is where reasonable codebases disagree most, and the empirical run found a legitimate style it cannot accommodate: a predicate like `screen.atLeast(Breakpoint.tablet)` reads perfectly without a question verb. Enable it by name if the convention is one you want enforced.

**See also:** [Effective Dart: naming](https://dart.dev/effective-dart/design#prefer-a-non-imperative-verb-phrase-for-a-boolean-property-or-variable)

## What counts as a question

The verb does not have to lead. `localeIsDefault` asks the same question as `isDefaultLocale`, and naming the subject first is a normal way to keep related settings sorting together — so any of the recognised verbs appearing as a whole word satisfies the rule.

A bare third-person verb (`involves`, `matches`) is already a question and needs no prefix.

Three things are never reported: an `@override`, whose name belongs to the base declaration; a setter, whose name is fixed by the getter it pairs with; and a private field backing an accessor, which is named after the storage while the accessor carries the readable name.

## Don't

```dart
class User {
  bool admin = false;
  bool emailSent = false;
}
```

## Do

```dart
class User {
  bool isAdmin = false;
  bool hasSentEmail = false;
}
```

## Enabling this rule

This rule is in the **`pedantic`** preset, so it is enabled by `preset: pedantic` or by name:

```yaml
# many_lints.yaml
rules:
  prefer_boolean_prefixes:
    enabled: true
```

## Turning this rule off

To disable this rule:

```yaml
# many_lints.yaml
rules:
  prefer_boolean_prefixes: false
```

To keep the rule on but skip certain paths, use [per-rule `exclude`](/many_lints/docs/configuration/#excluding-paths-per-rule).

## Related rules

- [`prefer_correct_callback_field_name`](/many_lints/docs/rules/class-naming/prefer-correct-callback-field-name/) — Name callbacks onSomething, the way Flutter does.
- [`prefer_correct_error_name`](/many_lints/docs/rules/class-naming/prefer-correct-error-name/) — Name exception and error classes with the matching suffix.
- [`prefer_correct_handler_name`](/many_lints/docs/rules/class-naming/prefer-correct-handler-name/) — Name event handlers after the event they answer.
- [`prefer_correct_setter_parameter_name`](/many_lints/docs/rules/class-naming/prefer-correct-setter-parameter-name/) — Use one parameter name in every setter.
