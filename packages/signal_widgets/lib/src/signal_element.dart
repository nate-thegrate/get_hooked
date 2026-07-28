import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_core.dart' as core;

/// Signature for a callback that computes a result while reading signals.
///
/// Signals accessed via `.value` during the callback are tracked; when they
/// change, the owning element recomputes without rebuilding the widget tree.
typedef SignalComputer<Result> = Result Function(BuildContext context);

/// Shared signal-subscription bookkeeping for elements that recompute instead
/// of rebuilding when signals change.
///
/// Any signal read via `.value` during [recompute] (while inside
/// [trackAndRecompute]) is subscribed; changes call [recompute] again.
mixin ElementSignal on Element {
  final _watch = <int, VoidCallback>{};
  bool _initializing = false;

  /// Subtypes implement this to apply computed values (e.g. onto a render object).
  ///
  /// Prefer reading signals with `.value` (not `.peek()`) so subscriptions are
  /// established.
  void recompute();

  /// Subscribes to [value] and schedules a recompute when it changes.
  void watchSignal(core.ReadonlySignal<Object?> value) {
    _watch.putIfAbsent(
      value.globalId,
      () => value.subscribe((_) {
        if (_initializing) return;
        if (!mounted) return;
        trackAndRecompute();
      }),
    );
  }

  void _updateWatch(Set<core.ReadonlySignal<Object?>> signals) {
    _initializing = true;
    try {
      final toRemove = <int>[];
      _watch.forEach((id, dispose) {
        if (!signals.any((s) => s.globalId == id)) {
          dispose();
          toRemove.add(id);
        }
      });
      for (final id in toRemove) {
        _watch.remove(id);
      }
      for (final signal in signals) {
        watchSignal(signal);
      }
    } finally {
      _initializing = false;
    }
  }

  /// Runs [body] while tracking signal reads, then syncs subscriptions.
  @protected
  T trackSignals<T>(T Function() body) {
    final signals = <core.ReadonlySignal<Object?>>{};
    final oldOnSignalRead = core.onSignalRead;
    core.onSignalRead = (signal) {
      if (signal is core.ReadonlySignal<Object?>) {
        signals.add(signal);
      }
    };

    try {
      return body();
    } finally {
      core.onSignalRead = oldOnSignalRead;
      if (signals.isEmpty) {
        clearSignalWatches();
      } else {
        _updateWatch(signals);
      }
    }
  }

  /// Runs [recompute] while tracking signal reads, then syncs subscriptions.
  @protected
  void trackAndRecompute() => trackSignals(recompute);

  /// Disposes all active signal subscriptions.
  @protected
  void clearSignalWatches() {
    for (final dispose in _watch.values) {
      dispose();
    }
    _watch.clear();
  }
}

/// A convenience base class for [SingleChildRenderObjectWidget] elements that
/// recompute render-object properties when signals change.
///
/// Mirrors the role of get_hooked's `SingleChildComputeElement`, but tracks
/// signals the same way `SignalElement` does: any signal read via `.value`
/// during [recompute] is subscribed, and changes call [recompute] again
/// instead of marking the element dirty for a full rebuild.
abstract class SingleChildSignalElement<Render extends RenderObject>
    extends SingleChildRenderObjectElement
    with ElementSignal {
  /// Creates an element that recomputes from signal subscriptions.
  SingleChildSignalElement(super.widget);

  /// The typed [renderObject] for this element.
  Render get renderer => renderObject as Render;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    trackAndRecompute();
  }

  @override
  void update(covariant SingleChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    trackAndRecompute();
  }

  @override
  void reassemble() {
    super.reassemble();
    clearSignalWatches();
    trackAndRecompute();
  }

  @override
  void unmount() {
    clearSignalWatches();
    super.unmount();
  }
}
