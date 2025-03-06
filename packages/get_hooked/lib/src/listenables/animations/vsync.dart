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

/// A [BuildContext] that also functions as a ticker provider.
abstract interface class VsyncContext implements Vsync, BuildContext {}
