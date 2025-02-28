import 'package:flutter/animation.dart';

import 'styled_animation.dart';
import 'vsync.dart';

/// Gives access to the [VsyncRegistry] within an [Vsync] declaration.
extension VsyncRegistryExtension on Vsync {
  /// A [VsyncRegistry] interface of this provider.
  VsyncRegistry get registry => VsyncRegistry._(this);
}

/// Since [AnimationController] does not expose its ticker provider field,
/// this registry was created to track animations' [Vsync]s.
extension type VsyncRegistry._(Vsync _vsync) {
  /// Assigns a [vsync] to an [animation], if it's registered and hasn't already been assigned one.
  bool add(VsyncRef animation) {
    if (animation.vsync == Vsync.fallback) {
      animation.resync(_vsync);
      return true;
    }
    return false;
  }

  /// Resets the animation to the fallback (perpetually unmuted) ticker provider.
  bool remove(VsyncRef animation) {
    if (animation.vsync == _vsync) {
      animation.resync(Vsync.fallback);
      return true;
    }
    return false;
  }
}
