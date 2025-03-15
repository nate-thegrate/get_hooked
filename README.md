<a href="https://pub.dev/packages/get_hooked">
  <p align="center">
    <img alt="Get Hooked! (logo)" src="https://github.com/user-attachments/assets/aecf1fbf-280e-4a0f-85ec-f8b24f6bc63e" width="200px">
  </p>
</a>

<br>

<h1 align="center">please don't.</h1>

<br>

**get_hooked** handles state management by using `ValueListenable` objects
as global variables. This practice goes against
[Flutter's style guide](https://github.com/flutter/flutter/blob/master/docs/contributing/Style-guide-for-Flutter-repo.md#avoid-secret-or-global-state)
and in some situations can lead to memory leaks.

Futhermore, prior to the 1.0.0 release, this package will not have
deprecation periods for breaking changes.

<br>

Here are a few alternatives to consider:

- [**riverpod**](https://riverpod.dev): if you don't mind using build_runner,
  this is a fantastic option.
- [**watch_it**](https://pub.dev/packages/watch_it): this package works great if
  you're already using [get_it](https://pub.dev/packages/get_it).
- [**signals**](https://pub.dev/packages/signals): a powerful, feature-rich
  package that reduces boilerplate without any code generation.

<br>

To learn more about **get_hooked**, continue reading here.

<br><br>

<hr>

<br><br>

# Summary

Listenable providers built with Hooks!

No boilerplate, no `build_runner`, huge performance.

<br>

## Comparison

| | [`InheritedWidget`](https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html) | [provider](https://pub.dev/packages/provider) | [bloc](https://bloclibrary.dev) | [riverpod](https://riverpod.dev) | [signals](https://dartsignals.dev/) | [get_it](https://pub.dev/packages/get_it) | [get_hooked](https://pub.dev/packages/get_hooked) |
|---------------------------------------|:--:|:---:|:--:|:---:|:--:|:---:|:--:|
| shared state between widgets          | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| supports scoping                      | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| optimized for performance             | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| optimized for testability             | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| conditional subscriptions             | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| avoids type overlap                   | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |
| no `context` needed                   | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| no boilerplate/code generation needed | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ |
| supports lazy-loading                 | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| supports animations                   | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| supports non-Flutter applications     | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Has a stable release                  | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |

<br>

# Drawbacks

## "Early Alpha" stage

Until version 1.0.0, you can expect breaking changes without prior warning.

<br>

## Flutter only

Many packages on [pub.dev](https://pub.dev/) have both a Flutter and a non-Flutter variant.

| Flutter | generic |
|:-------:|:-------:|
| [**flutter_riverpod**](https://pub.dev/packages/flutter_riverpod) | [**riverpod**](https://pub.dev/packages/riverpod) |
| [**flutter_bloc**](https://pub.dev/packages/flutter_bloc) | [**bloc**](https://pub.dev/packages/bloc) |
| [**watch_it**](https://pub.dev/packages/watch_it) | [**get_it**](https://pub.dev/packages/get_it) |

This is not a planned feature for **get_hooked**.

## Unconditional Subscriptions

Depending on who you ask, a lack of conditional subscriptions
could be characterized as a "missing feature" or as a "performance tradeoff".\
(See [flutter.dev/go/inheritedwidget-subscription](https://flutter.dev/go/inheritedwidget-subscription)
and its linked issue for more discussion.)

Setting up a provider to auto-dispose when it no longer has listeners
can reduce costs: both in terms of performance and money.

```dart
Widget build(BuildContext context, WidgetRef ref) {
  Object? data;
  if (_showingData) {
    data = ref.watch(databaseProvider);
  }

  // The provider can disconnect itself from the database
  // After the widget builds without a ref.watch() call.
}
```

But a similar result is achievable via composition:

```dart
Widget build(BuildContext context) {
  return _showingData ? const WidgetA() : const WidgetB();
}
```

Implementing conditional subscriptions for this package would be difficult
due to conflicts with the "Hook" paradigm.\
That being said: feel free to [post an issue](https://github.com/nate-thegrate/get_hooked/issues/new)
and share your opinion if you'd like!

<br>

# Highlights

## No boilerplate.

Given a generic `Data` class, let's see how different state management options compare.

```dart
@immutable
class Data {
  const Data(this.firstItem, [this.secondItem]);

  final Object firstItem;
  final Object? secondItem;

  static const initial = Data('initial data');
}
```

<br>

### Inherited Widget

```dart
class _InheritedData extends InheritedWidget {
  const _InheritedData({super.key, required this.data, required super.child});

  final Data data;

  @override
  bool updateShouldNotify(MyData oldWidget) => data != oldWidget.data;
}

class MyData extends StatefulWidget {
  const MyData({super.key, required this.child});

  final Widget child;

  static Data of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_InheritedData>()!.data;
  }

  State<MyData> createState() => _MyDataState();
}

class _MyDataState extends State<MyData> {
  Data _data = Data.initial;

  @override
  Widget build(BuildContext context) {
    return _InheritedData(data: _data, child: widget.child);
  }
}
```

Then the data can be accessed with
```dart
    final data = MyData.of(context);
```

<br>

### provider

```dart
typedef MyData = ValueNotifier<Data>;

class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyData(Data.initial),
      child: child,
    );
  }
}
```
<sup>([**flutter_bloc**](https://pub.dev/packages/flutter_bloc) is very similar but requires extending `Cubit<Data>` rather than making a `typedef`.)</sup>

```dart
    final data = context.watch<MyData>().value;
```

<br>

### riverpod

```dart
@riverpod
class MyData extends _$MyData {
  @override
  Data build() => Data.initial;

  void update(Object firstItem, [Object? secondItem]) {
    state = Data(firstItem, secondItem);
  }
}
```

An immutable, globally-scoped `myDataProvider` object is created via code generation:
```ps
$ dart run build_runner watch
```

and accessed as follows:
```dart
    final data = ref.watch(myDataProvider);
```

<br>

### get_it

```dart
typedef MyData = ValueNotifier<Data>;

GetIt.I.registerSingleton(MyData(Data.initial));
```

```dart
    final data = watchIt<MyData>().value;
```

<br>

### signals

```dart
typedef MyData = FlutterSignal<Data>;

class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SignalProvider(
      create: () => MyData(Data.initial),
      child: child,
    );
  }
}
```
<sup>
  To be fair, signals can be set up as <code>static</code> or globally-scoped objects
  (or as class members) to greatly reduce the boilerplate—the only downside being
  a lack of support for scoping.
</sup>

```dart
    final data = SignalProvider.of<MyData>(context);
```

<br>

### get_hooked

```dart
final myData = Get.it(Data.initial);
```

```dart
    final data = ref.watch(myData);
```

<br>

## Zero-cost interface

In April 2021, [flutter/flutter#71947](https://github.com/flutter/flutter/pull/71947#issuecomment-820568540)
added a huge performance optimization to the [`ChangeNotifier`](https://github.com/flutter/flutter/blob/d6918a48d3bb8c247efabea04b3361e1c4a40e02/packages/flutter/lib/src/foundation/change_notifier.dart#L138)
API.

This boosted `Listenable` objects throughout the Flutter framework,
and in other packages:

- **flutter_hooks** includes built-in support for Flutter's `Listenable` objects.
- **riverpod** has adopted [the same strategy as ChangeNotifier](https://github.com/rrousselGit/riverpod/blob/9e62837a9fb6741dc40728c6e28d0fd9d62452e3/packages/riverpod/lib/src/listenable.dart#L53)
  in its internal logic.
- **get_it** [recommends using ChangeNotifier](https://github.com/fluttercommunity/get_it/blob/589f27a775da471747f2cc47412e596491450264/example/lib/app_model.dart#L5-L9)
  to interact with its service locator API.
- **signals** has adapted its Flutter signal APIs so that they
  [implement ValueListenable by default](https://dartsignals.dev/flutter/value-listenable/).

<br>

In February 2024, Dart introduced [**extension types**](https://dart.dev/language/extension-types),
allowing for complete control of an API surface without incurring
runtime performance costs.

<br>

November 2024:

```dart
extension type Get(Listenable hooked) {
  // ...
}
```

<br>

## Animations

This package makes it easier than ever before for a multitude of widgets to
subscribe to a single animation.

A tailor-made `Vsync` keeps the tickers up-to-date, and `RefPaint` can subscribe
and re-render without ever rebuilding the widget tree.

```dart

class MyWidget extends StatelessWidget {
  static final animation = Get.vsync();

  @override
  Widget build(BuildContext context) {
    return RefPaint((ref) {
      // This widget will re-paint each time the animation sends an update.
      final double t = ref.watch(animation);

      ref.canvas.drawPath(/* ... */);
    });
  }
}
```

<br>

## Optional scoping

"Scoping" allows descendants of an `InheritedWidget` to receive data
by different means.

For example, **flutter_riverpod** includes a `ProviderScope` widget:

```dart
ProviderScope(
  overrides: [myDataProvider.overrideWith(OtherData.new)],
  child: Consumer(builder: (context, ref, child) {
    final data = ref.watch(myDataProvider);
    // ...
  }),
),
```

Likewise, **get_hooked** enables `ref.watch()` to subscribe to a different object
if a substitution is found in an ancestor `GetScope`.

```dart
GetScope(
  substitutes: [Substitute(myData, OtherData.new)],
  child: HookBuilder(builder: (context) {
    final data = ref.watch(myData);
    // ...
  }),
),
```

If the current `context` has an ancestor `GetScope`, building another scope
isn't necessary:

```dart
class MyWidget extends HookWidget {
  const MyWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final newData = ref.sub(getMyData, OtherData.new);

    return Row(
      children: [Text('$newData'), child],
    );
  }
}
```

If the child widget uses `ref.watch(getMyData)`, it will watch
the `newData` by default.

<br>

<!-- ## Dart 3 Hooks

Introduced in the phenomenal [**flutter_hooks**](https://pub.dev/packages/flutter_hooks)
package, the [**HookWidget**](https://pub.dev/documentation/flutter_hooks/latest/flutter_hooks/HookWidget-class.html)
allows a widget to benefit from a [**StatefulWidget**](https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html)'s
functionality using a single class declaration.

package as a foundation, **get_hooked** introduces a few tweaks to the API. -->

<!-- ## No magic curtain

Want to find out what's going on?\
No breakpoints, no print statements. Just type the name.

![getFade](https://github.com/user-attachments/assets/9dbb65b3-c2c2-44eb-9870-28defeede0ad)

<br> -->

# Overview

`Get` objects aren't necessary if the state isn't shared between widgets.\
This example shows how to make a button with a number that increases each time it's tapped:

```dart
class CounterButton extends HookWidget {
  const CounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = useState(0);

    return FilledButton(
      onPressed: () {
        counter.value += 1;
      },
      child: Text('counter value: ${counter.value}'),
    );
  }
}
```

But the following change would allow any widget to access this value:

```dart
final counter = Get.it(0);

class CounterButton extends HookWidget {
  const CounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {
        counter.value += 1;
      },
      child: Text('counter value: ${ref.watch(counter)}'),
    );
  }
}
```

15 lines of code, same as before!

<br>

An object like `counter` can't be passed into a `const` constructor.\
However: since access isn't limited in scope, it can be referenced by functions
and static methods, creating huge potential for rebuild-optimization.

The following example supports the same functionality as before, but
the `Text` widget updates based on the `counter` without the outer button widget
ever being rebuilt:

```dart
final counter = Get.it(0);

class CounterButton extends FilledButton {
  const CounterButton({super.key})
    : super(onPressed: _increment, child: const HookBuilder(builder: _build));

  static void _increment() {
    counter.value += 1;
  }

  static Widget _build(BuildContext context) {
    return Text('counter value: ${ref.watch(counter)}');
  }
}
```

<br>

## Detailed Overview

```dart
/// Wraps a [Listenable] with a new interface.
extension type Get<T, V extends ValueListenable<T>>.custom(V _hooked) {
  @factory
  static GetValue<T> it<T>(T initial) => GetValue<T>._(ValueNotifier(initial));

  T get value => hooked.value
}

/// A subtype of [Get] that encapsulates a [ValueNotifier].
extension type GetValue<T>._(ValueNotifier<T> _hooked) implements Get<T, ValueNotifier<T>> {}

/// Gives direct access to the underlying [Listenable].
extension GetHooked<V> on Get<Object?, V> {
  V get hooked => _hooked;
}
```

> [!CAUTION]
>
> **Do not get** `hooked` **directly:** use `ref.watch()` instead.\
> If a listener is added without automatically being removed, it can result in memory leaks,
> not to mention the problems that calling `dispose()` would create for other widgets
> that are still using the object.
>
> Consider hiding this getter as follows:
>
> ```dart
> import 'package:get_hooked/get_hooked.dart' hide GetHooked;
> ```
>
> <br>
>
> Only use `hooked` in the following situations:
> - If another API accepts a `Listenable` object (and takes care of the listener automatically).
> - If you feel like it.

<br>

```dart
const HookRef ref = HookRef._();

class HookRef implements Ref {
  // ...
}
```

`ref.watch()` and other static methods link Get objects with `HookWidget`s
and `RenderHookWidget`s.

The `Ref()` constructor is used in a `GetScope` to make substitutions.\
Descendant widgets that use `ref.watch()` will reference the new object
in its place.

<br>

# Tips for success

## Follow the rules of Hooks

`Ref` functions, along with any function name starting with `use`,
should only be called inside a `HookWidget`'s build method.

```dart
// BAD
Builder(builder: (context) {
  final focusNode = useFocusNode();
  final data = ref.watch(getMyData);
})

// GOOD
HookBuilder(builder: (context) {
  final focusNode = useFocusNode();
  final data = ref.watch(getMyData);
})
```

A `HookWidget`'s `context` keeps track of:
1. how many hook functions are called, and
2. the order they're called in.

Neither of these should change throughout the widget's lifetime.

For a more detailed explanation, see also:
- https://pub.dev/packages/flutter_hooks#rules
- https://react.dev/reference/rules/rules-of-hooks

<br>

## No simultaneous read & write

If a function is calling `ref.watch()`, that function should not mutate
any non-local values.

```dart
// BAD
double computeFunction(Ref ref) {
  final a = ref.watch(getA);
  if (a > 0) {
    getB.value += a;
  }
  final b = ref.watch(getB);
  return a + b;
}
```

```dart
// GOOD
double computeFunction(Ref ref) {
  final a = ref.watch(getA);
  final b = ref.watch(getB);
  return a + b;
}

void performUpdate() {
  final a = getA.value;
  if (a > 0) {
    getB.value += a;
  }
}
```

As a rule of thumb:
- Watching happens during a frame, while widgets are being built and rendered.
- Updates happen between frames, e.g. in response to user input or after `await`ing a Future.

> [!TIP]
> Try to avoid [post-frame callbacks](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addPostFrameCallback.html)
> whenever possible. It's an easy band-aid solution for
> `error: setState() called during build()`, but this practice often results in
> the framework drawing multiple frames in response to a single update.

<br>

## Only scope when necessary

One of the best things about **get_hooked** is the ability to interact
with providers directly.

While building a HookWidget, the `ref` methods handle the `BuildContext`
boilerplate, but as far as handling things between frames, scoping makes things
arguably a bit too verbose.

```dart
// With scope:
context.get(animation).forward();

// No scope:
animation.forward();
```

Scoping is sometimes necessitated by the app's target behavior: in these cases,
prefer adding the `GetScope` directly above the target widget(s), rather than
at the root of the tree.

```dart
// BAD
runApp(const GetScope(child: App()));

// GOOD
const GetScope(
  // This scope is as low in the tree as possible
  // while staying above the widgets that need scoping.
  child: Row(
    children: [
      ScopedWidget1(),
      ScopedWidget2(),
      Expanded(child: ScopedWidget3()),
    ],
  ),
)
```

This reduces the likelihood of `ref.sub()` and `GetScope.add()` leading to
conflicting substitutions, and it mitigates the additional performance costs.

<br>

If scoping is always the desired behavior for a certain Get object,
prefer instantiating via a `ScopedGet` constructor.

```dart
final getString = ScopedGet.it<String>();
```

<br>

## Avoid accessing `hooked` directly

Unlike a typical `State` member variable, Get objects persist throughout
changes to the app's state, so a couple of missing `removeListener()` calls
might create a noticeable performance impact.
Prefer calling `ref.watch()` to subscribe to updates.

A `static` or globally-scoped object should avoid calling the internal
`ChangeNotifier.dispose()` method, since the object would be unusable
from that point onward.

<br><br>

# Troubleshooting / FAQs

#### Ticker `AssertionError`

You might see an error with the message
`Cannot absorb Ticker after it has been disposed`.

This is a bug: if an `AnimationController` starts its ticker and then calls
[`resync()`](https://api.flutter.dev/flutter/animation/AnimationController/resync.html)
before the next frame, the Flutter framework incorrectly assumes that
the ticker was disposed of.

Eventually, a bugfix will be merged into the framework and subsequently
will show up in a stable release. Until then, feel free to make a change to
[ticker.dart](https://github.com/flutter/flutter/blob/d261411b4c3bfb8591f352e3842f64005ba75505/packages/flutter/lib/src/scheduler/ticker.dart#L320-L323):
```diff
    assert(
-     (originalTicker._future == null) == (originalTicker._startTime == null),
+     (originalTicker._future != null) || (originalTicker._startTime == null),
      'Cannot absorb Ticker after it has been disposed.',
    );
```
