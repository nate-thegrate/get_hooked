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
    // Sadly, a microtask scheduled within a transient callback
    // is not reliably executed during midFrameMicrotasks.
    SchedulerPhase.transientCallbacks ||
    SchedulerPhase.midFrameMicrotasks ||
    SchedulerPhase.persistentCallbacks => true,
    SchedulerPhase.postFrameCallbacks || SchedulerPhase.idle => false,
  };
}

/// Can be extended to support an arbitrary number of listenables via [Listenable.merge].
abstract class ProxyNotifierBase<T> with ChangeNotifier implements ValueListenable<T> {
  /// Initializes fields for subclasses.
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
