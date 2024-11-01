// ignore_for_file: avoid_setters_without_getters, getters are defined in the extension type

part of '../get_hooked.dart';

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

/// A version of [AnimationController] that doesn't expose methods like
/// [Animation.addListener] or [AnimationController.dispose].
extension type VsyncControls._(AnimationController _controller) implements AnimationView<double> {
  set value(double newValue) {
    _controller.value = newValue;
  }

  /// See [AnimationController.animateTo].
  TickerFuture animateTo(double target, {Duration? duration, Curve curve = Curves.linear}) {
    return _controller.animateTo(target, duration: duration, curve: curve);
  }

  /// See [AnimationController.animateBack].
  TickerFuture animateBack(double target, {Duration? duration, Curve curve = Curves.linear}) {
    return _controller.animateBack(target, duration: duration, curve: curve);
  }

  /// See [AnimationController.animateWith].
  TickerFuture animateWith(Simulation simulation) {
    return _controller.animateWith(simulation);
  }

  /// See [AnimationController.animationBehavior].
  AnimationBehavior get animationBehavior => _controller.animationBehavior;

  /// See [AnimationController.drive].
  @optionalTypeArgs
  Animation<U> drive<U>(Animatable<U> child) => _controller.drive(child);

  /// See [AnimationController.stop].
  void stop({bool canceled = true}) => _controller.stop(canceled: canceled);

  /// See [AnimationController.reset].
  void reset() => _controller.reset();

  /// See [AnimationController.forward].
  TickerFuture forward({double? from}) => _controller.forward(from: from);

  /// See [AnimationController.reverse].
  TickerFuture reverse({double? from}) => _controller.reverse(from: from);

  /// See [AnimationController.toggle].
  TickerFuture toggle({double? from}) => _controller.toggle(from: from);

  /// See [AnimationController.repeat].
  TickerFuture repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
    int? count,
  }) {
    // dart format off
    return _controller.repeat(
      min: min,
      max: max,
      reverse: reverse,
      period: period,
      count: count,
    );
    // dart format on
  }

  /// See [AnimationController.fling].
  TickerFuture fling({
    double velocity = 1.0,
    SpringDescription? springDescription,
    AnimationBehavior? animationBehavior,
  }) {
    return _controller.fling(
      velocity: velocity,
      springDescription: springDescription,
      animationBehavior: animationBehavior,
    );
  }

  /// See [AnimationController.lastElapsedDuration].
  Duration? get lastElapsedDuration => _controller.lastElapsedDuration;

  /// See [AnimationController.lowerBound].
  double get lowerBound => _controller.lowerBound;

  /// See [AnimationController.upperBound].
  double get upperBound => _controller.upperBound;

  /// See [AnimationController.velocity].
  double get velocity => _controller.velocity;
}

/// A version of [ValueAnimation] that doesn't expose methods like
/// [Animation.addListener] or [ValueAnimation.dispose].
extension type VsyncValueControls<T>._(ValueAnimation<T> _animation) implements AnimationView<T> {
  set value(T newValue) {
    _animation.value = newValue;
  }

  /// See [ValueAnimation.duration].
  Duration get duration => _animation.duration;
  set duration(Duration newValue) {
    _animation.duration = newValue;
  }

  /// See [ValueAnimation.curve].
  Curve get curve => _animation.curve;
  set curve(Curve newValue) {
    _animation.curve = curve;
  }

  /// See [ValueAnimation.drive].
  @optionalTypeArgs
  Animation<U> drive<U>(Animatable<U> child) => _animation.drive(child);

  /// See [ValueAnimation.animateTo].
  TickerFuture animateTo(T target, {T? from, Duration? duration, Curve? curve}) {
    return _animation.animateTo(target, from: from, duration: duration, curve: curve);
  }

  /// See [ValueAnimation.jumpTo].
  void jumpTo(T target) => _animation.jumpTo(target);

  /// See [ValueAnimation.stop].
  void stop({bool canceled = true}) => _animation.stop(canceled: canceled);

  /// See [ValueAnimation.animationBehavior].
  AnimationBehavior get animationBehavior => _animation.animationBehavior;
}
