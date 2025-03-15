/// @docImport 'package:flutter/material.dart';
library;

import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:collection_notifiers/collection_notifiers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/hook_ref/hook_ref.dart';
import 'package:get_hooked/src/substitution/substitution.dart';
import 'package:meta/meta.dart';

part 'src/computed.dart';
part 'src/dispose_guard.dart';
part 'src/scoped_get.dart';

typedef _V = ValueListenable<Object?>;

/// Allows the hook functions defined in [ref] to access
/// a [Get] object's [ValueListenable].
//
// ignore: library_private_types_in_public_api, I'm a rule-breaker
extension GetHooked<V extends _V> on Get<Object?, V> {
  /// Don't get hooked.
  V get hooked => _hooked;
}

/// Encapsulates a [ValueListenable] object with an interface for
/// easy updates and automatic lifecycle management.
extension type Get<T, V extends ValueListenable<T>>._(V _hooked) implements ValueListenable<T> {
  /// Don't add a listener directly!
  /// {@template get_hooked.dont}
  /// Prefer using [ref.watch] or something similar.
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

  /// Encapsulates an [AnimationController].
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
        lowerBound: lowerBound ?? (bounded ? 0.0 : double.negativeInfinity),
        upperBound: upperBound ?? (bounded ? 1.0 : double.infinity),
        duration: duration,
        reverseDuration: reverseDuration,
        behavior: behavior ?? (bounded ? AnimationBehavior.normal : AnimationBehavior.preserve),
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
  }) {
    return GetVsyncValue._(
      _ValueAnimation(
        initialValue: initialValue,
        duration: duration,
        curve: curve,
        behavior: behavior,
        lerp: lerp,
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
  static GetQuery<T> mediaQuery<T>(
    T Function(MediaQueryData data) query, {
    FlutterView? view,
    ViewFinder? viewFinder,
  }) {
    return GetQuery._(_MediaQueryNotifier(query, view: view, viewFinder: viewFinder));
  }

  /// Encapsulates a [Listenable] which notifies based on a [RefComputer] callback.
  static GetComputed<Result> compute<Result>(RefComputer<Result> callback) {
    return GetComputed._(ComputedNoScope(callback));
  }
}

/// Encapsulates a [ValueNotifier].
extension type GetValue<T>._(ValueNotifier<T> _hooked) implements Get<T, ValueNotifier<T>> {
  // ignore: annotate_redeclares, false positive
  set value(T newValue) {
    _hooked.value = newValue;
  }

  /// Sets a new value and emits a notification.
  void emit(T? newValue) {
    if (newValue is T) _hooked.value = newValue;
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
extension type GetList<E>._(ListNotifier<E> _hooked)
    implements List<E>, Get<List<E>, ListNotifier<E>> {
  /// Returns an [UnmodifiableListView] of this object.
  @redeclare
  List<E> get value => UnmodifiableListView(this);
}

/// Encapsulates a [SetNotifier] and can be used as a [Set] directly.
extension type GetSet<E>._(SetNotifier<E> _hooked)
    implements Set<E>, Get<Set<E>, SetNotifier<E>> {
  /// Returns an [UnmodifiableSetView] of this object.
  @redeclare
  Set<E> get value => UnmodifiableSetView(this);
}

/// Encapsulates a [MapNotifier] and can be used as a [Map] directly.
extension type GetMap<K, V>._(MapNotifier<K, V> _hooked)
    implements Map<K, V>, Get<Map<K, V>, MapNotifier<K, V>> {
  /// Returns an [UnmodifiableMapView] of this object.
  @redeclare
  Map<K, V> get value => UnmodifiableMapView(this);
}

typedef _Status = ValueListenable<AnimationStatus>;

/// Encapsulates the [Animator.status] listenable.
extension type GetAnimationStatus._(_Status _hooked) implements Get<AnimationStatus, _Status> {}

/// Encapsulates an [AnimationController].
extension type GetVsyncDouble._(VsyncDouble _hooked)
    implements VsyncDouble, Get<double, VsyncDouble> {
  /// Don't add a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  @redeclare
  void get addListener {}

  /// Don't remove a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  @redeclare
  void get removeListener {}

  @redeclare
  GetAnimationStatus get status => GetAnimationStatus._(_hooked.status);
}

/// Encapsulates a [ValueAnimation].
extension type GetVsyncValue<T>._(ValueAnimation<T> _hooked)
    implements ValueAnimation<T>, Get<T, ValueAnimation<T>> {
  /// Don't add a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  @redeclare
  void get addListener {}

  /// Don't remove a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  @redeclare
  void get removeListener {}

  @redeclare
  GetAnimationStatus get status => GetAnimationStatus._(_hooked.status);
}

/// Encapsulates an [AsyncNotifier].
extension type GetAsync<T>._(AsyncNotifier<T> _hooked) implements Get<T?, AsyncNotifier<T>> {}

/// Encapsulates a [MediaQueryNotifier].
extension type GetQuery<T>._(MediaQueryNotifier<T> _hooked)
    implements Get<T, MediaQueryNotifier<T>> {
  /// {@macro get_hooked.MediaQueryNotifier.assignView}
  void assignView(FlutterView view) => _hooked.assignView(view);
}

/// Encapsulates a [Listenable] which notifies based on a [RefComputer] callback.
extension type GetComputed<Result>._(ComputedNoScope<Result> _hooked)
    implements Get<Result, ValueListenable<Result>> {}
