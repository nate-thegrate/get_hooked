// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
/// @docImport 'package:flutter_test/flutter_test.dart';
library;

import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

export 'package:flutter/physics.dart' show Simulation, SpringDescription;
export 'package:flutter/scheduler.dart' show TickerFuture, TickerProvider;

// Examples can assume:
// late AnimationController _controller, fadeAnimationController, sizeAnimationController;
// late ValueAnimation<dynamic> _animation;
// late dynamic newValue;
// late bool dismissed;
// void setState(VoidCallback fn) { }

extension on AnimationBehavior {
  /// Whether animations should be enabled, based on the configured behavior
  /// and the [AccessibilityFeatures.disableAnimations] flag.
  bool get enableAnimations => switch (this) {
    AnimationBehavior.normal => !SemanticsBinding.instance.disableAnimations,
    AnimationBehavior.preserve => true,
  };
}

abstract class _AnimationControllerBase<AnimationType, ThisType> extends Animation<AnimationType>
    with
        AnimationEagerListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin {
  _AnimationControllerBase({
    required TickerProvider vsync,
    this.animationBehavior = AnimationBehavior.normal,
  }) {
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectCreated(
        library: 'package:flutter/animation.dart',
        className: '$ThisType',
        object: this,
      );
    }
    _ticker = vsync.createTicker(_tick);
  }

  /// The behavior of the controller when [AccessibilityFeatures.disableAnimations]
  /// is true.
  ///
  /// Defaults to [AnimationBehavior.normal] for the [AnimationController.new]
  /// constructor, and [AnimationBehavior.preserve] for the
  /// [AnimationController.unbounded] constructor.
  final AnimationBehavior animationBehavior;

  Ticker? _ticker;

  void _tick(Duration elapsed);

  // A method that all 3 controllers have in common.
  TickerFuture animateTo(AnimationType target);

  void resync(TickerProvider vsync) {
    final Ticker oldTicker = _ticker!;
    _ticker = vsync.createTicker(_tick);
    _ticker!.absorbTicker(oldTicker);
  }

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  @override
  void dispose() {
    assert(() {
      if (_ticker == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$ThisType.dispose() called more than once.'),
          ErrorDescription('A given $runtimeType cannot be disposed more than once.\n'),
          DiagnosticsProperty<ThisType>(
            'The following $runtimeType object was disposed multiple times',
            this as ThisType,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
        ]);
      }
      return true;
    }());
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectDisposed(object: this);
    }
    _ticker!.dispose();
    _ticker = null;
    clearStatusListeners();
    clearListeners();
    super.dispose();
  }
}

/// Function signature for linear interpolation.
///
/// {@template flutter.animation.LerpCallback}
/// For example, [Color.lerp] qualifies as a `LerpCallback<Color>`.
///
/// The callback should have the return type [T]; the return type
/// is nullable for compatibility with existing "lerp" methods.
/// {@endtemplate}
typedef LerpCallback<T> = T? Function(T a, T b, double t);

/// A [ValueListenable] whose [value] updates each frame
/// over the specified [duration] to create a continuous visual transition.
///
// /// This class is similar to `AnimatedValue`: [AnimatedValue] is a [StatefulWidget]
// /// whereas [ValueAnimation] is an [Animation].
///
/// A `ValueAnimation`
/// can animate to and from `null`, if [T] is configured as nullable and
/// the appropriate [lerp] callback is provided.
/// Otherwise, the appropriate transition is configured automatically
/// via [ValueAnimation.lerpCallbackOfExactType].
class ValueAnimation<T> extends _AnimationControllerBase<T, ValueAnimation<T>> {
  /// Creates a [ValueListenable] that smoothly animates between values.
  ///
  /// {@macro flutter.animation.ValueAnimation.value_setter}
  ValueAnimation({
    required super.vsync,
    required T initialValue,
    required this.duration,
    this.curve = Curves.linear,
    LerpCallback<T>? lerp,
    super.animationBehavior,
  }) : _from = initialValue,
       _target = initialValue,
       _value = initialValue,
       lerp = lerp ?? lerpCallbackOfExactType<T>();

  /// The length of time this animation should last.
  ///
  /// The duration can be adjusted at any time, but modifying it
  /// while an animation is active could result in sudden visual changes.
  Duration duration;

  /// Determines how quickly the animation speeds up and slows down.
  ///
  /// For instance, if this is set to [Curves.easeOutExpo], the majority of
  /// the change to the [value] happens right away, whereas [Curves.easeIn]
  /// would start slowly and then pick up speed toward the end.
  Curve curve;

