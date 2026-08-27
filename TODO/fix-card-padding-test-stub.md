---
type: bug
effort: small
status: done
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

## Resolution

2026-08-27. Fixed in `test/avoid_wrapping_in_padding_test.dart`: the `Card` stub
is replaced by a `BoxScrollView`/`ListView` pair where `ListView` takes
`super.padding`, matching the real signature
(`packages/flutter/lib/src/widgets/scroll_view.dart`). `test_paddingWrappingCard`
became `test_paddingWrappingListViewWithInheritedPaddingParam`, and now covers
something the suite did not cover before: `padding` arriving as a
**super-parameter**. Verified that the rule sees it — `_hasPaddingParam` reads
`constructor.formalParameters`, and a super-parameter is a real named formal
parameter there.

`example/lib/avoid_wrapping_in_padding_example.dart` carried the same mistake
(`// LINT: Card supports padding`), which the original note did not mention. The
LINT case is now a `ListView`; `Card` moved to the "Good" section as a widget
that genuinely has no `padding`. The docs page had already been corrected.

### On the follow-up question

Swept all 141 stub blocks across 96 test files against a real Flutter checkout
(3.47.1). **No other stub had a fabricated parameter that a test assertion
depended on** — the Card bug was the only one of its kind. Three further
fabrications were real but not load-bearing, and were corrected anyway:

- `Border({BorderSide side})` in `avoid_border_all_test.dart` — the real `Border`
  takes four sides (`painting/box_border.dart:435`); the single-side form is the
  positional `Border.fromBorderSide`.
- `BorderRadius.circular` in `prefer_const_border_radius_test.dart`, stubbed once
  as a **static method** and once as a **const constructor**. It is neither: it is
  a non-const generative constructor (`painting/border_radius.dart:361`). Each
  stub therefore exercised only one of the rule's two visitor branches, and the
  const one passed for a reason that cannot occur in real code. Both now use the
  real form.

One reported finding did **not** hold up. The sweep claimed the rule's
`('children', SliverList)` entry in `avoid_single_child_in_multi_child_widgets.dart`
was dead because no real `SliverList` constructor takes `children`. That is
wrong: `SliverList.list({required List<Widget> children, ...})` exists at
`widgets/sliver.dart:367`. Checked directly against the real signature — the rule
reports it. The entry stays.
