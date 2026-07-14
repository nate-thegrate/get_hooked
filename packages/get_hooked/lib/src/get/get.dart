/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:collection_notifiers/collection_notifiers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/computed_notifier.dart';
import 'package:meta/meta.dart';

part 'src/dispose_guard.dart';
part 'src/query.dart';

/// Gives access to methods such as [ValueListenable.addListener].
extension GetHooked<V extends ValueListenable<Object?>> on Get<Object?, V> {
  /// Don't get hooked.
  V get hooked => _listenable;
}

/// Encapsulates a [ValueListenable] object with an interface for
/// easy updates and automatic lifecycle management.
extension type Get<T, V extends ValueListenable<T>>._(V _listenable) implements ValueListenable<T> {
  /// Don't add a listener directly!
  /// {@template get_hooked.dont}
  /// Prefer using [Ref.watch] or something similar.
  ///
  /// …or if you really gotta do it, use the `.hooked` getter.
  /// {@endtemplate}
  @protected
  @redeclare
  void get addListener {}

  /// Don't remove a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  @redeclare
  void get removeListener {}

  /// Encapsulates a [ValueNotifier].
  ///
  /// See also:
  ///
  /// - [Get.vsyncValue], which creates smooth transitions between values,
  ///   by using a [Vsync] to change gradually each animation frame.
  static GetValue<T> it<T>(T initialValue) => GetValue._(_ValueNotifier(initialValue));

  /// Encapsulates a [ListNotifier], and can be used as a [List] directly.
  static GetList<E> list<E>([Iterable<E> list = const []]) => GetList._(_ListNotifier(list));

  /// Encapsulates a [SetNotifier], and can be used as a [Set] directly.
  static GetSet<E> set<E>([Iterable<E> set = const {}]) => GetSet._(_SetNotifier(set));

  /// Encapsulates a [MapNotifier], and can be used as a [Map] directly.
  static GetMap<K, V> map<K, V>([Map<K, V> map = const {}]) => GetMap._(_MapNotifier(map));

  /// Encapsulates a [VsyncDouble].
  static GetVsyncDouble vsync({
    double? initialValue,
    Duration? duration,
    Duration? reverseDuration,
    AnimationBehavior? behavior,
    String? debugLabel,
    double? lowerBound,
    double? upperBound,
    bool bounded = true,
  }) {
    return GetVsyncDouble._(
      _VsyncDouble(
        value: initialValue,
        lowerBound: lowerBound ?? (bounded ? 0.0 : .negativeInfinity),
        upperBound: upperBound ?? (bounded ? 1.0 : .infinity),
        duration: duration,
        reverseDuration: reverseDuration,
        behavior: behavior ?? (bounded ? .normal : .preserve),
        debugLabel: debugLabel,
      ),
    );
  }

  /// Encapsulates a [ValueAnimation].
  static GetVsyncValue<T> vsyncValue<T>(
    T initialValue, {
    Duration? duration,
    Curve? curve,
    AnimationBehavior behavior = AnimationBehavior.normal,
    LerpCallback<T>? lerp,
    String? debugLabel,
  }) {
    return GetVsyncValue._(
      _ValueAnimation(
        initialValue,
        duration: duration,
        curve: curve,
        behavior: behavior,
        lerp: lerp,
        debugLabel: debugLabel,
      ),
    );
  }

  /// Encapsulates an [AsyncNotifier] with a preconfigured [futureCallback].
  static GetAsync<T> async<T>(AsyncValueGetter<T> futureCallback, {T? initialData}) {
    return GetAsync._(_AsyncNotifier(futureCallback: futureCallback, initialData: initialData));
  }

  /// Encapsulates an [AsyncNotifier] with a preconfigured [streamCallback].
  static GetAsync<T> stream<T>(
    StreamCallback<T> streamCallback, {
    T? initialData,
    bool cancelOnError = false,
    bool notifyOnCancel = false,
  }) {
    return GetAsync._(
      _AsyncNotifier(
        streamCallback: streamCallback,
        initialData: initialData,
        cancelOnError: cancelOnError,
        notifyOnCancel: notifyOnCancel,
      ),
    );
  }

  /// Encapsulates a [MediaQueryNotifier], allowing for efficient notifications
  /// based on screen metrics.
  ///
  /// The [view] and [viewFinder] parameters are used to disambiguate
  /// multi-window applications. See [MediaQueryNotifier] for more information.
  ///
  /// See also:
  ///  * [GetQuery.size] and [GetQuery.brightness],
  static GetQuery<T> mediaQuery<T>(
    T Function(MediaQueryData data) query, {
    FlutterView? view,
    ViewFinder? viewFinder,
  }) {
    return GetQuery._(_MediaQueryNotifier(query, view: view, viewFinder: viewFinder));
  }

  /// Encapsulates an [OverlayPortalController] that notifies when `show()` and `hide()`
  /// are called.
  static GetOverlay overlay({String? debugLabel}) {
    return GetOverlay._(OverlayNotifier(debugLabel: debugLabel));
  }

  /// Encapsulates a [Listenable] which notifies based on a [RefComputer] callback.
  static GetComputed<Result> compute<Result>(RefComputer<Result> callback) {
    return GetComputed._(ComputedNotifier(callback));
  }