  /// A function to use for linear interpolation between [value]s.
  ///
  /// {@tool snippet}
  /// Rather than creating a [LerpCallback] for the animation, consider
  /// using the predefined function for that type. For example, [Color.lerp]
  /// can be used for a `ValueAnimation<Color>`.
  ///
  /// ```dart
  /// class _MyState extends State<StatefulWidget> with SingleTickerProviderMixin {
  ///   late final ValueAnimation<Color> colorAnimation = ValueAnimation<Color>(
  ///     tickerProvider: this,
  ///     initialValue: Colors.black,
  ///     duration: Durations.medium1,
  ///     lerp: Color.lerp,
  ///   );
  ///
  ///   // ...
  /// }
  /// ```
  /// {@end-tool}
  final LerpCallback<T> lerp;

  // dart format off

  /// Determines the appropriate [LerpCallback] based on the type argument.
  static LerpCallback<T> lerpCallbackOfExactType<T>() => switch (T) {
    const (double) => ui.lerpDouble,
    const (Offset) => Offset.lerp,
    const (Size) => Size.lerp,
    const (Rect) => Rect.lerp,
    const (Radius) => Radius.lerp,
    const (RRect) => RRect.lerp,
    const (Color) => Color.lerp,
    const (Shadow) => Shadow.lerp,
    const (List<Shadow>) => Shadow.lerpList,
    const (FontWeight) => FontWeight.lerp,
    const (FontVariation) => FontVariation.lerp,
    const (AlignmentGeometry) => AlignmentGeometry.lerp,
    const (Alignment) => Alignment.lerp,
    const (AlignmentDirectional) => AlignmentDirectional.lerp,
    const (BorderRadiusGeometry) => BorderRadiusGeometry.lerp,
    const (BorderRadius) => BorderRadius.lerp,
    const (BorderRadiusDirectional) => BorderRadiusDirectional.lerp,
    const (BorderSide) => BorderSide.lerp,
    const (ShapeBorder) => ShapeBorder.lerp,
    const (OutlinedBorder) => OutlinedBorder.lerp,
    const (BoxBorder) => BoxBorder.lerp,
    const (Border) => Border.lerp,
    const (BorderDirectional) => BorderDirectional.lerp,
    const (BoxDecoration) => BoxDecoration.lerp,
    const (BoxShadow) => BoxShadow.lerp,
    const (List<BoxShadow>) => BoxShadow.lerpList,
    const (HSVColor) => HSVColor.lerp,
    const (HSLColor) => HSLColor.lerp,
    const (ColorSwatch) => ColorSwatch.lerp,
    const (DecorationImage) => DecorationImage.lerp,
    const (Decoration) => Decoration.lerp,
    const (EdgeInsetsGeometry) => EdgeInsetsGeometry.lerp,
    const (EdgeInsets) => EdgeInsets.lerp,
    const (EdgeInsetsDirectional) => EdgeInsetsDirectional.lerp,
    const (FractionalOffset) => FractionalOffset.lerp,
    const (Gradient) => Gradient.lerp,
    const (LinearGradient) => LinearGradient.lerp,
    const (RadialGradient) => RadialGradient.lerp,
    const (SweepGradient) => SweepGradient.lerp,
    const (LinearBorderEdge) => LinearBorderEdge.lerp,
    const (ShapeDecoration) => ShapeDecoration.lerp,
    const (TextStyle) => TextStyle.lerp,
    const (BoxConstraints) => BoxConstraints.lerp,
    const (RelativeRect) => RelativeRect.lerp,
    const (TableBorder) => TableBorder.lerp,
    _ => throw Error(),
  } as LerpCallback<T>;

  // dart format on

  T _from;
  T _target;
  T _value;

  @override
  T get value => _value;

  /// {@template flutter.animation.ValueAnimation.value_setter}
  /// Rather than updating immediately, changes to the [value] will *animate*
  /// each time a new target is set, using the provided [duration], [curve],
  /// and [lerp] callback.
  /// {@endtemplate}
  ///
  /// To create an immediate change to the value, consider calling [animateTo]
  /// with a non-null `from` parameter, or calling [jumpTo].
  set value(T newTarget) {
    animateTo(newTarget);
  }

  late final _debugLerpError = FlutterError.fromParts([
    ErrorSummary('The "lerp" callback of a ValueAnimation<$T>() returned `null`.'),
    ErrorDescription('$this'),
    ErrorDescription(
      'A "lerp" callback should always return a non-null value when given 2 non-null inputs.',
    ),
    ErrorHint('Consider double-checking the linear interpolation logic.'),
  ]);

