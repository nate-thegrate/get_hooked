import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_hooked/listenables/default_animation_style.dart';

import 'styled_animation.dart';

/// Creates an [Animation] using a [TickerProvider].
typedef VsyncBuilder<A extends Animation<Object?>> = A Function(Vsync vsync);

typedef _StyleNotifier = ValueListenable<AnimationStyle>;

/// A [TickerProvider] implementation that can arbitrarily
/// reconfigure its attached [BuildContext].
///
/// Setting a [context] allows the ticker to inherit from the ambient
/// [TickerMode]; if the context is null, the ticker will always be active.
class Vsync implements AnimationStyleProvider {
  /// Creates a [TickerProvider] that can arbitrarily
  /// reconfigure its attached [BuildContext].
  Vsync([BuildContext? context]) : _context = context;

  /// Optionally allows an object to keep track of its [Vsync].
  ///
  /// [Animation]s created via [Vsync.build] are automatically registered.
  @visibleForTesting
  static final cache = Expando<Vsync>();

  /// Creates an animation using the provided [VsyncBuilder],
  /// and registers it to the [Vsync.cache].
  static A build<A extends Animation<Object?>>(VsyncBuilder<A> builder, [BuildContext? context]) {
    final vsync = Vsync(context);
    final A animation = builder(vsync);
    cache[animation] = vsync;
    return animation;
  }

  /// The [VsyncTicker] being managed by this ticker provider.
  VsyncTicker? get ticker => _ticker;
  VsyncTicker? _ticker;
  set ticker(VsyncTicker? newTicker) {
    if (newTicker == _ticker) return;
    _ticker?.dispose();
    _ticker = newTicker;
  }

  /// The [BuildContext] associated with this `vsync`.
  BuildContext? get context => _context;
  BuildContext? _context;
  set context(BuildContext? newContext) {
    if (newContext == _context) return;

    if (newContext != null) {
      _ticker?.updateNotifier(newContext);
      updateStyleNotifier(newContext);
    } else {
      _ticker?.detach();
      _styleNotifier?.removeListener(_updateAnimation);
      _styleNotifier = null;
    }

    _context = newContext;
  }

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (context case BuildContext(mounted: false)) {
        throw FlutterError.fromParts([
          ErrorSummary('Vsync.createTicker() called after dispose().'),
          ErrorHint('Consider attaching an active BuildContext before creating a ticker.'),
        ]);
      }
      return true;
    }());

    return VsyncTicker(onTick, this);
  }

  StyledAnimation<Object?>? _animation;

  /// Ensures that this Vsync is subscribed to the relevant [ValueListenable].
  ///
  /// If the `context` argument is null, the context registered to this object
  /// is used instead.
  void updateStyleNotifier([BuildContext? context]) {
    context ??= _context;
    if (context == null) return;
    final _StyleNotifier newNotifier = DefaultAnimationStyle.getNotifier(context);
    if (newNotifier != _styleNotifier) {
      _styleNotifier?.removeListener(_updateAnimation);
      _styleNotifier = newNotifier..addListener(_updateAnimation);
    }
  }

  void _updateAnimation() {
    if (_styleNotifier?.value case final newStyle?) {
      _animation?.updateStyle(newStyle);
    }
  }

  _StyleNotifier? _styleNotifier;

  @override
  void registerAnimation(StyledAnimation<Object?> animation) {
    assert(() {
      if (_animation == null) return true;
      throw FlutterError.fromParts([
        ErrorSummary('Tried to register multiple animations to a Vsync.'),
        ErrorDescription('Vsync is designed to manage a single animation.'),
      ]);
    }());
    _animation = animation..updateStyle(_styleNotifier?.value ?? AnimationStyle());
  }
}

/// A [Ticker] created by a [Vsync].
@visibleForTesting
class VsyncTicker extends Ticker {
  /// Creates a [VsyncTicker].
  VsyncTicker(super.onTick, this.vsync) {
    vsync.ticker = this;
    if (vsync.context case final context? when context.mounted) {
      updateNotifier(context);
    }
  }

  /// The [Vsync] associated with this ticker.
  final Vsync vsync;

  /// A [ValueListenable] that notifies when the [muted] status should change.
  ValueListenable<bool> enabledNotifier = const _UnsetNotifier();

  /// Updates the [enabledNotifier] if its identity changes
  /// (may happen if an ancestor [TickerMode] is added to/removed from the tree.)
  void updateNotifier(BuildContext context) {
    final ValueListenable<bool> newNotifier = TickerMode.getNotifier(context);
    if (newNotifier != enabledNotifier) {
      enabledNotifier.removeListener(_listener);
      enabledNotifier = newNotifier..addListener(_listener);
      _listener();
    }
  }

  /// Sets the ticker as "no longer managed by a [BuildContext]".
  void detach() {
    muted = false;
    stop(canceled: true);
    enabledNotifier.removeListener(_listener);
  }

  void _listener() {
    muted = !enabledNotifier.value;
  }

  @override
  TickerFuture start() {
    assert(() {
      if (vsync.context case BuildContext(mounted: false)) {
        throw FlutterError.fromParts([
          ErrorSummary('Ticker.start() called after dispose().'),
          ErrorHint(
            'Consider setting an active context for its vsync before starting the ticker.',
          ),
        ]);
      }
      return true;
    }());

    return super.start();
  }

  @override
  void dispose() {
    enabledNotifier.removeListener(_listener);
    super.dispose();
    vsync._ticker = null;
  }
}

class _UnsetNotifier implements ValueListenable<bool> {
  /// Throws unless it's [removeListener] being called.
  const _UnsetNotifier();

  @override
  Never get value => throw StateError('Ticker notifier is not set');

  @override
  Never addListener(VoidCallback listener) => value;

  @override
  void removeListener(VoidCallback listener) {}
}
