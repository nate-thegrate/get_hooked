import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'default_animation_style.dart';
import 'styled_animation.dart';

/// A [TickerProvider] that also applies an [AnimationStyle].
///
/// Most implementations will use the style from the nearest ancestor
/// [DefaultAnimationStyle] widget.
abstract interface class Vsync implements TickerProvider {
  /// Registers the [StyledAnimation] object with this provider.
  ///
  /// [StyledAnimation.updateStyle] is called immediately, and then called again
  /// each time there's a relevant change.
  void registerAnimation(StyledAnimation<Object?> animation);

  /// Unregisters the [StyledAnimation] object with this provider.
  ///
  /// This is generally called when the animation is disposed of, or in rare cases where
  /// it switches between providers.
  void unregisterAnimation(StyledAnimation<Object?> animation);

  /// A "default" provider that never mutes its tickers.
  static const Vsync fallback = _Vsync();
}

class _Vsync implements Vsync {
  const _Vsync();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  @override
  void registerAnimation(StyledAnimation<Object?> animation) {
    animation.updateStyle(AnimationStyle());
  }

  @override
  void unregisterAnimation(StyledAnimation<Object?> animation) {}
}

typedef _StyleNotifier = ValueListenable<AnimationStyle>;
typedef _TickerMode = ValueListenable<bool>;
typedef _AnimationSet = Set<StyledAnimation<Object?>>;

/// A [BuildContext] that also functions as a ticker provider.
abstract interface class VsyncContext implements Vsync, BuildContext {}

/// A mixin that implements the [Vsync] interface.
mixin ElementVsync on Element implements VsyncContext {
  Set<Ticker>? _tickers;
  _TickerMode? _tickerMode;

  _AnimationSet? _animations;
  _StyleNotifier? _styleNotifier;

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = Ticker(onTick);
    (_tickers ??= {}).add(ticker);

    return ticker
      ..muted = (_tickerMode ??= TickerMode.getNotifier(this)..addListener(_updateTickers)).value;
  }

  @override
  void registerAnimation(StyledAnimation<Object?> animation) {
    (_animations ??= {}).add(animation);
    animation.updateStyle(
      (_styleNotifier ??= DefaultAnimationStyle.getNotifier(this)..addListener(_updateStyles))
          .value,
    );
  }

  @override
  void unregisterAnimation(StyledAnimation<Object?> animation) {
    _animations?.remove(animation);
  }

  void _updateTickers() {
    for (final Ticker ticker in _tickers ?? const {}) {
      ticker.muted = _tickerMode!.value;
    }
  }

  void _updateStyles() {
    for (final StyledAnimation<Object?> animation in _animations ?? const {}) {
      animation.updateStyle(_styleNotifier!.value);
    }
  }

  @override
  void activate() {
    super.activate();

    if (_tickerMode != null) {
      final _TickerMode newNotifier = TickerMode.getNotifier(this);
      if (newNotifier != _tickerMode) {
        _tickerMode?.removeListener(_updateTickers);
        _tickerMode = newNotifier..addListener(_updateTickers);
      }
    }

    if (_styleNotifier != null) {
      final _StyleNotifier newNotifier = DefaultAnimationStyle.getNotifier(this);
      if (newNotifier != _styleNotifier) {
        _styleNotifier?.removeListener(_updateStyles);
        _styleNotifier = newNotifier..addListener(_updateStyles);
      }
    }
  }

  @override
  void unmount() {
    for (final Ticker ticker in _tickers ?? const {}) {
      ticker.dispose();
    }
    _tickerMode?.removeListener(_updateTickers);
    _styleNotifier?.removeListener(_updateStyles);
    super.unmount();
  }
}