  /// Triggers an animation, and returns a [TickerFuture] that completes
  /// when it finishes.
  ///
  /// ```dart
  /// // using the .animateTo() method
  /// _animation.animateTo(
  ///   target: newValue,
  ///   duration: Durations.medium1,
  ///   curve: Curves.ease,
  /// );
  ///
  /// // equivalent to:
  /// _animation
  ///   ..duration = Durations.medium1
  ///   ..curve = Curves.ease
  ///   ..value = newValue;
  /// ```
  @override
  TickerFuture animateTo(T target, {T? from, Duration? duration, Curve? curve}) {
    assert(_ticker != null, 'Cannot animate after the ValueAnimation was disposed of.');
    _ticker!.stop(canceled: true);

    if (duration != null) {
      this.duration = duration;
    }
    if (curve != null) {
      this.curve = curve;
    }
    if (from == null && value == target) {
      return TickerFuture.complete();
    }
    if (this.duration == Duration.zero || !animationBehavior.enableAnimations) {
      value = target;
      _statusUpdate(AnimationStatus.completed);
      return TickerFuture.complete();
    }

    _from = from ?? value;
    _target = target;
    final T? newValue = lerp(_from, _target, 0);
    if (newValue is! T) {
      assert(throw _debugLerpError);
      return TickerFuture.complete();
    }
    _value = newValue;
    _statusUpdate(AnimationStatus.forward);
    return _ticker!.start();
  }

  /// Immediately set a new value.
  void jumpTo(T target) {
    _ticker!.stop(canceled: true);
    _from = _value = _target = target;
    notifyListeners();
  }

  @override
  void _tick(Duration elapsed) {
    late final double progress = elapsed.inMicroseconds / duration.inMicroseconds;

    if (_value == _target || progress >= 1.0) {
      _value = _target;
      _statusUpdate(AnimationStatus.completed);
      _ticker!.stop();
    } else {
      final double t = curve.transform(math.max(progress, 0.0));
      final T? newValue = lerp(_from, _target, t);
      if (newValue is! T) {
        assert(throw _debugLerpError);
        return;
      }
      _value = newValue;
    }
    notifyListeners();
  }

  /// The current status of the value's animation.
  ///
  /// Possible status values:
  ///
  ///  * [AnimationStatus.dismissed] when the [ValueAnimation] is created,
  ///    before its first animation starts.
  ///  * [AnimationStatus.forward] when an animation is in progress.
  ///  * [AnimationStatus.completed] once an animation completes.
  ///
  /// [AnimationStatus.reverse] is used in [AnimationController] and
  /// [ToggleAnimation], but it does not apply to a [ValueAnimation].
  @override
  AnimationStatus get status => _lastReportedStatus;
  AnimationStatus _lastReportedStatus = AnimationStatus.dismissed;
  void _statusUpdate(AnimationStatus newStatus) {
    if (newStatus == _lastReportedStatus) {
      return;
    }
    _lastReportedStatus = newStatus;
    notifyStatusListeners(newStatus);
  }

  /// Stops the animation.
  void stop({bool canceled = true}) => _ticker!.stop(canceled: canceled);
}

/// An animation controller that toggles between two states.
///
/// Rather than a [bool], the [value] is a [double] ranging from `0.0` to `1.0`.
/// This value is updated each frame throughout the [duration], creating a
/// smooth transition between the "on" and "off" states.
///
/// See also:
///
/// * [AnimationController], a multi-purpose controller that can `toggle`,
///   `fling`, or follow a [Simulation].
/// * [CurvedAnimation], which can take a [ToggleAnimation] as its `parent`
///   and apply a [Curve].
/// * [ValueAnimation], for controlling a curved animation of any type.
class ToggleAnimation extends _AnimationControllerBase<double, ToggleAnimation> {
  /// Creates a ToggleAnimation.
  ///
  /// Example:
  ///
  /// ```dart
  /// class MyState extends State<StatefulWidget> with SingleTickerProviderMixin {
  ///   late final ToggleAnimation toggleAnimation = ToggleAnimation(
  ///     vsync: this,
  ///     duration: Durations.medium1,
  ///   );
  /// }
  /// ```
  ToggleAnimation({
    required super.vsync,
    required this.duration,
    this.reverseDuration,
    this.maintainSpeed = true,
    super.animationBehavior,
  });

  /// The amount of time the animation should last.
  ///
  /// See [reverseDuration] and [maintainSpeed] for other ways to affect
  /// the animation's duration.
  Duration duration;

  /// The amount of time the animation should last if the [value] is decreasing.
  ///
  /// If this is `null` (the default), the [duration] is used in its place.
  Duration? reverseDuration;

  /// If set to true, an animation that covers half the distance
  /// (e.g. `animateTo(1.0, from: 0.5)`) will finish in half the time.
  ///
  /// If false, the specified [duration] will always apply, so a transition
  /// from `0.5` to `1.0` will appear "slower" than from `0.0` to `1.0`.
  final bool maintainSpeed;

