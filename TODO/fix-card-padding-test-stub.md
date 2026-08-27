---
type: bug
effort: small
status: open
---

# `avoid_wrapping_in_padding` test stubs a `Card.padding` that does not exist

## What

`test/avoid_wrapping_in_padding_test.dart:31` declares:

```dart
class Card extends Widget {
  Card({Key? key, EdgeInsets? padding, Widget? child});
}
```

Flutter's real `Card` has **no `padding` parameter** — only `margin`
(`packages/flutter/lib/src/material/card.dart:80`). So
`test_paddingWrappingCard` asserts the rule reports a shape that cannot occur
in any real project.

## Why it matters

The rule itself is fine: it looks up whether the child's type declares a
`padding` named parameter rather than carrying a hardcoded widget list, so a
real `Card` simply never matches. Nothing is broken in `lib/`.

What is broken is the test's evidence. A passing test named
"padding wrapping Card" implies coverage of a case the rule cannot encounter,
and it propagated: the documentation page used `Card` as its worked example
until 2026-08-27, so readers were shown a rewrite that would never be offered.

## Fix

Replace `Card` in the test stub with a widget that genuinely takes `padding`
(`Container`, `ListView`, `SliverPadding`), and rename the test accordingly.
Consider whether other rule tests stub widget signatures that have drifted from
the SDK — this was found by checking the stub against a real Flutter checkout,
which nothing in CI does.

## Found

2026-08-27, during the full documentation review, by verifying a doc example
against `/Users/dominikkrajcer/Developer/flutter` rather than against the
rule's own test stub.
