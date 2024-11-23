<a href="https://pub.dev/packages/get_hooked">
  <p align="center">
    <img alt="Get Hooked! (logo)" src="https://github.com/user-attachments/assets/aecf1fbf-280e-4a0f-85ec-f8b24f6bc63e" width="200px">
  </p>
</a>

<br>

<p align="center">
  A Flutter package for sharing state between widgets, inspired by <a href="https://pub.dev/packages/riverpod"><b>riverpod</b></a> and <a href="https://pub.dev/packages/get_it"><b>get_it</b></a>.
</p>

<br><br>

<hr>

<br><br>

# Summary

No boilerplate. No `build_runner`. Raw performance.

<br>

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
<sup>(The `==`/`hashCode` overrides could be added manually, or with a [**fancy macro**](https://dart.dev/language/macros)!)</sup>

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

A `final`, globally-scoped `myDataProvider` object is created via code generation:
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

### get_hooked

```dart
final getMyData = Get.it(Data.initial);
```

```dart
    final data = Ref.watch(getMyData);
```

<br>

# Comparison

| | [`InheritedWidget`](https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html) | [provider](https://pub.dev/packages/provider) | [bloc](https://bloclibrary.dev) | [riverpod](https://riverpod.dev) | [get_it](https://pub.dev/packages/get_it) | [get_hooked](https://pub.dev/packages/get_hooked) |
|---------------------------------------|:--:|:---:|:--:|:---:|:--:|:---:| 
| shared state between widgets          | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| supports scoping                      | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| optimized for performance             | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| optimized for testability             | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Tailored for Dart 3                   | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Has a stable release                  | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| supports conditional subscriptions    | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| integrated with Hooks                 | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| avoids type overlap                   | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| no `context` needed                   | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| no boilerplate/code generation needed | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| supports lazy-loading                 | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| supports auto-dispose                 | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| supports `Animation`s                 | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| Flutter & non-Flutter variants        | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
<!-- Gotta love emojis being 1.5 characters wide! -->

<br>

# Drawbacks

### "Early Alpha" stage

Until version 1.0.0, you can expect breaking changes without prior warning.

<br>

### Flutter only

Many packages on [pub.dev](https://pub.dev/) have both a Flutter and a non-Flutter variant.

| Flutter | generic |
|:-:|:-:|
| [**flutter_riverpod**](https://pub.dev/packages/flutter_riverpod) | [**riverpod**](https://pub.dev/packages/riverpod) |
| [**flutter_bloc**](https://pub.dev/packages/flutter_bloc) | [**bloc**](https://pub.dev/packages/bloc) |
| [**watch_it**](https://pub.dev/packages/watch_it) | [**get_it**](https://pub.dev/packages/get_it) |

If you want a non-Flutter version of [**get_hooked**](https://pub.dev/packages/get_hooked), please [open an issue](https://github.com/nate-thegrate/get_hooked/issues)
and describe your use case.

<br>

# Highlights

### Zero-cost interface

In April 2021, [flutter/flutter#71947](https://github.com/flutter/flutter/pull/71947#issuecomment-820568540)
added a huge performance optimization to the [`ChangeNotifier`](https://github.com/flutter/flutter/blob/d6918a48d3bb8c247efabea04b3361e1c4a40e02/packages/flutter/lib/src/foundation/change_notifier.dart#L138)
API.

This boosted `Listenable` objects throughout the Flutter framework,
and the effects have stretched into other packages:

- **flutter_hooks** includes built-in support for Flutter's `Listenable` objects.
- **riverpod** has adopted [the same strategy as ChangeNotifier](https://github.com/rrousselGit/riverpod/blob/9e62837a9fb6741dc40728c6e28d0fd9d62452e3/packages/riverpod/lib/src/listenable.dart#L53) in its internal logic.

<br>

Then in February 2024, Dart introduced [**extension types**](https://dart.dev/language/extension-types),
allowing for complete control of an API surface without incurring
runtime performance costs.

<br>

November 2024: **get_hooked** is born.

```dart
extension type Get(Listenable hooked) {
  // ...
}
```

<br>

### Animations

This package makes it easier than ever before for a multitude of widgets to subscribe to a single
[`Animation`](https://main-api.flutter.dev/flutter/animation/Animation-class.html).

A tailor-made `TickerProvider` allows animations to repeatedly attach & detach from `BuildContext`s
based on how they're being used. A developer could prevent widget rebuilding entirely by
hooking them straight up to `RenderObject`s.

```dart
final getAnimation = Get.vsync();

class _RenderMyAnimation extends RenderSliverAnimatedOpacity {
  _RenderMyAnimation() : super(opacity: getAnimation.hooked);
}
```

<br>

### Optional scoping

Here, "scoping" is defined as a form of dependency injection, where a subset of widgets
(typically descendants of an `InheritedWidget`) receive data by different means.

```dart
ProviderScope(
  overrides: [myDataProvider.overrideWith(OtherDataClass.new)],
  child: Consumer(builder: (context, ref, child) {
    final data = ref.watch(myDataProvider);
    // ...
  }),
),
```

`Ref.watch()` will watch a different Get object if an `Override` is found in
an ancestor `GetScope` widget.

```dart
GetScope(
  overrides: [Override(getMyData, overrideWith: OtherDataClass.new)],
  child: HookBuilder(builder: (context) {
    final data = Ref.watch(getMyData);
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
    final newData = useState(Data.initial);
    Ref.override(getMyData, () => newData); // Adds newData to the scope.

    return Row(
      children: [Text('$newData'), child],
    );
  }
}
```

If the child widget uses `Ref.watch(getMyData)`, it will watch
the `newData` by default.

<br>

### No magic curtain

Want to find out what's going on?\
No breakpoints, no print statements. Just type the name.

![getFade](https://github.com/user-attachments/assets/9dbb65b3-c2c2-44eb-9870-28defeede0ad)

<br>

# Overview



"Get" encapsulates a listenable object with an interface for easy updates and automatic lifecycle management.

<br>

#### Example usage

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
final getCount = Get.it(0);

class CounterButton extends HookWidget {
  const CounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {
        getCount.value += 1;
      },
      child: Text('counter value: ${Ref.watch(getCount)}'),
    );
  }
}
```

15 lines of code, same as before!

<br>

An object like `getCount` can't be passed into a `const` constructor.\
However: since access isn't limited in scope, it can be referenced by functions and static methods,
creating huge potential for rebuild-optimization.

The following example supports the same functionality as before, but the `Text` widget updates based on
`getCount` without the outer button widget ever being rebuilt:
```dart
final getCount = Get.it(0);

class CounterButton extends FilledButton {
  const CounterButton({super.key})
    : super(onPressed: _increment, child: const HookBuilder(builder: _build));

  static void _increment() {
    getCount.modify((int value) => value + 1);
  }

  static Widget _build(BuildContext context) {
    return Text('counter value: ${Ref.watch(getCount)}');
  }
}
```

<br>

## Detailed Overview

Here's a (less oversimplified) rundown of the Get API:

```dart
extension type Get<T, V extends ValueListenable<T>>.custom(V hooked) {
  @factory
  static GetValue<T> it<T>(T initial) => GetValue<T>._(initial);

  T get value => hooked.value
}

extension type GetValue<T>._(ValueNotifier<T> hooked) implements Get<T, ValueNotifier<T>> {
  void emit(T newValue) => hooked.value = newValue;

  void modify(T Function(T value) modifier) => emit(modifier(hooked.value));
}

class Ref {
  static T watch(Get<T, ValueListenable<T>> getObject) {
    return use(_RefHook(getObject));
  }
}
```

> [!CAUTION]
> **Do not access** `hooked` **directly:** get it through a Hook instead.\
> If a listener is added without automatically being removed, it can result in memory leaks,
> and calling `dispose()` would create problems for other widgets that are still using it.
>
> <br>
>
> Only use `hooked` in the following situations:
> - If another API accepts a `Listenable` object (and takes care of the listener automatically).
> - If you feel like it.

<br>

# Tips for success

### Follow the rules of Hooks

`Ref` functions, along with any function name starting with `use`,
should only be called inside a `HookWidget`'s build method.

```dart
// BAD
Builder(builder: (context) {
  final focusNode = useFocusNode();
  final data = Ref.watch(useMyData);
})

// GOOD
HookBuilder(builder: (context) {
  final focusNode = useFocusNode();
  final data = Ref.watch(useMyData);
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

### `Get` naming conventions

Just like how Hook functions generally start with `use`, Get objects should start
with `get`.

If the object is only intended to be used by widgets in the same `.dart` file,
consider marking it with an annotation, to avoid cluttering autofill suggestions:

```dart
@visibleForTesting
final getAnimation = Get.vsync();
```

<br>

### Avoid using `hooked` directly

Unlike most `StatefulWidget` member variables, Get objects persist throughout
changes to the app's state, so a couple of missing `removeListener()` calls
might create a noticeable performance impact.
Prefer calling `Ref.watch()` to subscribe to updates.

When a `GetAsync` object's listeners are removed, it will automatically end its
stream subscription and restore the listenable to its default state.
A listenable encapulated in a Get object should avoid calling the internal
`ChangeNotifier.dispose()` method, since the object would be unusable
from that point onward.

<br><br>

# Troubleshooting / FAQs

So far, not a single person has reached out because of a problem with this package.
Which means it's probably flawless!

<br><br>

<hr>

<br><br>

<a href="https://pub.dev/packages/get_hooked">
  <p align="center">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/0a4dc595-24c8-4b98-bf93-1ede32b0cf03">
      <img alt="get_hooked (logo, bottom)" src="https://github.com/user-attachments/assets/c82159f8-142d-4289-9405-a10b50fff259">
    </picture>
  </p>
</a>
