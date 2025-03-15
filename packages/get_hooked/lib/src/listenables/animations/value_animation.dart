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

import 'animator.dart';

export 'package:flutter/scheduler.dart' show TickerFuture, TickerProvider;

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
/// A `ValueAnimation`
/// can animate to and from `null`, if [T] is configured as nullable and
/// the appropriate [lerp] callback is provided.
/// Otherwise, the appropriate transition is configured automatically
/// via [ValueAnimation.lerpCallbackOfExactType].
class ValueAnimation<T> extends Animator<T> {
  /// Creates a [ValueListenable] that smoothly animates between values.
  ///
  /// {@macro flutter.animation.ValueAnimation.value_setter}
  ValueAnimation({
    required super.initialValue,
    super.vsync,
    super.duration,
    super.curve,
    LerpCallback<T>? lerp,
    super.behavior,
    super.debugLabel,
  }) : _from = initialValue,
       _target = initialValue,
       lerp = lerp ?? lerpCallbackOfExactType<T>();

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

  /// {@template flutter.animation.ValueAnimation.value_setter}
  /// Rather than updating immediately, changes to the [value] will *animate*
  /// each time a new target is set, using the provided [duration], [curve],
  /// and [lerp] callback.
  /// {@endtemplate}
  ///
  /// To create an immediate change to the value, consider calling [animateTo]
  /// with a non-null `from` parameter, or calling [jumpTo].
  @override
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
    assert(debugCheckDisposal('animateTo'));
    stop();

    if (duration != null) {
      this.duration = duration;
    }
    if (curve != null) {
      this.curve = curve;
    }
    if (from == null && value == target) {
      return TickerFuture.complete();
    }
    if (this.duration == Duration.zero || !behavior.enableAnimations) {
      value = target;
      statusNotifier.value = AnimationStatus.completed;
      return TickerFuture.complete();
    }

    _from = from ?? value;
    _target = target;
    final T? newValue = lerp(_from, _target, 0);
    if (newValue is! T) {
      assert(throw _debugLerpError);
      return TickerFuture.complete();
    }
    super.value = newValue;
    statusNotifier.value = AnimationStatus.forward;
    return start();
  }

  /// Immediately set a new value.
  void jumpTo(T target) {
    stop();
    super.value = _from = _target = target;
    notifyListeners();
  }

  @override
  void tick(Duration elapsed) {
    late final double progress = elapsed.inMicroseconds / duration.inMicroseconds;

    if (value == _target || progress >= 1.0) {
      super.value = _target;
      statusNotifier.value = AnimationStatus.completed;
      stop(canceled: false);
    } else {
      final double t = curve.transform(math.max(progress, 0.0));
      final T? newValue = lerp(_from, _target, t);
      if (newValue is! T) {
        assert(throw _debugLerpError);
        return;
      }
      super.value = newValue;
    }
  }
}
