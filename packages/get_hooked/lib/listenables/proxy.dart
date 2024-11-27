// ignore_for_file: public_member_api_docs, as much as I'd love to document l1, l2, l3, l4…

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// {@template get_hooked.SchedulerBuilding}
/// Provides an estimate regarding whether a build is imminent.
///
/// This allows classes such as [ProxyNotifier] to decide whether to
/// fire immediately or use [Future.microtask] to mitigate duplicate notifications.
/// {@endtemplate}
extension SchedulerBuilding on SchedulerBinding {
  /// {@macro get_hooked.SchedulerBuilding}
  bool get building => switch (schedulerPhase) {
    SchedulerPhase.midFrameMicrotasks || SchedulerPhase.persistentCallbacks => true,
    SchedulerPhase.postFrameCallbacks ||
    SchedulerPhase.transientCallbacks ||
    SchedulerPhase.idle =>
      false,
  };
}

extension type ProxyListenable._(Listenable listenable) implements Listenable {
  // ignore: inference_failure_on_untyped_parameter, they're dynamic
  ProxyListenable([l1, l2, l3, l4, l5, l6, l7, l8, l9])
    : listenable = Listenable.merge(() sync* {
        if (l1 is Listenable) yield l1;
        if (l2 is Listenable) yield l2;
        if (l3 is Listenable) yield l3;
        if (l4 is Listenable) yield l4;
        if (l5 is Listenable) yield l5;
        if (l6 is Listenable) yield l6;
        if (l7 is Listenable) yield l7;
        if (l8 is Listenable) yield l8;
        if (l9 is Listenable) yield l9;
      }());
}

abstract class ProxyNotifierBase<T> with ChangeNotifier implements ValueListenable<T> {
  ProxyNotifierBase(this.listenable, {required T value, this.concurrent = false})
    : _value = value;

  /// Whether this notifier should immediately update its value
  /// upon receiving a notification.
  ///
  /// Set as `true` when a single [Listenable] is proxied.
  /// Otherwise the behavior depends on the [SchedulerPhase],
  /// ensuring that dependents are notified on time while avoiding
  /// duplicate notifications when possible.
  bool? concurrent;

  /// The input [Listenable] object.
  final Listenable listenable;

  T _value;

  bool _updateInProgress = false;
  void _scheduleUpdate() {
    if (_updateInProgress) return;
    if (this.concurrent ?? SchedulerBinding.instance.building) {
      return _performUpdate();
    }
    _updateInProgress = true;
    Future.microtask(_performUpdate);
  }

  void _performUpdate() {
    final T oldValue = _value;
    final T newValue = _value = value;

    if (newValue != oldValue) notifyListeners();
    _updateInProgress = false;
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      listenable.addListener(_scheduleUpdate);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      listenable.removeListener(_scheduleUpdate);
    }
  }
}

/// Transforms any [Listenable] into a [ValueListenable].
class ProxyNotifier<T, L extends Listenable> extends ProxyNotifierBase<T> {
  /// Transforms any [Listenable] into a [ValueListenable].
  ProxyNotifier(L super.listenable, this.getValue)
    : super(value: getValue(listenable), concurrent: true);

  /// Retrieves a [value] using the provided [listenable].
  final T Function(L) getValue;

  @override
  T get value => getValue(listenable as L);
}

/// Transforms a pair of values into a [ValueListenable].
///
/// At least 1 of these two values should be a [Listenable],
/// so that the `ProxyNotifier` knows when to send its own notifications.
class ProxyNotifier2<T, L1, L2> extends ProxyNotifierBase<T> {
  /// Transforms a pair of values into a [ValueListenable].
  ///
  /// At least 1 of these two values should be a [Listenable],
  /// so that the `ProxyNotifier` knows when to send its own notifications.
  ProxyNotifier2(this.l1, this.l2, this.getValue, {super.concurrent})
    : super(ProxyListenable(l1, l2), value: getValue(l1, l2));

  /// Retrieves a [value] using the provided [getValue] function with the three values.
  final T Function(L1 l1, L2 l2) getValue;

