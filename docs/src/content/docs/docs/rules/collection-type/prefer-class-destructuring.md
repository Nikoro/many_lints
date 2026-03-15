---
title: prefer_class_destructuring
description: "Use Dart 3 class destructuring when accessing multiple properties on the same object."
sidebar:
  badge:
    text: "Fix"
    variant: "tip"
  label: prefer_class_destructuring
---

<span class="rule-badge rule-badge--version">v0.4.0</span>
<span class="rule-badge rule-badge--warning">Warning</span>
<span class="rule-badge rule-badge--fix">Fix</span>
<span class="rule-badge rule-badge--category">Collection & Type</span>

When you access three or more properties on the same object within a scope, Dart 3 class destructuring can consolidate those accesses into a single declaration. This makes the code more concise and groups related property extractions together.

## Why use this rule

Repeated `object.property` accesses are verbose and scatter related logic across multiple lines. A single destructuring declaration like `final MyClass(:name, :email, :age) = object;` extracts all needed values at once, making it clear which properties are used in the current scope.

**See also:** [Dart patterns](https://dart.dev/language/patterns) | [Destructuring](https://dart.dev/language/patterns#destructuring)

## Don't

```dart
class UserProfile {
  final String name;
  final String email;
  final int age;
  final String address;

  const UserProfile({
    required this.name,
    required this.email,
    required this.age,
    required this.address,
  });
}

// Accessing 3+ properties separately on the same variable
void displayUser(UserProfile user) {
  final greeting = 'Hello, ${user.name}';
  final contact = user.email;
  print('Age: ${user.age}');
}
```

## Do

```dart
// Using class destructuring
void displayUser(UserProfile user) {
  final UserProfile(:name, :email, :age) = user;
  final greeting = 'Hello, $name';
  final contact = email;
  print('Age: $age');
}

// Only 2 property accesses (below threshold) — no warning
void showBasicInfo(UserProfile user) {
  print(user.name);
  print(user.email);
}

// Method calls are not counted as property accesses
void interactWithUser(UserProfile user) {
  print(user.name);
  print(user.email);
  user.toString();
}
```

## Configuration

To disable this rule:

```yaml
plugins:
  many_lints:
    diagnostics:
      prefer_class_destructuring: false
```
