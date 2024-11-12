<a href="https://pub.dev/packages/get_hooked">
  <p align="center">
    <img alt="Get Hooked! (logo)" src="https://github.com/user-attachments/assets/f1fb45f4-069a-4457-902a-4117bd590d46" width="200px">
  </p>
</a>

<br>

<p align="center">
  A Flutter package for sharing state between widgets, inspired by <a href="https://pub.dev/packages/riverpod"><b>riverpod</b></a> and <a href="https://pub.dev/packages/get_it"><b>get_it</b></a>.
</p>

<br><br>

<hr>

<br><br>


Given a generic `Data` class, let's see how different state management options compare.

```dart
@immutable
class Data {
  const Data(this.firstItem, [this.secondItem]);

  static const initial = Data('initial data');

  final Object firstItem;
  final Object? secondItem;
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
final getMyData = Get.value(Data.initial);
```

```dart
    final data = Use.watch(getMyData);
```

<br>

# Comparison

|                                       | `InheritedWidget` | provider | bloc | riverpod | get_it | get_hooked |
|---------------------------------------|:-----------------:|:--------:|:----:|:--------:|:------:|:----------:|
| shared state between widgets          |        ✅        |    ✅    |  ✅  |   ✅    |   ✅   |    ✅     |
| optimized for performance             |        ✅        |    ✅    |  ✅  |   ✅    |   ✅   |    ✅     |
| optimized for testability             |        ✅        |    ✅    |  ✅  |   ✅    |   ✅   |    ✅     |
| integrated with Hooks                 |        ❌        |    ❌    |  ❌  |   ✅    |   ❌   |    ✅     |
| avoids type overlap                   |        ❌        |    ❌    |  ❌  |   ✅    |   ❌   |    ✅     |
| no `context` needed                   |        ❌        |    ❌    |  ❌  |   ❌    |   ✅   |    ✅     |
| no boilerplate/code generation needed |        ❌        |    ✅    |  ❌  |   ❌    |   ✅   |    ✅     |
| supports scoping                      |        ✅        |    ✅    |  ✅  |   ✅    |   ✅   |    ❌     |
| supports lazy-loading                 |        ❌        |    ✅    |  ✅  |   ✅    |   ✅   |    ✅     |
| supports auto-dispose                 |        ❌        |    ❌    |  ❌  |   ✅    |   ✅   |    ✅     |
| supports `Animation`s                 |        ✅        |    ✅    |  ❌  |   ❌    |   ❌   |    ✅     |
| Flutter & non-Flutter variants        |        ❌        |    ❌    |  ✅  |   ✅    |   ✅   |    ❌     |

<br>

# Drawbacks

Let's start with the bad news.

<br>

### "Early Alpha" stage

Until the 1.0.0 release, you can expect breaking changes without prior warning.

<br>

### No scoping

Here, "scoping" is defined as a form of dependency injection, where a subset of widgets
(typically descendants of an `InheritedWidget`) receive data by different means.

```dart
  testWidgets('my test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [myDataProvider.overrideWith(TestData.new)],
        child: MyWidget(),
      ),
    );
  });
```

Even though **get_hooked** does not support this, widgets can be effectively tested via
global dependency injection.

```dart
  setUp(() {
    reconfigureMyData();
  });

  testWidgets('my test', (WidgetTester tester) async {
    await tester.pumpWidget(
      child: MyWidget(),
    );
  });
```
<sup>
  (This code snippet was written for the purpose of instruction;
  please disregard the glaring lack of a <a href="https://dart.dev/lints/unnecessary_lambdas"><b>tear-off</b></a>.)
</sup>

<br><br>

Testability is super important—please don't hesitate to [reach out](https://github.com/nate-thegrate/get_hooked/issues)
with any issues you run into.

