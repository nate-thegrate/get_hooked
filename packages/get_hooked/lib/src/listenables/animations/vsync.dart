/// @docImport 'package:flutter/scheduler.dart';
/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'default_animation_style.dart';

/// A [ValueListenable] attached to a [TickerProvider].
///
/// Generally this interface is implemented by [Animation] objects,
/// but it can be used in other ways (e.g. a single object that manages multiple animations).
///
/// See also: [VsyncRegistry], which can automatically [resync] these objects
/// when ticker providers are introduced.
abstract interface class VsyncValue<T> implements ValueListenable<T> {
  /// The listenable's associated [Vsync].
  Vsync get vsync;

  /// Called to update the listenable's associated [Vsync].
  void resync(Vsync vsync);
}

/// Interface for an [Animation] that uses a [Vsync] to manage its [Ticker] and [AnimationStyle].
///
/// Notably, this class does not implement Flutter's [Animation] interface:
/// subclasses can choose to include functionality such as [Animation.addStatusListener]
/// or to have a more barebones [ValueListenable] API surface.
abstract interface class StyledAnimation<T> implements VsyncValue<T> {
  /// Applies the [newStyle] to the animation.
  void updateStyle(AnimationStyle newStyle);
}

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
  Ticker createTicker(TickerCallback onTick) => _FallbackTicker(onTick);

  @override
  void registerAnimation(StyledAnimation<Object?> animation) {
    animation.updateStyle(AnimationStyle());
  }

  @override
  void unregisterAnimation(StyledAnimation<Object?> animation) {}
}

class _FallbackTicker extends Ticker {
  _FallbackTicker(super.onTick);

  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

/// A [BuildContext] that also functions as a ticker provider.
abstract interface class VsyncContext implements Vsync, BuildContext {}
