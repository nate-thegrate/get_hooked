/// @docImport 'package:flutter/scheduler.dart';
library;

import 'dart:ui';

import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/src/bug_report.dart';

import 'animator.dart';

/// A variant of [AnimationController] that implements the [VsyncValue] and [StyledAnimation]
/// interfaces. (An [Animation] object can be obtained via [toAnimation].)
///
/// (See [Animator] for more information.)
class VsyncDouble extends Animator<double> {
  /// Initializes fields.
  VsyncDouble({
    double? value,
    super.vsync,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    super.duration,
    super.curve,
    super.reverseDuration,
    super.reverseCurve,
    super.behavior,
    super.debugLabel,
  }) : super(
         initialValue: value ?? lowerBound,
         initialStatus:
             value == lowerBound
                 ? AnimationStatus.dismissed
                 : value == upperBound
                 ? AnimationStatus.completed
                 : AnimationStatus.forward,
       );

  /// The value at which this animation is deemed to be dismissed.
  final double lowerBound;

  /// The value at which this animation is deemed to be completed.
  final double upperBound;

  bool _forward = true;

  @override
  set value(double newValue) {
    stop();
    _internalSetValue(newValue);
  }

  void _internalSetValue(double newValue) {
    super.value = clampDouble(newValue, lowerBound, upperBound);
    statusNotifier.value =
        value == lowerBound
            ? AnimationStatus.dismissed
            : value == upperBound
            ? AnimationStatus.completed
            : _forward
            ? AnimationStatus.forward
            : AnimationStatus.reverse;
  }

  Simulation? _simulation;

  /// Drives the animation from its current value to the given target, "forward".
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  ///
  /// During the animation, [status] is reported as [AnimationStatus.forward]
  /// regardless of whether `target` > [value] or not. At the end of the
  /// animation, when `target` is reached, [status] is reported as
  /// [AnimationStatus.completed].
  ///
  /// If the `target` argument is the same as the current [value] of the
  /// animation, then this won't animate, and the returned [TickerFuture] will
  /// be already complete.
  @override
  TickerFuture animateTo(double target, {double? from, Duration? duration, Curve? curve}) {
    assert(debugCheckDisposal('animateTo'));
    stop();

    _forward = true;
    if (duration != null) this.duration = duration;
    if (curve != null) this.curve = curve;

    return _runSimulation(
      _InterpolationSimulation(
        from ?? value,
        upperBound,
        this.duration,
        this.curve,
        behavior.enableAnimations ? 1.0 : 0.05,
      ),
    );
  }

  /// Drives the animation from its current value to the given target, "backward".
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  ///
  /// During the animation, [status] is reported as [AnimationStatus.reverse]
  /// regardless of whether `target` < [value] or not. At the end of the
  /// animation, when `target` is reached, [status] is reported as
  /// [AnimationStatus.dismissed].
  ///
  /// If the `target` argument is the same as the current [value] of the
  /// animation, then this won't animate, and the returned [TickerFuture] will
  /// be already complete.
  TickerFuture animateBack(double target, {Duration? duration, Curve? curve}) {
    assert(debugCheckDisposal('animateBack'));
    stop();

    _forward = false;
    if (duration != null) this.duration = duration;
    if (curve != null) this.curve = curve;

    return _runSimulation(
      _InterpolationSimulation(
        value,
        upperBound,
        this.duration,
        this.curve,
        behavior.enableAnimations ? 1.0 : 0.05,
      ),
    );
  }

  /// Drives the animation according to the given simulation.
  ///
  /// {@template flutter.animation.AnimationController.animateWith}
  /// The values from the simulation are clamped to the [lowerBound] and
  /// [upperBound]. To avoid this, consider creating the [AnimationController]
  /// using the [AnimationController.unbounded] constructor.
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  /// {@endtemplate}
  ///
  /// The [status] is always [AnimationStatus.forward] for the entire duration
  /// of the simulation.
  ///
  /// See also:
  ///
  ///  * [animateBackWith], which is like this method but the status is always
  ///    [AnimationStatus.reverse].
  TickerFuture animateWith(Simulation simulation) {
    assert(debugCheckDisposal('animateWith'));
    stop();

    _forward = true;
    return _runSimulation(simulation);
  }

  /// Drives the animation according to the given simulation with a [status] of
  /// [AnimationStatus.reverse].
  ///
  /// {@macro flutter.animation.AnimationController.animateWith}
  ///
  /// The [status] is always [AnimationStatus.reverse] for the entire duration
  /// of the simulation.
  ///
  /// See also:
  ///
  ///  * [animateWith], which is like this method but the status is always
  ///    [AnimationStatus.forward].
  TickerFuture animateBackWith(Simulation simulation) {
    assert(debugCheckDisposal('animateBackWith'));
    stop();

    _forward = false;
    return _runSimulation(simulation);
  }