> [!TIP]
> Global dependency injection is great for test coverage, but in some cases, a scoping mechanism
> might be desired as part of the app structure.
>
> The solution is: don't use **get_hooked** for it! Reusable "state" can be achieved with a
> `StatefulWidget` or `HookWidget`, and reusable "shared state" is possible through `InheritedWidget`s.\
> <sub>(Using both [**get_hooked**](https://pub.dev/packages/get_hooked) and [**provider**](https://pub.dev/packages/provider) is totally fine!)</sub>

<br>

### Flutter only

Many packages on [pub.dev](https://pub.dev/) have both a Flutter and a non-Flutter variant.

| Flutter | generic |
|:-:|:-:|
| [**flutter_riverpod**](https://pub.dev/packages/flutter_riverpod) | [**riverpod**](https://pub.dev/packages/riverpod) |
| [**flutter_bloc**](https://pub.dev/packages/flutter_bloc) | [**bloc**](https://pub.dev/packages/bloc) |
| [**watch_it**](https://pub.dev/packages/watch_it) | [**get_it**](https://pub.dev/packages/get_it) |

If you want a non-Flutter version of **get_hooked**, please [open an issue](https://github.com/nate-thegrate/get_hooked/issues)
and describe your use case.

<br>

# Overview

```dart
abstract class Get {
  ValueListenable get it;

  void update(Function function);
}
```

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
final getCount = Get.value(0);

class CounterButton extends HookWidget {
  const CounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {
        getCount.update((int value) => value + 1);
      },
      child: Text('counter value: ${Use.watch(getCount)}'),
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
final getCount = Get.value(0);

class CounterButton extends FilledButton {
  const CounterButton({super.key})
    : super(onPressed: _update, child: const HookBuilder(builder: _build));

  static void _update() {
    getCount.update((int value) => value + 1);
  }

  static Widget _build(BuildContext context) {
    return Text('counter value: ${Use.watch(getCount)}');
  }
}
```

<br>

## Detailed Overview

Here's a (less oversimplified) rundown of the Get API:

```dart
abstract interface class Get<T, V extends ValueListenable<T>> {
  /// [Get.value] is a pseudo-constructor: it creates a [Get] object,
  /// but it's structured as a `static` method instead of a `factory`
  /// so that it can expose the [GetValue<T>] return type.
  static GetValue<T> value<T>(T initial) {
    return GetValue<T>(initial);
  }

  V get it;

  void update(covariant Function updateFunction);
}

class GetValue<T> implements Get<T, ValueNotifier<T>> {
  GetValue(T initial) : it = ValueNotifier(initial);

  @override
  final ValueNotifier<T> it;

  @override
  void update(T Function(T previous) updateFunction) {
    it.value = updateFunction(it.value);
  }
}

/// The [Use] class is just a namespace for hook functions.
abstract final class Use {
  static T watch(Get<T, ValueListenable<T>> getObject) {
    return use(_GetHook(getObject));
  }
}
```

> [!CAUTION]
> **Do not access** `it` **directly:** get it through a Hook instead.\
> If a listener is added without automatically being removed, it can result in memory leaks,
> and calling `it.dispose()` would create problems for other widgets that are still using it.
>
> <br>
>
> Only use `it` in the following situations:
> - If another API accepts a `Listenable` object (and takes care of the listener automatically).
> - If you feel like it.

<br>

# Highlights

### Animations

This package makes it easier than ever before for a multitude of widgets to subscribe to a single
[`Animation`](https://main-api.flutter.dev/flutter/animation/Animation-class.html).

A tailor-made `TickerProvider` allows animations to repeatedly attach & detach from `BuildContext`s
based on how they're being used. A developer could prevent widget rebuilding entirely by
hooking them straight up to `RenderObject`s.

```dart
final getAnimation = Get.vsync();

class _RenderMyAnimation extends RenderSliverAnimatedOpacity {
  _RenderMyAnimation() : super(opacity: getAnimation.it);
}
```

<br>

### No boilerplate, no magic curtain

**get_hooked** is powered by Flutter's [ChangeNotifier](https://github.com/flutter/flutter/blob/d6918a48d3bb8c247efabea04b3361e1c4a40e02/packages/flutter/lib/src/foundation/change_notifier.dart#L138)
API (**riverpod** [does the same thing](https://github.com/rrousselGit/riverpod/blob/9e62837a9fb6741dc40728c6e28d0fd9d62452e3/packages/riverpod/lib/src/listenable.dart#L53)
under the hood) along with the concept of "Hooks" introduced by [React](https://react.dev/reference/react/hooks).

Want to find out what's going on?\
No breakpoints, no print statements. Just type the name.

![getFade](https://github.com/user-attachments/assets/9dbb65b3-c2c2-44eb-9870-28defeede0ad)


<br>

# Tips for success

### Follow the rules of Hooks

By convention, Hook function names start with `use`, and they should only be called inside a `HookWidget`'s build method.

The `HookWidget`'s `context` keeps track of:
1. How many hook functions the build method calls, and
2. the order they were called in.

Neither of these should change throughout the widget's lifetime.

For a more detailed explanation, see also:
- https://pub.dev/packages/flutter_hooks#rules
- https://react.dev/reference/rules/rules-of-hooks

<br>

### `Get` naming conventions

Just like how each Hook function starts with `use`, Get objects should start with `get`.

If the object is only intended to be used by widgets in the same `.dart` file, consider marking it with an annotation:

```dart
@visibleForTesting
final getAnimation = Get.vsync();
```

<br>

### Avoid using `it` directly

Unlike most `StatefulWidget` member variables, Get objects persist throughout changes to the app's state,
so a couple of missing `removeListener()` calls might create a noticeable performance impact.
Prefer calling `Use.watch()` to subscribe to updates.

When a `GetAsync` object's listeners are removed, it will automatically end its stream subscription and
restore the listenable to its default state. A listenable encapulated in a Get object should never call the
internal `ChangeNotifier.dispose()` method, since the object would be unusable from that point onward.

<br><br>

# Troubleshooting / FAQs

So far, not a single person has reached out because of a problem with this package.
Which means it's probably flawless!

<br><br>

<hr>

<br><br>

<a href="https://pub.dev/">
  <p align="center">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/9c57719d-7316-45ad-b83e-fb6d54b351f9">
      <img alt="get_hooked: try it once" src="https://github.com/user-attachments/assets/d151e872-028b-43fb-baf2-c5c6a01275f1">
    </picture>
  </p>
</a>