  final L1 l1;
  final L2 l2;

  @override
  T get value => getValue(l1, l2);
}

/// Transforms three values into a [ValueListenable].
///
/// At least 1 of these three values should be a [Listenable],
/// so that the `ProxyNotifier` knows when to send its own notifications.
class ProxyNotifier3<T, L1, L2, L3> extends ProxyNotifierBase<T> {
  /// Transforms three values into a [ValueListenable].
  ///
  /// At least 1 of these three values should be a [Listenable],
  /// so that the `ProxyNotifier` knows when to send its own notifications.
  ProxyNotifier3(this.l1, this.l2, this.l3, this.getValue, {super.concurrent})
    : super(ProxyListenable(l1, l2, l3), value: getValue(l1, l2, l3));

  /// Retrieves a [value] using the provided [getValue] function with the three values.
  final T Function(L1 l1, L2 l2, L3 l3) getValue;

  final L1 l1;
  final L2 l2;
  final L3 l3;

  @override
  T get value => getValue(l1, l2, l3);
}

/// Transforms four values into a [ValueListenable].
///
/// At least 1 of these four values should be a [Listenable],
/// so that the `ProxyNotifier` knows when to send its own notifications.
class ProxyNotifier4<T, L1, L2, L3, L4> extends ProxyNotifierBase<T> {
  /// Transforms four values into a [ValueListenable].
  ///
  /// At least 1 of these four values should be a [Listenable],
  /// so that the `ProxyNotifier` knows when to send its own notifications.
  ProxyNotifier4(this.l1, this.l2, this.l3, this.l4, this.getValue, {super.concurrent})
    : super(ProxyListenable(l1, l2, l3, l4), value: getValue(l1, l2, l3, l4));

  /// Retrieves a [value] using the provided [getValue] function with four values.
  final T Function(L1 l1, L2 l2, L3 l3, L4 l4) getValue;

  final L1 l1;
  final L2 l2;
  final L3 l3;
  final L4 l4;

  @override
  T get value => getValue(l1, l2, l3, l4);
}

/// Transforms five values into a [ValueListenable].
///
/// At least 1 of these five values should be a [Listenable],
/// so that the `ProxyNotifier` knows when to send its own notifications.
class ProxyNotifier5<T, L1, L2, L3, L4, L5> extends ProxyNotifierBase<T> {
  /// Transforms five values into a [ValueListenable].
  ///
  /// At least 1 of these five values should be a [Listenable],
  /// so that the `ProxyNotifier` knows when to send its own notifications.
  ProxyNotifier5(this.l1, this.l2, this.l3, this.l4, this.l5, this.getValue, {super.concurrent})
    : super(ProxyListenable(l1, l2, l3, l4, l5), value: getValue(l1, l2, l3, l4, l5));

  /// Retrieves a [value] using the provided [getValue] function with five values.
  final T Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5) getValue;

  final L1 l1;
  final L2 l2;
  final L3 l3;
  final L4 l4;
  final L5 l5;

  @override
  T get value => getValue(l1, l2, l3, l4, l5);
}

/// Transforms six values into a [ValueListenable].
///
/// At least 1 of these six values should be a [Listenable],
/// so that the `ProxyNotifier` knows when to send its own notifications.
class ProxyNotifier6<T, L1, L2, L3, L4, L5, L6> extends ProxyNotifierBase<T> {
  /// Transforms six values into a [ValueListenable].
  ///
  /// At least 1 of these six values should be a [Listenable],
  /// so that the `ProxyNotifier` knows when to send its own notifications.
  ProxyNotifier6(
    this.l1,
    this.l2,
    this.l3,
    this.l4,
    this.l5,
    this.l6,
    this.getValue, {
    super.concurrent,
  }) : super(ProxyListenable(l1, l2, l3, l4, l5, l6), value: getValue(l1, l2, l3, l4, l5, l6));

