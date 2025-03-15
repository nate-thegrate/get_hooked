/// @docImport 'dart:ui';
///
/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:meta/meta.dart';

import 'default_animation_style.dart';
import 'vsync.dart';

@internal
extension EnableAnimations on AnimationBehavior {
  bool get enableAnimations => switch (this) {
    AnimationBehavior.normal => !SemanticsBinding.instance.disableAnimations,
    AnimationBehavior.preserve => true,
  };
}

/// An object that drives animations.
///
/// A class can extend [Animator] to achieve behavior similar to [AnimationController],
/// but with some tweaks to the API surface.
///
/// This class creates an interface similar to [Animation], but the [status] field
/// is a [ValueListenable] to facilitate use in e.g. [Ref.watch] calls.
abstract class Animator<T> extends ValueNotifier<T> implements StyledAnimation<T> {
  /// Initializes fields for subclasses.
  Animator({
    required T initialValue,
    Vsync vsync = Vsync.fallback,
    AnimationStatus initialStatus = AnimationStatus.dismissed,
    this.behavior = AnimationBehavior.normal,
    Duration? duration,
    Curve? curve,
    Duration? reverseDuration,
    Curve? reverseCurve,
    this.debugLabel,
  }) : _vsync = vsync,
       statusNotifier = ValueNotifier(initialStatus),
       _duration = duration,
       _curve = curve,
       _reverseDuration = reverseDuration,
       _reverseCurve = reverseCurve,
       super(initialValue) {
    _ticker = vsync.createTicker(_tick);
    vsync.registerAnimation(this);
  }

  /// The [Animator]'s current value.
  @override
  T get value => super.value;

  late Ticker _ticker;

  /// Starts the clock for the [Ticker]. If the ticker is not muted, then this
  /// also starts calling the ticker's callback once per animation frame.
  ///
  /// The returned future resolves once the ticker [stop]s ticking.
  ///
  /// This method cannot be called while the ticker is active. To restart the
  /// ticker, first [stop] it.
  ///
  /// By convention, this method is used by the object that receives the ticks
  /// (as opposed to the [TickerProvider] which created the ticker).
  @protected
  TickerFuture start() => _ticker.start();

  /// Stops calling the [Ticker]'s callback.
  ///
  /// If called with the `canceled` argument set to true (the default),
  /// the [TickerFuture] does not resolve, and the future obtained from
  /// [TickerFuture.orCancel], if any, resolves with a [TickerCanceled] error.
  /// Setting the `canceled` argument set to false causes the future returned
  /// by [start] to resolve.
  void stop({bool canceled = true}) {
    _ticker.stop(canceled: canceled);
  }

  /// The amount of time that has passed between the time the animation started
  /// and the most recent tick of the animation.
  ///
  /// If the controller is not animating, the last elapsed duration is null.
  Duration? get lastElapsedDuration => _lastElapsedDuration;
  Duration? _lastElapsedDuration;

  @override
  Vsync get vsync => _vsync;
  Vsync _vsync;

  @mustCallSuper
  @override
  void resync(Vsync vsync) {
    if (vsync == _vsync) return;

    final Ticker oldTicker = _ticker;
    _vsync.unregisterAnimation(this);
    _vsync = vsync..registerAnimation(this);
    _ticker = vsync.createTicker(_tick)..absorbTicker(oldTicker);
  }

  /// The [AnimationStyle] associated with this object.
  ///
  /// The value of this field is managed by the [Vsync].
  @protected
  AnimationStyle get style => _style;
  late AnimationStyle _style;

  @protected
  @mustCallSuper
  @override
  void updateStyle(AnimationStyle newStyle) {
    _style = newStyle;
  }

  /// The length of time the animation should last.
  ///
  /// If [reverseDuration] is specified, then [duration] is only used when going
  /// forward. Otherwise, it specifies the duration going in both directions.
  ///
  /// If no value was set explicitly, this field's value is obtained via the [Vsync]
  /// (typically from an ancestor [DefaultAnimationStyle] widget).
  Duration get duration => _duration ?? style.duration ?? DefaultAnimationStyle.fallbackDuration;
  Duration? _duration;
  set duration(Duration? newValue) {
    _duration = newValue;
  }

  /// The length of time the animation should last in the "reverse" direction, if/when applicable.
  ///
  /// If no value is set, this falls back to the [duration].
  Duration get reverseDuration =>
      _reverseDuration ??
      _duration ??
      style.reverseDuration ??
      _style.duration ??
      DefaultAnimationStyle.fallbackDuration;
  Duration? _reverseDuration;
  set reverseDuration(Duration? newValue) {
    _reverseDuration = newValue;
  }

  /// The [Curve] for this animation to use while interpolating.
  ///
  /// If [reverseCurve] is specified, then [curve] is only used when going
  /// forward. Otherwise, it specifies the curve going in both directions.
  ///
  /// If no value was set explicitly, this field's value is obtained via the [Vsync]
  /// (typically from an ancestor [DefaultAnimationStyle] widget).
  Curve get curve => _curve ?? style.curve ?? DefaultAnimationStyle.fallbackCurve;
  Curve? _curve;
  set curve(Curve? newValue) {
    _curve = newValue;
  }

