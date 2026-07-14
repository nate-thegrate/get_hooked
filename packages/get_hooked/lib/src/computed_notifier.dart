import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/scope.dart';

/// {@template get_hooked.SchedulerBuilding}
/// Provides an estimate regarding whether a build is imminent.
///
/// This allows classes such as [ComputedNotifier] to decide whether to
/// fire immediately or use [Future.microtask] to mitigate duplicate notifications.
/// {@endtemplate}
extension SchedulerBuilding on WidgetsBinding {
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

typedef _V = ValueListenable<Object?>;
typedef _Animation = VsyncValue<Object?>;

/// A [ValueListenable] object that computes its result using a [RefComputer] callback.
class ComputedNotifier<Result> with ChangeNotifier implements Ref, VsyncValue<Result> {
  /// Initializes class fields.
  ///
  /// If [_scope] is non-null, [Ref.watch] and [Ref.select] calls targeting
  /// the map keys will subscribe to the respective values.
  ComputedNotifier(this.compute, {this.concurrent, this._scope, this._vsync = Vsync.fallback});

  /// The function on which this notifier is based.
  final RefComputer<Result> compute;
  Result _compute() {
    final Result result = compute(this);
    if (kDebugMode && result is Future) {
      throw FlutterError.fromParts([
        ErrorSummary('A computed notifier returned a Future.'),
        ErrorDescription('Computed notifier callbacks should always be synchronous.'),
        ErrorHint(
          'Consider removing the `async` from the callback and/or '
          "double-checking whether the function's return value is a Future.",
        ),
      ]);
    }

    _needsDependencies = false;
    return result;
  }

  bool _needsDependencies = true;

  /// Shouldn't ever change. To change the substitutions, throw away this notifier
  /// and make a new one.
  final SubMap<_V>? _scope;

  @override
  Result get value => hasListeners ? _value : _value = _compute();
  late Result _value = _compute();

  /// Whether re-computations should happen concurrently or via [scheduleMicrotask].
  ///
  /// If null, a custom heuristic defined in `_scheduleUpdate` is used instead.
  final bool? concurrent;
  bool _updateInProgress = false;
  void _scheduleUpdate() {
    if (_updateInProgress) return;
    if (concurrent ?? (_dependencyCount <= 1 || WidgetsBinding.instance.building)) {
      return _performUpdate();
    }
    _updateInProgress = true;
    scheduleMicrotask(_performUpdate);
  }

  void _performUpdate() {
    _updateInProgress = false;
    final Result newValue = compute(this);
    if (_value == newValue) return;

    _value = newValue;
    notifyListeners();
  }

  @override
  Vsync get vsync => _vsync;
  Vsync _vsync;

  @override
  void resync(Vsync vsync) {
    if (vsync == _vsync) return;
    if (hasListeners && _vsync != Vsync.fallback) _animations?.forEach(_vsync.registry.remove);
    _vsync = vsync;
    if (hasListeners && _vsync != Vsync.fallback) _animations?.forEach(_vsync.registry.add);
  }

  Set<_Animation>? _animations;
  void _autoVsync(Listenable listenable) {
    if (listenable is _Animation) (_animations ??= {}).add(listenable);
  }

  final Set<Listenable> _dependencies = {};
  Listenable get _listenable => Listenable.merge(_dependencies);
  final _selectors = <(Listenable, VoidCallback)>{};
  int get _dependencyCount => _dependencies.length + _selectors.length;

  @override
  T watch<T>(ValueListenable<T> listenable, {bool autoVsync = true, bool useScope = true}) {
    if (useScope) {
      if (_scope?.maybeGet(listenable) case final scoped?) {
        listenable = scoped;
        autoVsync = false;
      }
    }
    if (_needsDependencies) {
      _dependencies.add(listenable);
      if (autoVsync) _autoVsync(listenable);
    }
    return listenable.value;
  }

  @override
  R select<R, T>(
    ValueListenable<T> listenable,
    R Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    if (useScope) {
      if (_scope?.maybeGet(listenable) case final scoped?) {
        listenable = scoped;
        autoVsync = false;
      }
    }
    if (_needsDependencies) {
      if (autoVsync) _autoVsync(listenable);

      R current = selector(listenable.value);
      void select() {
        final R newValue = selector(listenable.value);
        if (newValue == current) return;
        current = newValue;
        _scheduleUpdate();
      }

      _selectors.add((listenable, select));
    }
    return selector(listenable.value);
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      _value = _compute();
      _listenable.addListener(_scheduleUpdate);
      for (final (listenable, listener) in _selectors) {
        listenable.addListener(listener);
      }
      _animations?.forEach(vsync.registry.add);
    }
    super.addListener(listener);
  }

  void _deactivate() {
    _listenable.removeListener(_scheduleUpdate);
    for (final (listenable, listener) in _selectors) {
      listenable.removeListener(listener);
    }
    _animations?.forEach(vsync.registry.remove);
    _needsDependencies = true;
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) _deactivate();
  }

  /// Returns a copy of this notifier that uses the provided values.
  ComputedNotifier<Result> scopeWith(SubMap<ValueListenable<Object?>> map, Vsync vsync) {
    return ComputedNotifier(compute, concurrent: concurrent, scope: map, vsync: vsync);
  }

  @override
  void dispose() {
    _deactivate();
    super.dispose();
  }
}