  static final SpringDescription _flingSpring = SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 500.0,
  );

  static const Tolerance _tolerance = Tolerance(velocity: double.infinity, distance: 0.01);

  /// Drives the animation with a spring (within [lowerBound] and [upperBound])
  /// and initial velocity.
  ///
  /// If velocity is positive, the animation will complete, otherwise it will
  /// dismiss. The velocity is specified in units per second. If the
  /// [SemanticsBinding.disableAnimations] flag is set, the velocity is somewhat
  /// arbitrarily multiplied by 200.
  ///
  /// The [springDescription] parameter can be used to specify a custom
  /// [SpringType.criticallyDamped] or [SpringType.overDamped] spring with which
  /// to drive the animation. By default, a [SpringType.criticallyDamped] spring
  /// is used. See [SpringDescription.withDampingRatio] for how to create a
  /// suitable [SpringDescription].
  ///
  /// The resulting spring simulation cannot be of type [SpringType.underDamped];
  /// such a spring would oscillate rather than fling.
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  TickerFuture fling({
    double velocity = 1.0,
    SpringDescription? springDescription,
    AnimationBehavior? animationBehavior,
  }) {
    assert(debugCheckDisposal('fling'));
    stop();

    _forward = !velocity.isNegative;
    final simulation = SpringSimulation(
      springDescription ?? _flingSpring,
      value,
      _forward ? upperBound + _tolerance.distance : lowerBound - _tolerance.distance,
      velocity * ((animationBehavior ?? behavior).enableAnimations ? 1.0 : 200.0),
    )..tolerance = _tolerance;
    assert(
      simulation.type != SpringType.underDamped,
      'The specified spring simulation is of type SpringType.underDamped.\n'
      'An underdamped spring results in oscillation rather than a fling. '
      'Consider specifying a different springDescription, or use animateWith() '
      'with an explicit SpringSimulation if an underdamped spring is intentional.',
    );
    return _runSimulation(simulation);
  }

  /// Starts running this animation forwards (towards the end).
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// If [from] is non-null, it will be set as the current [value] before running
  /// the animation.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  ///
  /// During the animation, [status] is reported as [AnimationStatus.forward],
  /// which switches to [AnimationStatus.completed] when [upperBound] is
  /// reached at the end of the animation.
  TickerFuture forward({double? from}) {
    assert(debugCheckDisposal('forward'));
    stop();

    return _runSimulation(
      _InterpolationSimulation(
        value,
        upperBound,
        duration * ((upperBound - value) / (upperBound - lowerBound)),
        Curves.linear,
        behavior.enableAnimations ? 1.0 : 0.05,
      ),
    );
  }

  /// Starts running this animation in reverse (towards the beginning).
  ///
  /// Returns a [TickerFuture] that completes when the animation is dismissed.
  ///
  /// If [from] is non-null, it will be set as the current [value] before running
  /// the animation.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  ///
  /// During the animation, [status] is reported as [AnimationStatus.reverse],
  /// which switches to [AnimationStatus.dismissed] when [lowerBound] is
  /// reached at the end of the animation.
  TickerFuture reverse({double? from}) {
    assert(debugCheckDisposal('reverse'));
    stop();

    return _runSimulation(
      _InterpolationSimulation(
        value,
        lowerBound,
        duration * ((value - lowerBound) / (upperBound - lowerBound)),
        Curves.linear,
        behavior.enableAnimations ? 1.0 : 0.05,
      ),
    );
  }

  /// Toggles the direction of this animation, based on whether its status is forward
  /// or completed.
  ///
  /// Specifically, this function acts the same way as [reverse] if the [status] is
  /// either [AnimationStatus.forward] or [AnimationStatus.completed], and acts as
  /// [forward] for [AnimationStatus.reverse] or [AnimationStatus.dismissed].
  ///
  /// If [forward] is non-null, it determines the animation's direction.
  /// If it matches the current direction (and the animation is running),
  /// this method will return the existing future instead of canceling and resuming
  /// the [Ticker].
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  TickerFuture toggle({bool? forward}) {
    assert(debugCheckDisposal('toggle'));
    if (forward != null && forward == _forward) {
      if (_tickerFuture case final tickerFuture?) return tickerFuture;
    }

    return (forward ?? !_forward) ? this.forward() : reverse();
  }

  /// Starts running this animation in the forward direction, and
  /// restarts the animation when it completes.
  ///
  /// Defaults to repeating between the [lowerBound] and [upperBound] of the
  /// [AnimationController] when no explicit value is set for [min] and [max].
  ///
  /// With [reverse] set to true, instead of always starting over at [min]
  /// the starting value will alternate between [min] and [max] values on each
  /// repeat. The [status] will be reported as [AnimationStatus.reverse] when
  /// the animation runs from [max] to [min].
  ///
  /// Each run of the animation will have a duration of `period`. If `period` is not
  /// provided, [duration] will be used instead, which has to be set before [repeat] is
  /// called either in the constructor or later by using the [duration] setter.
  ///
  /// If a value is passed to [count], the animation will perform that many
  /// iterations before stopping. Otherwise, the animation repeats indefinitely.
  ///
  /// Returns a [TickerFuture] that never completes, unless a [count] is specified.
  /// The [TickerFuture.orCancel] future completes with an error when the animation is
  /// stopped (e.g. with [stop]).
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  TickerFuture repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
    int? count,
  }) {
    assert(debugCheckDisposal('repeat'));
    stop();
    min ??= lowerBound;
    max ??= upperBound;
    period ??= duration;
    assert(max >= min);
    assert(max <= upperBound && min >= lowerBound);
    assert(
      count == null || count > 0,
      'If the count is non-null, it should be greater than zero.',
    );
    return _runSimulation(
      _RepeatingSimulation(value, min, max, reverse, period, _directionSetter, count),
    );
  }

  // ignore: use_setters_to_change_properties, used as a tear-off
  void _directionSetter({required bool forward}) {
    _forward = forward;
  }

  /// Sets the controller's value to [lowerBound], stopping the animation (if
  /// in progress), and resetting to its beginning point, or dismissed state.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  ///
  /// See also:
  ///
  ///  * [value], which can be explicitly set to a specific value as desired.
  ///  * [forward], which starts the animation in the forward direction.
  ///  * [stop], which aborts the animation without changing its value or status
  ///    and without dispatching any notifications other than completing or
  ///    canceling the [TickerFuture].
  void reset() {
    assert(debugCheckDisposal('reset'));
    value = lowerBound;
  }

  /// The rate of change of [value] per second.
  ///
  /// If [isAnimating] is false, then [value] is not changing and the rate of
  /// change is zero.

  double get velocity {
    if ((_simulation, lastElapsedDuration) case (final simulation?, final duration?)) {
      return simulation.dx(duration.inMicroseconds / Duration.microsecondsPerSecond);
    }
    return 0.0;
  }

  TickerFuture? _tickerFuture;

  TickerFuture _runSimulation(Simulation simulation) {
    _simulation = simulation;
    final TickerFuture tickerFuture = _tickerFuture = start();
    _internalSetValue(simulation.x(0.0));
    return tickerFuture;
  }

  @override
  void stop({bool canceled = true}) {
    super.stop(canceled: canceled);
    _tickerFuture = null;
  }

  @override
  void tick(Duration elapsed) {
    if (_simulation case final simulation?) {
      final double time = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
      _internalSetValue(simulation.x(time));
      if (!simulation.isDone(time)) return;
    } else {
      assert(throw StateError('VsyncDouble.tick() called with a null duration.\n$bugReport'));
    }
    stop(canceled: false);
  }
}