  /// Encapsulates a [Listenable] which notifies by selecting from another listenable.
  ///
  /// {@tool snippet}
  /// This constructor is very similar to [Get.compute] but only watches a single other value,
  /// allowing the internal logic to be a bit more simple & efficient.
  ///
  /// The following have identical behavior:
  ///
  /// ```dart
  /// Get.compute((ref) => ref.watch(something).toString());
  ///
  /// Get.select(something, (value) => value.toString());
  /// ```
  /// {@end-tool}
  static GetSelection<Result, Input> select<Result, Input>(
    ValueListenable<Input> input,
    Result Function(Input value) selector,
  ) {
    return GetSelection._(
      input is VsyncValue<Input>
          ? _VsyncProxyNotifier(input, selector)
          : ProxyNotifier(input, selector),
    );
  }
}

class _VsyncProxyNotifier<Result, Input> extends ProxyNotifier<Result, Input>
    implements VsyncValue<Result> {
  _VsyncProxyNotifier(VsyncValue<Input> super.input, super.getValue);

  late final VsyncValue<Input> _vsync = input as VsyncValue<Input>;

  @override
  Vsync get vsync => _vsync.vsync;

  @override
  void resync(Vsync vsync) => _vsync.resync(vsync);

  @override
  ProxyNotifier<Result, Input> proxyWith(covariant VsyncValue<Input> newInput) {
    return _VsyncProxyNotifier(newInput, getValue);
  }
}

/// Encapsulates a [ValueNotifier].
extension type GetValue<T>._(ValueNotifier<T> _listenable) implements Get<T, ValueNotifier<T>> {
  // ignore: avoid_setters_without_getters, annotate_redeclares, false positive
  set value(T newValue) {
    _listenable.value = newValue;
  }

  /// Sets a new value and emits a notification.
  void emit(T? newValue) {
    if (newValue is T) _listenable.value = newValue;
  }
}

/// Toggles a boolean [GetValue].
extension ToggleValue on GetValue<bool> {
  /// Convenience method for toggling a [bool] value back and forth.
  ///
  /// The optional positional parameter allows it to be used in e.g. [Switch.onChanged].
  void toggle([_]) => emit(!value);
}

/// Encapsulates a [ListNotifier] and can be used as a [List] directly.
extension type GetList<E>._(ListNotifier<E> _listenable)
    implements List<E>, Get<List<E>, ListNotifier<E>> {
  /// Returns an [UnmodifiableListView] of this object.
  @redeclare
  List<E> get value => UnmodifiableListView(this);
}

/// Encapsulates a [SetNotifier] and can be used as a [Set] directly.
extension type GetSet<E>._(SetNotifier<E> _listenable)
    implements Set<E>, Get<Set<E>, SetNotifier<E>> {
  /// Returns an [UnmodifiableSetView] of this object.
  @redeclare
  Set<E> get value => UnmodifiableSetView(this);
}

/// Encapsulates a [MapNotifier] and can be used as a [Map] directly.
extension type GetMap<K, V>._(MapNotifier<K, V> _listenable)
    implements Map<K, V>, Get<Map<K, V>, MapNotifier<K, V>> {
  /// Returns an [UnmodifiableMapView] of this object.
  @redeclare
  Map<K, V> get value => UnmodifiableMapView(this);
}

typedef _Status = ValueListenable<AnimationStatus>;

/// Encapsulates the [Animator.status] listenable.
extension type GetAnimationStatus._(_Status _listenable) implements Get<AnimationStatus, _Status> {}

/// Encapsulates an [AnimationController].
extension type GetVsyncDouble._(VsyncDouble _listenable)
    implements VsyncDouble, Get<double, VsyncDouble> {
  /// Don't add a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  void get addListener {}

  /// Don't remove a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  void get removeListener {}

  @redeclare
  GetAnimationStatus get status => GetAnimationStatus._(_listenable.status);

  @redeclare
  GetValue<bool> get toggler => GetValue._(_listenable.toggler);
}

/// Encapsulates a [ValueAnimation].
extension type GetVsyncValue<T>._(ValueAnimation<T> _listenable)
    implements ValueAnimation<T>, Get<T, ValueAnimation<T>> {
  /// Don't add a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  void get addListener {}

  /// Don't remove a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  void get removeListener {}

  @redeclare
  GetAnimationStatus get status => GetAnimationStatus._(_listenable.status);
}

/// Encapsulates an [AsyncNotifier].
extension type GetAsync<T>._(AsyncNotifier<T> _listenable)
    implements Get<AsyncValue<T>, AsyncNotifier<T>> {}

/// Encapsulates an [OverlayPortalController].
extension type GetOverlay._(OverlayNotifier _listenable)
    implements OverlayPortalController, Get<bool, OverlayNotifier> {}

/// Encapsulates a [Listenable] which notifies based on a [RefComputer] callback.
extension type GetComputed<Result>._(ComputedNotifier<Result> _listenable)
    implements Get<Result, ValueListenable<Result>> {}

/// Encapsulates a [Listenable] which notifies based on a [RefComputer] callback.
extension type GetSelection<Result, Input>._(ProxyNotifier<Result, Input> _listenable)
    implements Get<Result, ValueListenable<Result>> {}
