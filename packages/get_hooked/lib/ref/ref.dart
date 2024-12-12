import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';

import 'get/get.dart';
import 'hooked/hooked.dart';

export 'get/get.dart' hide ComputedNoScope, ComputedScoped;
export 'hooked/hooked.dart';

part 'src/get_scope.dart';
part 'src/ref_hooks.dart';
part 'src/substitute.dart';

/// A callback that returns a [Get] object that wraps the specified [ValueListenable].
typedef GetGetter<V extends ValueRef> = ValueGetter<GetV<V>>;

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
extension type Ref<V extends ValueRef>(GetV<V> _get) implements Object {
  /// Uses a [Listenable] (of the [Get] object's representation type)
  /// to create a [Substitution] which can be passed into a [GetScope].
  Substitution<V> sub(V newListenable, {bool autoDispose = true}) {
    return _SubEager(_get.hooked, newListenable, autoDispose: autoDispose);
  }

  /// Uses a different [Get] object to create a [Substitution]
  /// which can be passed into a [GetScope].
  Substitution<V> subGet(GetV<V> newGet, {bool autoDispose = true}) {
    return sub(newGet.hooked, autoDispose: autoDispose);
  }

  /// Uses a callback (typically a constructor) to create a [Substitution]
  /// which can be passed into a [GetScope].
  ///
  /// This can be useful if, for example, a [StatelessWidget] builds a [GetScope]:
  /// passing a constructor tear-off like [ListNotifier.new] is preferred to `ListNotifier()`,
  /// since the latter would create a new [Listenable] object each time the widget is built.
  Substitution<V> subGetter(ValueGetter<V> factory, {bool autoDispose = true}) {
    return _SubFactory(_get.hooked, factory, autoDispose: autoDispose);
  }

  /// Uses a callback (typically a constructor) to create a [Substitution]
  /// which can be passed into a [GetScope].
  ///
  /// This can be useful if, for example, a [StatelessWidget] builds a [GetScope]:
  /// passing a constructor tear-off such as [Get.vsync] is preferred to `Get.vsync()`,
  /// since the latter would create a new animation controller each time the widget is built.
  Substitution<V> subGetGetter(GetGetter<V> factory, {bool autoDispose = true}) {
    return _SubGetFactory(_get.hooked, factory, autoDispose: autoDispose);
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
    GetT<T> get, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'Ref.watch';
    if (useScope) get = GetScope.of(useContext(), get);

    _useVsyncValidation(get, checkVsync, label);

    return HookData.use(
      _GetSelect<T, T>(get.hooked, _selectAll<T>, watching: watching),
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
    GetT<T> get,
    Result Function(T value) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'Ref.select';
    if (useScope) get = GetScope.of(useContext(), get);

    _useVsyncValidation(get, checkVsync, label);

    return HookData.use(
      _GetSelect<Result, T>(get.hooked, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Returns the provided [RefComputer]'s output and triggers a rebuild
  /// when any of the values referenced by [ComputeRef.watch] change.
  static Result compute<Result>(RefComputer<Result> computeCallback) {
    return use(
      _RefComputerHook.new,
      key: null,
      data: computeCallback,
      debugLabel: 'compute<$Result>',
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
