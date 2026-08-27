---
title: prefer_boolean_prefixes
description: "Name booleans as questions"
sidebar:
  label: prefer_boolean_prefixes
---

<span class="rule-badge rule-badge--version">v1.0.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--category">Class Naming</span>

Flags a boolean field, getter, method or top-level function whose name does not read as a yes-or-no question.

`if (user.admin)` reads as though `admin` might be an object, and the reader has to check. `if (user.isAdmin)` can only be a condition — which is why `isEmpty`, `hasListeners` and `canPop` read the way they do throughout the SDK.

This rule is in the **`pedantic`** preset, and takes no configuration.

## Don't

```dart
class User {
  bool admin = false;
  bool emailSent = false;

  bool profileComplete() => true;
}
```

## Do

```dart
class User {
  bool isAdmin = false;
  bool hasSentEmail = false;

  bool isProfileComplete() => true;
}
```

## Examples

### The verb does not have to lead

Any recognised verb counts as long as it appears as a whole camelCase word. Naming the subject first is a normal way to keep related settings sorting together:

```dart
class Settings {
  // All accepted
  bool isDefaultLocale = false;
  bool localeIsDefault = false;
  bool userCanEdit = false;
}
```

The recognised verbs are `is are was were has have had can should will would does do did must needs allows contains supports enables requires wants shows hides accepts`.

### Word boundaries, not substrings

Matching is on camelCase words, so a name that merely *contains* the letters is still reported:

```dart
// Don't — `island` is not `is`, and `hasty` is not `has`
bool island = false;    // LINT
bool hasty = false;     // LINT

// Do
bool isIsland = false;
bool isHasty = false;
```

### A bare third-person verb is already a question

A single lowercase word ending in `s` needs no prefix — it reads as a question on its own:

```dart
class Matcher {
  // Accepted
  bool matches() => true;
  bool involves() => true;
}
```

Only a single lowercase word qualifies, so `emailSent` is still reported.

### Three declarations are never reported

An `@override` takes its name from the base declaration, a setter from the getter it pairs with, and a private field backing an accessor from the storage rather than the question:

```dart
class Toggle {
  // Not reported — a private field beside an accessor
  bool _value = false;

  bool get isEnabled => _value;

  // Not reported — a setter's name is fixed by its getter
  set isEnabled(bool value) => _value = value;
}

class AdminUser extends User {
  // Not reported — the name belongs to the base declaration
  @override
  bool admin = true;
}
```

## Known limitations

**Only an explicit `bool` annotation.** The type has to be written out. `var isReady = false` and a getter with an inferred return type are not checked.

**No configuration.** The verb list is fixed. If a legitimate house style does not fit it — a predicate like `screen.atLeast(Breakpoint.tablet)` reads perfectly without a question verb — silence it with `// ignore: many_lints/prefer_boolean_prefixes` or turn the rule off.

**See also:** [Effective Dart: naming](https://dart.dev/effective-dart/design#prefer-a-non-imperative-verb-phrase-for-a-boolean-property-or-variable)

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