  /// Retrieves a [value] using the provided [getValue] function with six values.
  final T Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6) getValue;

  final L1 l1;
  final L2 l2;
  final L3 l3;
  final L4 l4;
  final L5 l5;
  final L6 l6;

  @override
  T get value => getValue(l1, l2, l3, l4, l5, l6);
}

/// Transforms seven values into a [ValueListenable].
///
/// At least 1 of these seven values should be a [Listenable],
/// so that the `ProxyNotifier` knows when to send its own notifications.
class ProxyNotifier7<T, L1, L2, L3, L4, L5, L6, L7> extends ProxyNotifierBase<T> {
  /// Transforms seven values into a [ValueListenable].
  ///
  /// At least 1 of these seven values should be a [Listenable],
  /// so that the `ProxyNotifier` knows when to send its own notifications.
  ProxyNotifier7(
    this.l1,
    this.l2,
    this.l3,
    this.l4,
    this.l5,
    this.l6,
    this.l7,
    this.getValue, {
    super.concurrent,
  }) : super(
         ProxyListenable(l1, l2, l3, l4, l5, l6, l7),
         value: getValue(l1, l2, l3, l4, l5, l6, l7),
       );

  /// Retrieves a [value] using the provided [getValue] function with seven values.
  final T Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7) getValue;

  final L1 l1;
  final L2 l2;
  final L3 l3;
  final L4 l4;
  final L5 l5;
  final L6 l6;
  final L7 l7;

  @override
  T get value => getValue(l1, l2, l3, l4, l5, l6, l7);
}

/// Transforms eight values into a [ValueListenable].
///
/// At least 1 of these eight values should be a [Listenable],
/// so that the `ProxyNotifier` knows when to send its own notifications.
class ProxyNotifier8<T, L1, L2, L3, L4, L5, L6, L7, L8> extends ProxyNotifierBase<T> {
  /// Transforms eight values into a [ValueListenable].
  ///
  /// At least 1 of these eight values should be a [Listenable],
  /// so that the `ProxyNotifier` knows when to send its own notifications.
  ProxyNotifier8(
    this.l1,
    this.l2,
    this.l3,
    this.l4,
    this.l5,
    this.l6,
    this.l7,
    this.l8,
    this.getValue, {
    super.concurrent,
  }) : super(
         ProxyListenable(l1, l2, l3, l4, l5, l6, l7, l8),
         value: getValue(l1, l2, l3, l4, l5, l6, l7, l8),
       );

  /// Retrieves a [value] using the provided [getValue] function with eight values.
  final T Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7, L8 l8) getValue;

  final L1 l1;
  final L2 l2;
  final L3 l3;
  final L4 l4;
  final L5 l5;
  final L6 l6;
  final L7 l7;
  final L8 l8;

  @override
  T get value => getValue(l1, l2, l3, l4, l5, l6, l7, l8);
}

/// Transforms nine values into a [ValueListenable].
///
/// At least 1 of these nine values should be a [Listenable],
/// so that the `ProxyNotifier` knows when to send its own notifications.
class ProxyNotifier9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9> extends ProxyNotifierBase<T> {
  /// Transforms nine values into a [ValueListenable].
  ///
  /// At least 1 of these nine values should be a [Listenable],
  /// so that the `ProxyNotifier` knows when to send its own notifications.
  ProxyNotifier9(
    this.l1,
    this.l2,
    this.l3,
    this.l4,
    this.l5,
    this.l6,
    this.l7,
    this.l8,
    this.l9,
    this.getValue, {
    super.concurrent,
  }) : super(
         ProxyListenable(l1, l2, l3, l4, l5, l6, l7, l8, l9),
         value: getValue(l1, l2, l3, l4, l5, l6, l7, l8, l9),
       );

  /// Retrieves a [value] using the provided [getValue] function with nine values.
  final T Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7, L8 l8, L9 l9) getValue;

  final L1 l1;
  final L2 l2;
  final L3 l3;
  final L4 l4;
  final L5 l5;
  final L6 l6;
  final L7 l7;
  final L8 l8;
  final L9 l9;

  @override
  T get value => getValue(l1, l2, l3, l4, l5, l6, l7, l8, l9);
}
