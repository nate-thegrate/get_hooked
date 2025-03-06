/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/scoped_selection.dart';
import 'package:get_hooked/src/substitution/substitution.dart';

import 'get/get.dart';
import 'hooked/hooked.dart';

export 'get/get.dart' hide ComputedNoScope;
export 'hooked/hooked.dart';

part 'src/get_scope.dart';
part 'src/ref_hooks.dart';
part 'src/substitute.dart';

/// A [ComputeRef] that works inside a [HookWidget.build].
///
/// A globally-scoped function can call [use] or [HookRef.watch],
/// as long as that function is only called while a hook widget is building.
const HookRef ref = _HookRef();

class _HookRef implements HookRef {
  const _HookRef();

  /// This hook function returns a copy of the provided [Get] object,
  /// overriding it with any replacement in an ancestor [GetScope] if applicable.
  ///
  /// Unlike [ref.watch], this method does not subscribe to any notifications
  /// from the object; instead, by default it creates a dependency on the ancestor
  /// scope (so that it receives notifications if a relevant [Substitution] is made).
  G read<G extends ValueListenable<Object?>>(
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
  /// via [ref.vsync]) and throws an error if it fails. The check can be
  /// bypassed by setting [checkVsync] to `false`.
  ///
  /// By default, if an ancestor [GetScope] overrides the [Get] object's
  /// value, the new object is used instead. Setting [useScope] to `false`
  /// will ignore any overrides.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  /// * [ref.select], which allows rebuilding only when a specified part
  ///   of the listenable's value changes.
  /// * [GetScope.of], for retrieving an [Override]'s new value outside of
  ///   a [HookWidget.build] method.
  @override
  T watch<T>(
    ValueListenable<T> get, {
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
  @override
  Result select<Result, T>(
    ValueListenable<T> get,
    Result Function(T value) selector, {
    bool watching = true,
    bool autoVsync = true,
    bool useScope = true,
  }) {
    if (useScope) get = GetScope.of(useContext(), get);

    return HookData.use(
      _GetSelect<Result, T>(get, selector, watching: watching),
      debugLabel: 'Ref.select',
    );
  }

  /// Returns the provided [RefComputer]'s output and triggers a rebuild
  /// when any of the values referenced by [ComputeRef.watch] change.
  @override
  Result compute<Result>(RefComputer<Result> computeCallback) {
    return use(
      _RefComputerHook.new,
      key: null,
      data: computeCallback,
      debugLabel: 'compute<$Result>',
    );
  }
}

/// An animation object is synced to an [Vsync] via the first build context
/// that uses it.
void _autoVsync(Listenable get) {
  if (get is VsyncValue<Object?>) {
    use(_VsyncHook.new, key: get, data: get, debugLabel: 'auto-vsync');
  }
}