class _InterpolationSimulation extends Simulation {
  _InterpolationSimulation(this._begin, this._end, Duration duration, this._curve, double scale)
    : assert(duration.inMicroseconds > 0),
      _durationInSeconds = (duration.inMicroseconds * scale) / Duration.microsecondsPerSecond;

  final double _durationInSeconds;
  final double _begin;
  final double _end;
  final Curve _curve;

  @override
  double x(double timeInSeconds) {
    final double t = clampDouble(timeInSeconds / _durationInSeconds, 0.0, 1.0);
    return switch (t) {
      0.0 => _begin,
      1.0 => _end,
      _ => _begin + (_end - _begin) * _curve.transform(t),
    };
  }

  @override
  double dx(double timeInSeconds) {
    final double epsilon = tolerance.time;
    return (x(timeInSeconds + epsilon) - x(timeInSeconds - epsilon)) / (2 * epsilon);
  }

  @override
  bool isDone(double timeInSeconds) => timeInSeconds > _durationInSeconds;
}

typedef _DirectionSetter = void Function({required bool forward});

class _RepeatingSimulation extends Simulation {
  _RepeatingSimulation(
    double initialValue,
    this.min,
    this.max,
    // ignore: avoid_positional_boolean_parameters, my preference :)
    this.reverse,
    Duration period,
    this.directionSetter,
    this.count,
  ) : assert(
        count == null || count > 0,
        'If the count is non-null, it should be greater than zero.',
      ),
      _periodInSeconds = period.inMicroseconds / Duration.microsecondsPerSecond,
      _initialT =
          (max == min)
              ? 0.0
              : ((clampDouble(initialValue, min, max) - min) / (max - min)) *
                  (period.inMicroseconds / Duration.microsecondsPerSecond) {
    assert(_periodInSeconds > 0.0);
    assert(_initialT >= 0.0);
  }

  final double min;
  final double max;
  final bool reverse;
  final int? count;
  final _DirectionSetter directionSetter;

  final double _periodInSeconds;
  final double _initialT;

  late final double _exitTimeInSeconds = (count! * _periodInSeconds) - _initialT;

  @override
  double x(double timeInSeconds) {
    assert(timeInSeconds >= 0.0);

    final double totalTimeInSeconds = timeInSeconds + _initialT;
    final double t = (totalTimeInSeconds / _periodInSeconds) % 1.0;
    final bool forward = !reverse || (totalTimeInSeconds ~/ _periodInSeconds).isEven;
    directionSetter(forward: forward);

    final (double a, double b) = forward ? (min, max) : (max, min);
    return lerpDouble(a, b, t)!;
  }

  @override
  double dx(double timeInSeconds) => (max - min) / _periodInSeconds;

  @override
  bool isDone(double timeInSeconds) {
    return count != null && (timeInSeconds >= _exitTimeInSeconds);
  }
}
