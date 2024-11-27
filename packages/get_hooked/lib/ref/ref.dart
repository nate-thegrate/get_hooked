import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';

import 'get/get.dart';
import 'hooked/hooked.dart';

export 'get/get.dart';
export 'hooked/hooked.dart';

part 'src/get_scope.dart';
part 'src/ref_hooks.dart';
part 'src/substitute.dart';

/// A callback that returns a [Get] object that wraps the specified [ValueListenable].
typedef GetGetter<V extends ValueRef> = ValueGetter<Get<Object?, V>>;

/// A namespace for [Hook] functions that interact with [Get] objects.
///
/// Unlike most Hook functions, `Ref` methods (such as [Ref.watch]) can either
/// be called inside [HookWidget.build] or in a [RenderHookWidget]'s method.
/// The latter allows a [RenderHookElement] to subscribe to updates and re-paint
/// a widget without ever rebuilding.
///
/// Additionally, if a [Substitution] is made in an ancestor [GetScope], these
/// methods will reference that new value automatically.
///
/// The `Ref` methods include:
///
/// - [Ref.watch], for subscribing to updates from a [Get] object.
/// - [Ref.read], to ensure that the scoped version of the [Get] object is being accessed,
///   if applicable.
/// - [Ref.vsync], to manage the ticker provider of a [GetVsync] object.
/// - [Ref.select], to select a single value from a complex [Get] object.\
///   Updates are only triggered when the selected value changes.
///   - A single value can be selected from multiple [Get] objects via
///     [Ref.select2], [Ref.select3], [Ref.select4], [Ref.select5],
///     [Ref.select6], [Ref.select7], [Ref.select8], or [Ref.select9].
///
/// {@tool snippet}
///
/// The [Ref.new] constructor can wrap a [Get] object, creating a [Substitution]
/// which can be passed into a [GetScope] (see also: [useSubstitute], to achieve
/// the same effect via a [Hook] function).
///
/// ```dart
/// GetScope(
///   substitutes: {Ref(getValue).sub(getOtherValue)},
///   child: widget.child,
/// );
/// ```
/// {@end-tool}
extension type Ref<V extends ValueRef>(Get<Object?, V> _get) implements Object {
  /// Uses a different [Get] object to create a [Substitution]
  /// which can be passed into a [GetScope].
  Substitution<V> sub(Get<Object?, V> newGet, {bool autoDispose = true}) {
    return subListenable(newGet.hooked, autoDispose: autoDispose);
  }

  /// Uses a [Listenable] (of the [Get] object's representation type)
  /// to create a [Substitution] which can be passed into a [GetScope].
  Substitution<V> subListenable(V newListenable, {bool autoDispose = true}) {
    return _SubEager(_get.hooked, newListenable, autoDispose: autoDispose);
  }

  /// Uses a callback (typically a constructor) to create a [Substitution]
  /// which can be passed into a [GetScope].
  ///
  /// This can be useful if, for example, a [StatelessWidget] builds a [GetScope]:
  /// passing a constructor tear-off such as [Get.vsync] is preferred to `Get.vsync()`,
  /// since the latter would create a new animation controller each time the widget is built.
  Substitution<V> subFactory(GetGetter<V> factory, {bool autoDispose = true}) {
    return _SubGetFactory(_get.hooked, factory, autoDispose: autoDispose);
  }

  /// Uses a callback (typically a constructor) to create a [Substitution]
  /// which can be passed into a [GetScope].
  ///
  /// This can be useful if, for example, a [StatelessWidget] builds a [GetScope]:
  /// passing a constructor tear-off like [ListNotifier.new] is preferred to `ListNotifier()`,
  /// since the latter would create a new [Listenable] object each time the widget is built.
  Substitution<V> subListenableFactory(ValueGetter<V> factory, {bool autoDispose = true}) {
    return _SubFactory(_get.hooked, factory, autoDispose: autoDispose);
  }

  /// This hook function returns a copy of the provided [Get] object,
  /// overriding it with any replacement in an ancestor [GetScope] if applicable.
  ///
  /// Unlike [Ref.watch], this method does not subscribe to any notifications
  /// from the object.
  static G read<G extends GetAny>(
    G get, {
    bool createDependency = true,
    bool throwIfMissing = false,
  }) {
    return GetScope.of(
      useContext(),
      get,
      createDependency: createDependency,
      throwIfMissing: throwIfMissing,
    );
  }

  /// This hook function watches a [Get] object
  /// and triggers a rebuild when it sends a notification.
  ///
  /// {@template get_hooked.Ref.watch}
  /// Must be called inside a [HookWidget.build] method.
  ///
  /// Notifications are not sent when [watching] is `false`
  /// (changes to this value will apply the next time the [HookWidget]
  /// is built).
  ///
  /// If a [GetVsync] object is passed, this hook will check if the
  /// [Vsync] is attached to a [BuildContext] (which is typically achieved
  /// via [Ref.vsync]) and throws an error if it fails. The check can be
  /// bypassed by setting [checkVsync] to `false`.
  ///
  /// By default, if an ancestor [GetScope] overrides the [Get] object's
  /// value, the new object is used instead. Setting [useScope] to `false`
  /// will ignore any overrides.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  /// * [Ref.select], which allows rebuilding only when a specified part
  ///   of the listenable's value changes.
  /// * [GetScope.of], for retrieving an [Override]'s new value outside of
  ///   a [HookWidget.build] method.
  static T watch<T>(
    Get<T, ValueListenable<T>> get, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'Ref.watch';
    if (useScope) get = GetScope.of(useContext(), get);

    _useVsyncValidation(get, checkVsync, label);

    return HookData.use(
      _Select1<T, T>(get.hooked, _selectAll<T>, watching: watching),
      debugLabel: label,
    );
  }

