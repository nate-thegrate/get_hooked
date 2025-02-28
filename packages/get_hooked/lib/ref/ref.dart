import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/bug_report.dart';
import 'package:get_hooked/listenables.dart';

import 'get/get.dart';
import 'hooked/hooked.dart';

export 'get/get.dart' hide ComputedNoScope;
export 'hooked/hooked.dart';

part 'src/get_scope.dart';
part 'src/ref_hooks.dart';
part 'src/substitute.dart';

/// A callback that returns a [Get] object that wraps the specified [ValueListenable].
typedef GetGetter<V extends ValueRef> = ValueGetter<GetV<V>>;

/// An animation object is synced to an [Vsync] via the first build context
/// that uses it.
void _autoVsync(GetAny get) {
  if (get is GetVsyncAny && (get is AnimationController || get is StyledAnimation<Object?>)) {
    use(_VsyncHook.new, key: get, data: get, debugLabel: 'auto-vsync');
  }
}

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
extension type Ref<V extends ValueRef>(V _get) implements Object {
  /// Uses a [Listenable] (of the [Get] object's representation type)
  /// to create a [Substitution] which can be passed into a [GetScope].
  Substitution<V> sub(V newListenable, {bool autoDispose = true}) {
    return _SubEager(_get, newListenable, autoDispose: autoDispose);
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
    return _SubFactory(_get, factory, autoDispose: autoDispose);
  }

  /// Uses a callback (typically a constructor) to create a [Substitution]
  /// which can be passed into a [GetScope].
  ///
  /// This can be useful if, for example, a [StatelessWidget] builds a [GetScope]:
  /// passing a constructor tear-off such as [Get.vsync] is preferred to `Get.vsync()`,
  /// since the latter would create a new animation controller each time the widget is built.
  Substitution<V> subGetGetter(GetGetter<V> factory, {bool autoDispose = true}) {
    return _SubGetFactory(_get, factory, autoDispose: autoDispose);
  }

  /// If a [Substitution] was made, returns the widget that made it.
  ///
  /// The result could be:
  ///
  /// - A [GetScope], if the substitution was made there
  /// - A [HookWidget] that called [useSubstitute]
  /// - Another widget that used a `Ref` instance method such as [Ref.sub]
  /// - `null`, if no substitution was made
  ///
  /// The result is always `null` in profile & release mode.
  Widget? debugSubWidget(BuildContext context) {
    Widget? result;
    assert(() {
      final ValueRef? scopedGet = GetScope.maybeOf(context, _get);
      if (scopedGet == null) return true;
      final GetScope scope = context.findAncestorStateOfType<_GetScopeState>()!.widget;
      for (final SubAny sub in scope.substitutes) {
        if (sub.ref == _get) {
          result = scope;
          return true;
        }
      }
      final container =
          context.getElementForInheritedWidgetOfExactType<_OverrideContainer>()!
              as _OverrideContainerElement;

      for (final MapEntry(key: context, value: map) in container.clientSubstitutes.entries) {
        for (final ValueRef key in map.keys) {
          if (key == _get) {
            result = context.widget;
            return true;
          }
        }
      }

      throw StateError(
        'The object $_get was substituted with $scopedGet, '
        'but the substitution was not found.\n'
        '$bugReport',
      );
    }());

    return result;
  }

  /// This hook function returns a copy of the provided [Get] object,
  /// overriding it with any replacement in an ancestor [GetScope] if applicable.
  ///
  /// Unlike [Ref.watch], this method does not subscribe to any notifications
  /// from the object; instead, by default it creates a dependency on the ancestor
  /// scope (so that it receives notifications if a relevant [Substitution] is made).
  static G read<G extends GetAny>(
    G get, {
    bool createDependency = true,
    bool throwIfMissing = false,
    bool autoVsync = true,
  }) {
    final G result = GetScope.of(
      useContext(),
      get,
      createDependency: createDependency,
      throwIfMissing: throwIfMissing,
    );
    if (autoVsync) _autoVsync(get);

    return result;
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
    bool autoVsync = true,
    bool useScope = true,
  }) {
    if (useScope) get = GetScope.of(useContext(), get);
    if (autoVsync) _autoVsync(get);
    return useValueListenable(get, watching: watching);
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
    bool autoVsync = true,
    bool useScope = true,
  }) {
    if (useScope) get = GetScope.of(useContext(), get);

    return HookData.use(
      _GetSelect<Result, T>(get.hooked, selector, watching: watching),
      debugLabel: 'Ref.select',
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
}