  @override
  bool get isForwardOrCompleted => _target > 0 && _target >= _from;

  @override
  double get value => _value;
  set value(double newValue) {
    _ticker!.stop(canceled: true);
    final bool wasChanged = _value != newValue;
    _value = _from = _target = newValue;
    if (wasChanged) {
      notifyListeners();
      _statusUpdate();
    }
  }

  double _value = 0.0;
  double _from = 0.0;
  double _target = 0.0;
  double _targetProgress = 1.0;
  TickerFuture _currentAnimation = TickerFuture.complete();

  /// Runs an animation in which the [value] transitions to match the [target].
  ///
  /// If [from] is non-null, it will be set as the value before
  /// the animation starts.
  ///
  /// If the target is greater than the current value, the [status] will show as
  /// [AnimationStatus.forward] while the animation is running and
  /// [AnimationStatus.completed] when it ends; likewise, if the target is less
  /// than the current value, the status is reported as [AnimationStatus.reverse]
  /// while the animation runs and [AnimationStatus.dismissed] when it's over.
  ///
  /// If [maintainSpeed] is false, the animation runs for the full [duration]
  /// (or [reverseDuration], if applicable). Otherwise, the animation lasts for
  /// a fraction of the specified duration, based on the difference between the
  /// [target] and the current [value].
  @override
  TickerFuture animateTo(double target, {double? from}) {
    assert(_ticker != null, 'Cannot animate after the ToggleAnimation is disposed of.');
    assert(
      0.0 <= target && target <= 1.0,
      'The target value (${target.toStringAsFixed(2)}) must be in the range [0.0, 1.0].',
    );
    assert(
      from == null || 0.0 <= from && from <= 1.0,
      'The "from" value (${from.toStringAsFixed(2)}) must be in the range [0.0, 1.0].',
    );

    _ticker!.stop(canceled: true);
    _target = target;
    if (from != null) {
      _value = _from = from;
    } else {
      _from = _value;
    }
    if (maintainSpeed) {
      _targetProgress = (_target - _from).abs();
    }

    if (target == _value) {
      return TickerFuture.complete();
    }
    if (duration == Duration.zero) {
      _value = target;
      notifyListeners();
      _statusUpdate();
      return TickerFuture.complete();
    }
    final TickerFuture tickerFuture = _ticker!.start();
    _statusUpdate();
    return _currentAnimation = tickerFuture;
  }

  /// Toggles the animation back and forth.
  ///
  /// If a `forward` value is passed, it determines the animation's direction.
  ///
  /// If the value of `forward` matches [isForwardOrCompleted], this method
  /// returns the existing [TickerFuture] instead of cancelling it.
  /// This also means that the animation's speed will remain unchanged,
  /// even if [maintainSpeed] is false.
  ///
  /// If `forward` is null, then `toggle()` will switch directions
  /// each time it's called.
  TickerFuture toggle({bool? forward}) {
    if (forward == isForwardOrCompleted && _ticker!.isActive) {
      return _currentAnimation;
    }

    forward ??= !isForwardOrCompleted;
    return animateTo(forward ? 1.0 : 0.0);
  }

  /// Toggles this animation toward the "on" state, i.e. a value of `1.0`.
  TickerFuture forward({double? from}) => animateTo(1.0, from: from);

  /// Toggles this animation toward the "off" state, i.e. a value of `0.0`.
  TickerFuture reverse({double? from}) => animateTo(0.0, from: from);

  @override
  void _tick(Duration elapsed) {
    final Duration duration =
        isForwardOrCompleted ? this.duration : reverseDuration ?? this.duration;
    final double progress = elapsed.inMicroseconds / duration.inMicroseconds;

    if (progress >= _targetProgress) {
      _value = _target;
      _ticker!.stop();
      _statusUpdate();
    } else {
      _value = ui.lerpDouble(_from, _target, progress)!;
    }

    notifyListeners();
  }

  @override
  AnimationStatus get status => _lastReportedStatus;
  AnimationStatus _lastReportedStatus = AnimationStatus.dismissed;

  void _statusUpdate() {
    assert(_ticker != null);

    final AnimationStatus currentStatus = switch ((_value, _ticker!.isActive)) {
      (0.0, false) => AnimationStatus.dismissed,
      (1.0, false) => AnimationStatus.completed,
      _ => isForwardOrCompleted ? AnimationStatus.forward : AnimationStatus.reverse,
    };

    if (currentStatus != _lastReportedStatus) {
      _lastReportedStatus = currentStatus;
      notifyStatusListeners(currentStatus);
    }
  }
}