  /// Selects a value from a complex [Get] object and triggers a rebuild when
  /// the selected value changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select<Result, T>(
    Get<T, ValueListenable<T>> get,
    Result Function(T value) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'Ref.select';
    final BuildContext context = useContext();
    if (useScope) get = GetScope.of(context, get);

    _useVsyncValidation(get, checkVsync, label);

    return HookData.use(
      _Select1<Result, T>(get.hooked, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 2 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select2<Result, L1, L2>(
    L1 l1,
    L2 l2,
    Result Function(L1 l1, L2 l2) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select2';

    final BuildContext context = useContext();
    if (useScope) {
      l1 = l1.of(context);
      l2 = l2.of(context);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);

    return HookData.use(
      _Select2<Result, L1, L2>(l1, l2, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 3 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select3<Result, L1, L2, L3>(
    L1 l1,
    L2 l2,
    L3 l3,
    Result Function(L1 l1, L2 l2, L3 l3) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select3';

    final BuildContext context = useContext();
    if (useScope) {
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);

    return HookData.use(
      _Select3<Result, L1, L2, L3>(l1, l2, l3, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 4 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select4<Result, L1, L2, L3, L4>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    Result Function(L1 l1, L2 l2, L3 l3, L4 l4) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select4';

    final BuildContext context = useContext();
    if (useScope) {
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
      l4 = l4.of(context);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);
    _useVsyncValidation(l4, checkVsync, label);

    return HookData.use(
      _Select4(l1, l2, l3, l4, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 5 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select5<Result, L1, L2, L3, L4, L5>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select5';

    final BuildContext context = useContext();
    if (useScope) {
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
      l4 = l4.of(context);
      l5 = l5.of(context);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);
    _useVsyncValidation(l4, checkVsync, label);
    _useVsyncValidation(l5, checkVsync, label);

    return HookData.use(
      _Select5(l1, l2, l3, l4, l5, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 6 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select6<Result, L1, L2, L3, L4, L5, L6>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    L6 l6,
    Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select6';

    final BuildContext context = useContext();
    if (useScope) {
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
      l4 = l4.of(context);
      l5 = l5.of(context);
      l6 = l6.of(context);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);
    _useVsyncValidation(l4, checkVsync, label);
    _useVsyncValidation(l5, checkVsync, label);
    _useVsyncValidation(l6, checkVsync, label);

    return HookData.use(
      _Select6(l1, l2, l3, l4, l5, l6, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 7 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select7<Result, L1, L2, L3, L4, L5, L6, L7>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    L6 l6,
    L7 l7,
    Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select7';

    final BuildContext context = useContext();
    if (useScope) {
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
      l4 = l4.of(context);
      l5 = l5.of(context);
      l6 = l6.of(context);
      l7 = l7.of(context);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);
    _useVsyncValidation(l4, checkVsync, label);
    _useVsyncValidation(l5, checkVsync, label);
    _useVsyncValidation(l6, checkVsync, label);
    _useVsyncValidation(l7, checkVsync, label);

    return HookData.use(
      _Select7(l1, l2, l3, l4, l5, l6, l7, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 8 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select8<Result, L1, L2, L3, L4, L5, L6, L7, L8>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    L6 l6,
    L7 l7,
    L8 l8,
    Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7, L8 l8) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select8';

    final BuildContext context = useContext();
    if (useScope) {
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
      l4 = l4.of(context);
      l5 = l5.of(context);
      l6 = l6.of(context);
      l7 = l7.of(context);
      l8 = l8.of(context);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);
    _useVsyncValidation(l4, checkVsync, label);
    _useVsyncValidation(l5, checkVsync, label);
    _useVsyncValidation(l6, checkVsync, label);
    _useVsyncValidation(l7, checkVsync, label);
    _useVsyncValidation(l8, checkVsync, label);

    return HookData.use(
      _Select8(l1, l2, l3, l4, l5, l6, l7, l8, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 9 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select9<Result, L1, L2, L3, L4, L5, L6, L7, L8, L9>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    L6 l6,
    L7 l7,
    L8 l8,
    L9 l9,
    Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7, L8 l8, L9 l9) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select8';

    final BuildContext context = useContext();
    if (useScope) {
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
      l4 = l4.of(context);
      l5 = l5.of(context);
      l6 = l6.of(context);
      l7 = l7.of(context);
      l8 = l8.of(context);
      l9 = l9.of(context);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);
    _useVsyncValidation(l4, checkVsync, label);
    _useVsyncValidation(l5, checkVsync, label);
    _useVsyncValidation(l6, checkVsync, label);
    _useVsyncValidation(l7, checkVsync, label);
    _useVsyncValidation(l8, checkVsync, label);
    _useVsyncValidation(l9, checkVsync, label);

    return HookData.use(
      _Select9(l1, l2, l3, l4, l5, l6, l7, l8, l9, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Provides an interface for controlling a [GetVsync] animation,
  /// and optionally rebuilds when the animation sends a notification.
  ///
  /// If [watch] is true, each notification sent by the animation
  /// triggers a rebuild.
  static Controls vsync<Controls extends GetVsyncAny>(Controls get, {bool watch = false}) {
    final Controls scoped = GetScope.of(useContext(), get);
    useListenable(watch ? scoped.hooked : null);

    use(_VsyncHook.new, key: scoped, data: scoped, debugLabel: 'Ref.vsync');
    return scoped;
  }
}

extension<T> on T {
  T of(BuildContext context) {
    if (this case final GetAny get) {
      if (GetScope.of<GetAny>(context, get) case final T result) return result;
    }
    return this;
  }
}
