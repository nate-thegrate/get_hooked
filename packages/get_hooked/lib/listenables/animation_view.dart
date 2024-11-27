import 'package:flutter/animation.dart';

/// Provides a "view" of an [Animation] object, without exposing methods for
/// adding/removing listeners.
extension type AnimationView<T>(Animation<T> _animation) implements Object {
  /// Whether this animation is running in either direction.
  ///
  /// By default, this value is equal to `status.isAnimating`, but
  /// [AnimationController] overrides this method so that its output
  /// depends on whether the controller is actively ticking.
  bool get isAnimating => _animation.isAnimating;

  /// Whether this animation is stopped at the end.
  bool get isCompleted => _animation.isCompleted;

  /// Whether this animation is stopped at the beginning.
  bool get isDismissed => _animation.isDismissed;

  /// Whether the current aim of the animation is toward completion.
  ///
  /// Specifically, returns `true` for [AnimationStatus.forward] or
  /// [AnimationStatus.completed], and `false` for
  /// [AnimationStatus.reverse] or [AnimationStatus.dismissed].
  bool get isForwardOrCompleted => _animation.isForwardOrCompleted;

  /// The current status of this animation.
  ///
  /// By default, this determines the results of [isAnimating],
  /// [isCompleted], and [isDismissed].
  /// Subclasses (such as [AnimationController]) may choose to [override]
  /// one or more of these getters.
  AnimationStatus get status => _animation.status;

  /// Provides a string describing the status of this object, but not including
  /// information about the object itself.
  ///
  /// This function is used by [Animation.toString] so that [Animation]
  /// subclasses can provide additional details while ensuring all [Animation]
  /// subclasses have a consistent [toString] style.
  ///
  /// The result of this function includes an icon describing the status of this
  /// [Animation] object:
  ///
  /// * "&#x25B6;": [AnimationStatus.forward] ([value] increasing)
  /// * "&#x25C0;": [AnimationStatus.reverse] ([value] decreasing)
  /// * "&#x23ED;": [AnimationStatus.completed] ([value] == 1.0)
  /// * "&#x23EE;": [AnimationStatus.dismissed] ([value] == 0.0)
  String toStringDetails() => _animation.toStringDetails();

  /// The current value of the animation.
  T get value => _animation.value;
}
