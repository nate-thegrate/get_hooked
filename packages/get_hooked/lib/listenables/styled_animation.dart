// ignore_for_file: public_member_api_docs, pro crastinate!

import 'package:flutter/material.dart';

import 'default_animation_style.dart';
import 'value_animation.dart';

abstract interface class StyledAnimation<T> implements Animation<T> {
  void updateStyle(AnimationStyle newStyle);
}

abstract interface class AnimationStyleProvider implements TickerProvider {
  /// Registers the [StyledAnimation] object with this provider.
  ///
  /// [StyledAnimation.updateStyle] is called immediately, and then called again
  /// each time there's a relevant change.
  void registerAnimation(StyledAnimation<Object?> animation);
}

class AnimationControllerStyled extends AnimationController implements StyledAnimation<double> {
  AnimationControllerStyled({
    required AnimationStyleProvider vsync,
    super.value,
    super.duration,
    this.curve,
    super.reverseDuration,
    this.reverseCurve,
    super.debugLabel,
    super.lowerBound,
    super.upperBound,
    super.animationBehavior,
  }) : _configuredDuration = duration,
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

  Curve? curve;
  Curve? reverseCurve;

  late AnimationStyle _style;

  @override
  void updateStyle(AnimationStyle newStyle) {
    _style = newStyle;
    late final Duration? newDuration = newStyle.duration;
    late final Duration? newReverseDuration = newStyle.reverseDuration;
    if (_configuredDuration == null && newDuration != null) {
      super.duration = newDuration;
    }
    if (_configuredReverseDuration == null && newReverseDuration != null) {
      super.duration = newReverseDuration;
    }
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

class ValueAnimationStyled<T> extends ValueAnimation<T> implements StyledAnimation<T> {
  ValueAnimationStyled({
    required AnimationStyleProvider vsync,
    required super.initialValue,
    Duration? duration,
    Curve? curve,
    super.lerp,
    super.animationBehavior,
  }) : _configuredDuration = duration,
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
}
