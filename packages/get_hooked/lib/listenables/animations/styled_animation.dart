/// @docImport 'package:flutter/scheduler.dart';
/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'default_animation_style.dart';
import 'value_animation.dart';
import 'vsync.dart';

/// A [ValueListenable] attached to a [TickerProvider].
///
/// Generally this interface is implemented by [Animation] objects,
/// but it can be used in other ways (e.g. a single object that manages multiple animations).
abstract interface class VsyncValue<T> implements ValueListenable<T> {
  /// The listenable's associated [Vsync].
  Vsync get vsync;

  /// Called to update the listenable's associated [Vsync].
  void resync(Vsync vsync);
}

/// A `typedef` that can represent any [VsyncValue] object.
typedef VsyncRef = VsyncValue<Object?>;

/// Interface for an [Animation] that uses a [Vsync] to manage its [Ticker] and [AnimationStyle].
abstract interface class StyledAnimation<T> implements Animation<T>, VsyncValue<T> {
  /// Applies the [newStyle] to the animation.
  void updateStyle(AnimationStyle newStyle);
}

/// An [AnimationController] that implements the [StyledAnimation] interface.
///
/// [Get.vsync] returns an instance of this class.
class AnimationControllerStyled extends AnimationController implements StyledAnimation<double> {
  /// Creates an animation controller.
  ///
  /// * `value` is the initial value of the animation. If defaults to the lower
  ///   bound.
  ///
  /// * [duration] is the length of time this animation should last.
  ///
  /// * [debugLabel] is a string to help identify this animation during
  ///   debugging (used by [toString]).
  ///
  /// * [lowerBound] is the smallest value this animation can obtain and the
  ///   value at which this animation is deemed to be dismissed.
  ///
  /// * [upperBound] is the largest value this animation can obtain and the
  ///   value at which this animation is deemed to be completed.
  ///
  /// * `vsync` is the required [Vsync] for the current context. It can
  ///   be changed by calling [resync].
  AnimationControllerStyled({
    required Vsync vsync,
    super.value,
    super.duration,
    this.curve,
    super.reverseDuration,
    this.reverseCurve,
    super.debugLabel,
    super.lowerBound,
    super.upperBound,
    super.animationBehavior,
  }) : _vsync = vsync,
       _configuredDuration = duration,
       _configuredReverseDuration = reverseDuration,
       super(vsync: vsync) {
    vsync.registerAnimation(this);
  }

  Duration? _configuredDuration;
  @override
  set duration(Duration? value) {
    _configuredDuration = value;
    super.duration = value;
  }

  Duration? _configuredReverseDuration;
  @override
  set reverseDuration(Duration? value) {
    _configuredReverseDuration = value;
    super.reverseDuration = value;
  }

  /// The [Curve] to use by default when calling [animateTo].
  Curve? curve;

  /// The [Curve] to use by default when calling [animateBack].
  Curve? reverseCurve;

  late AnimationStyle _style;

  @override
  void updateStyle(AnimationStyle newStyle) {
    _style = newStyle;
    if (_configuredDuration == null) {
      super.duration = newStyle.duration ?? Durations.medium2;
    }
    if (_configuredReverseDuration == null) {
      super.duration = newStyle.reverseDuration ?? Durations.medium2;
    }
  }

  @override
  Vsync get vsync => _vsync;
  Vsync _vsync;

  @override
  void resync(covariant Vsync vsync) {
    if (vsync == _vsync) return;

    super.resync(vsync);
    _vsync.unregisterAnimation(this);
    _vsync = vsync..registerAnimation(this);
  }

  @override
  TickerFuture animateTo(double target, {Duration? duration, Curve? curve}) {
    return super.animateTo(
      target,
      duration: duration ?? _configuredDuration ?? _style.duration,
      curve: curve ?? this.curve ?? _style.curve ?? DefaultAnimationStyle.fallbackCurve,
    );
  }

  @override
  TickerFuture animateBack(double target, {Duration? duration, Curve? curve}) {
    return super.animateBack(
      target,
      duration: duration ?? _configuredReverseDuration ?? _style.reverseDuration,
      curve: curve ?? reverseCurve ?? _style.reverseCurve ?? DefaultAnimationStyle.fallbackCurve,
    );
  }
}

/// A [ValueAnimation] that inherits fallback values from a [Vsync]'s default [AnimationStyle].
class ValueAnimationStyled<T> extends ValueAnimation<T> implements StyledAnimation<T> {
  /// Creates a new [ValueAnimation] object.
  ValueAnimationStyled({
    required Vsync vsync,
    required super.initialValue,
    Duration? duration,
    Curve? curve,
    super.lerp,
    super.animationBehavior,
  }) : _vsync = vsync,
       _configuredDuration = duration,
       _configuredCurve = curve,
       super(
         vsync: vsync,
         duration: duration ?? DefaultAnimationStyle.fallbackDuration,
         curve: curve ?? DefaultAnimationStyle.fallbackCurve,
       ) {
    vsync.registerAnimation(this);
  }

  Duration? _configuredDuration;
  @override
  set duration(Duration value) {
    _configuredDuration = value;
    super.duration = value;
  }

  Curve? _configuredCurve;
  @override
  set curve(Curve value) {
    _configuredCurve = value;
    super.curve = value;
  }

  @override
  void updateStyle(AnimationStyle newStyle) {
    late final Duration? newDuration = newStyle.duration;
    late final Curve? newCurve = newStyle.curve;
    if (_configuredDuration == null && newDuration != null) {
      super.duration = newDuration;
    }
    if (_configuredCurve == null && newCurve != null) {
      super.curve = newCurve;
    }
  }

  @override
  Vsync get vsync => _vsync;
  Vsync _vsync;

  @override
  void resync(covariant Vsync vsync) {
    super.resync(vsync);

    _vsync.unregisterAnimation(this);
    _vsync = vsync..registerAnimation(this);
  }
}