  /// The [Curve] for this animation to use in the "reverse" direction, if/when applicable.
  ///
  /// If no value is set, the [curve]'s value is used instead
  /// (and if that isn't set, it's pulled from the animation [style]).
  Curve get reverseCurve =>
      _reverseCurve ??
      _curve ??
      style.reverseCurve ??
      style.curve ??
      DefaultAnimationStyle.fallbackCurve;
  Curve? _reverseCurve;
  set reverseCurve(Curve? newValue) {
    _reverseCurve = newValue;
  }

  void _tick(Duration elapsed) {
    _lastElapsedDuration = elapsed;
    tick(elapsed);
  }

  /// Override this method to specify what happens to this animator each frame
  /// the [Ticker] is running.
  ///
  /// This method should call [stop] (with `canceled: false`) when the animation
  /// is complete.
  void tick(Duration elapsed);

  /// Drives an animation to the specified `target`, either from the animator's current [value]
  /// or the provided `from` parameter.
  TickerFuture animateTo(T target, {T? from, Duration? duration, Curve? curve});

  /// A [ValueListenable] object that sends notifications when there's a change
  /// to this animator's [AnimationStatus].
  ValueListenable<AnimationStatus> get status => statusNotifier;

  /// The [ValueNotifier] used to track the animator's status.
  ///
  /// This field allows subclasses to make [status] updates.
  @protected
  final ValueNotifier<AnimationStatus> statusNotifier;

  /// The animator's behavior when [AccessibilityFeatures.disableAnimations]
  /// is true.
  ///
  /// Defaults to [AnimationBehavior.normal] for the [AnimationController.new]
  /// constructor, and [AnimationBehavior.preserve] for the
  /// [AnimationController.unbounded] constructor.
  final AnimationBehavior behavior;

  /// Creates an object that uses this [Animator] to implement the [Animation] interface.
  ProxyAnimator<T> toAnimation() => _proxy ??= ProxyAnimator._(this);
  ProxyAnimator<T>? _proxy;

  /// Whether [dispose] has been called.
  @protected
  @visibleForTesting
  bool get debugDisposed => _debugDisposed;
  bool _debugDisposed = false;

  /// In debug mode, verifies that this object has not yet been disposed of.
  @protected
  bool debugCheckDisposal(String methodName) {
    assert(() {
      if (!_debugDisposed) return true;
      throw FlutterError('$runtimeType.$methodName() called after dispose().');
    }());
    return true;
  }

  @override
  void dispose() {
    assert(() {
      if (!_debugDisposed) return _debugDisposed = true;

      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('Animator.dispose() called more than once.'),
        ErrorDescription('A given $runtimeType cannot be disposed more than once.\n'),
        DiagnosticsProperty<Animator<T>>(
          'The following $runtimeType object was disposed multiple times',
          this,
          style: DiagnosticsTreeStyle.errorProperty,
        ),
      ]);
    }());
    _proxy?._statusListeners.clear();
    statusNotifier.dispose();
    _ticker.dispose();
    super.dispose();
  }

  /// A label that is used in the [toString] output. Intended to aid with
  /// identifying animation controller instances in debug output.
  final String? debugLabel;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer
      ..write(switch (status.value) {
        AnimationStatus.forward => '\u25B6 ', // >
        AnimationStatus.reverse => '\u25C0 ', // <
        AnimationStatus.completed => '\u23ED ', // >>|
        AnimationStatus.dismissed => '\u23EE ', // |<<
      })
      ..write(switch (value) {
        final double number => number.toStringAsFixed(3),
        final T t => t,
      });
    if (!_ticker.isActive) buffer.write('; paused');
    if (_ticker.muted) buffer.write('; silenced');
    if (kDebugMode && debugLabel != null) buffer.write('; for $debugLabel');

    return '${describeIdentity(this)}($buffer)';
  }
}

/// An [Animation] object created from an [Animator].
class ProxyAnimator<T> extends Animation<T> implements StyledAnimation<T> {
  ProxyAnimator._(this._animator);
  final Animator<T> _animator;

  @override
  void addListener(VoidCallback listener) {
    _animator.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _animator.removeListener(listener);
  }

  @override
  AnimationStatus get status => _status.value;
  late final _status = _animator.status;

  final _statusListeners = <AnimationStatusListener, VoidCallback>{};
  @override
  void addStatusListener(AnimationStatusListener listener) {
    _status.addListener(_statusListeners[listener] ??= () => listener(_status.value));
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    if (_statusListeners.remove(listener) case final voidCallback?) {
      _status.removeListener(voidCallback);
    }
  }

  @override
  T get value => _animator.value;
  set value(T newValue) {
    _animator.value = newValue;
  }

  @override
  Vsync get vsync => _animator._vsync;

  @override
  void resync(Vsync vsync) => _animator.resync(vsync);

  @override
  void updateStyle(AnimationStyle newStyle) => _animator.updateStyle(newStyle);

  /// Frees the resources attached to this object.
  ///
  /// Calling `dispose()` on either this object or the original [Animator]
  /// will dispose of both of them.
  @mustCallSuper
  void dispose() => _animator.dispose();

  @override
  String toString() => '${describeIdentity(this)}(animator: $_animator)';
}
