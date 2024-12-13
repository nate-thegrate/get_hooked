// ignore_for_file: use_setters_to_change_properties, avoid_setters_without_getters, intentional design :)
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:collection/collection.dart';
import 'package:collection_notifiers/collection_notifiers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/ref/ref.dart';
import 'package:meta/meta.dart';

part 'src/computed.dart';
part 'src/dispose_guard.dart';
part 'src/scoped_get.dart';

/// Allows the hook functions defined in [Ref] to access
/// a [Get] object's [ValueListenable].
extension GetHooked<V extends ValueRef> on Get<Object?, V> {
  /// Don't get hooked.
  V get hooked => _hooked;
}

/// Encapsulates a [ValueListenable] object with an interface for
/// easy updates and automatic lifecycle management.
extension type Get<T, V extends ValueListenable<T>>.custom(V _hooked)
    implements ValueListenable<T> {
  /// Don't add a listener directly!
  /// {@template get_hooked.dont}
  /// Prefer using [Ref.watch] or something similar.
  ///
  /// …or if you really gotta do it, use the `.hooked` getter.
  /// {@endtemplate}
  @protected
  @redeclare
  void get addListener {}

  /// Don't remove a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  @redeclare
  void get removeListener {}

  /// Encapsulates a [ValueNotifier].
  ///
  /// See also:
  ///
  /// - [Get.vsyncValue], which creates smooth transitions between values,
  ///   by using a [Vsync] to change gradually each animation frame.
  @factory
  static GetValue<T> it<T>(T initialValue) => GetValue._(_ValueNotifier(initialValue));

  /// Encapsulates a [ListNotifier], and can be used as a [List] directly.
  @factory
  static GetList<E> list<E>([Iterable<E> list = const []]) => GetList._(_ListNotifier(list));

  /// Encapsulates a [SetNotifier], and can be used as a [Set] directly.
  @factory
  static GetSet<E> set<E>([Iterable<E> set = const {}]) => GetSet._(_SetNotifier(set));

  /// Encapsulates a [MapNotifier], and can be used as a [Map] directly.
  @factory
  static GetMap<K, V> map<K, V>([Map<K, V> map = const {}]) => GetMap._(_MapNotifier(map));

  /// Encapsulates an [AnimationController].
  @factory
  static GetVsyncDouble vsync({
    double? initialValue,
    Duration? duration,
    Duration? reverseDuration,
    AnimationBehavior? animationBehavior,
    String? debugLabel,
    double? lowerBound,
    double? upperBound,
    bool bounded = true,
  }) {
    return GetVsyncDouble._(
      Vsync.build(
        (vsync) => _AnimationControllerStyled(
          vsync: vsync,
          value: initialValue,
          lowerBound: lowerBound ?? (bounded ? 0.0 : double.negativeInfinity),
          upperBound: upperBound ?? (bounded ? 1.0 : double.infinity),
          duration: duration,
          reverseDuration: reverseDuration,
          animationBehavior:
              animationBehavior ??
              (bounded ? AnimationBehavior.normal : AnimationBehavior.preserve),
          debugLabel: debugLabel,
        ),
      ),
    );
  }

  /// Encapsulates a [ValueAnimation].
  @factory
  static GetVsyncValue<T> vsyncValue<T>(
    T initialValue, {
    Duration? duration,
    Curve? curve,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    LerpCallback<T>? lerp,
  }) {
    return GetVsyncValue._(
      Vsync.build(
        (vsync) => _ValueAnimationStyled(
          vsync: vsync,
          initialValue: initialValue,
          duration: duration,
          curve: curve,
          animationBehavior: animationBehavior,
          lerp: lerp,
        ),
      ),
    );
  }

  /// Encapsulates any [Animation] via the provided [VsyncBuilder].
  @factory
  static GetVsync<T, A> customVsync<T, A extends Animation<T>>(VsyncBuilder<A> builder) {
    return GetVsync._(Vsync.build(builder));
  }

  /// Encapsulates an [AsyncNotifier] with a preconfigured [futureCallback].
  @factory
  static GetAsync<T> async<T>(AsyncValueGetter<T> futureCallback, {T? initialData}) {
    return GetAsync._(_AsyncController(futureCallback: futureCallback, initialData: initialData));
  }

  /// Encapsulates an [AsyncNotifier] with a preconfigured [streamCallback].
  @factory
  static GetAsync<T> stream<T>(
    StreamCallback<T> streamCallback, {
    T? initialData,
    bool cancelOnError = false,
    bool notifyOnCancel = false,
  }) {
    return GetAsync._(
      _AsyncController(
        streamCallback: streamCallback,
        initialData: initialData,
        cancelOnError: cancelOnError,
        notifyOnCancel: notifyOnCancel,
      ),
    );
  }

  /// Encapsulates a [ProxyNotifier], using the provided callback to retrieve a value.
  @factory
  static GetProxy<T, L> proxy<T, L extends Listenable>(L listenable, T Function(L) getValue) {
    return GetProxy._(_ProxyNotifier(listenable, getValue));
  }

  /// Encapsulates a [Listenable] which notifies based on a [RefComputer] callback.
  @factory
  static GetComputed<Result> compute<Result>(RefComputer<Result> callback) {
    return GetComputed._(ComputedNoScope(callback));
  }
}

/// A generic type implemented by all [Get] objects.
typedef GetAny = Get<Object?, ValueRef>;

/// Shorthand for specifying a [Get] object's first type argument.
typedef GetT<T> = Get<T, ValueListenable<T>>;

/// Shorthand for specifying a [Get] object's second type argument.
typedef GetV<V extends ValueRef> = Get<Object?, V>;

/// A generic type implemented by all [GetVsync] objects.
typedef GetVsyncAny = GetVsync<Object?, Animation<Object?>>;

/// Encapsulates a [ValueNotifier].
extension type GetValue<T>._(ValueNotifier<T> _hooked) implements Get<T, ValueNotifier<T>> {
  // ignore: annotate_redeclares, false positive
  set value(T newValue) {
    _hooked.value = newValue;
  }

  /// Sets a new value and emits a notification.
  void emit(T? newValue) {
    if (newValue is T) _hooked.value = newValue;
  }
}

/// Toggles a boolean [GetValue].
extension ToggleValue on GetValue<bool> {
  /// Convenience method for toggling a [bool] value back and forth.
  ///
  /// The optional positional parameter allows it to be used in e.g. [Switch.onChanged].
  void toggle([_]) => emit(!value);
}

/// Encapsulates a [ListNotifier] and can be used as a [List] directly.
extension type GetList<E>._(ListNotifier<E> _hooked)
    implements List<E>, Get<List<E>, ListNotifier<E>> {
  /// Returns an [UnmodifiableListView] of this object.
  @redeclare
  @redeclare
  List<E> get value => UnmodifiableListView(this);
}

/// Encapsulates a [SetNotifier] and can be used as a [Set] directly.
extension type GetSet<E>._(SetNotifier<E> _hooked)
    implements Set<E>, Get<Set<E>, SetNotifier<E>> {
  /// Returns an [UnmodifiableSetView] of this object.
  @redeclare
  @redeclare
  Set<E> get value => UnmodifiableSetView(this);
}

/// Encapsulates a [MapNotifier] and can be used as a [Map] directly.
extension type GetMap<K, V>._(MapNotifier<K, V> _hooked)
    implements Map<K, V>, Get<Map<K, V>, MapNotifier<K, V>> {
  /// Returns an [UnmodifiableMapView] of this object.
  @redeclare
  @redeclare
  Map<K, V> get value => UnmodifiableMapView(this);
}

/// Encapsulates an [Animation].
extension type GetVsync<T, A extends Animation<T>>._(A _hooked)
    implements Get<T, A>, Animation<T> {
  /// The [Vsync] associated with this animation.
  Vsync? get maybeVsync => Vsync.cache[this];

  /// The [Vsync] associated with this animation.
  Vsync get vsync {
    assert(() {
      if (maybeVsync == null) {
        throw FlutterError.fromParts([
          ErrorSummary('Vsync not found: $this'),
          ErrorDescription(
            'This is most likely caused by creating an animation without calling Vsync.build.',
          ),
          ErrorHint('Consider initializing the animation via Get.vsync().'),
        ]);
      }
      return true;
    }());
    return maybeVsync!;
  }

  /// Don't add a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  @redeclare
  void get addListener {}

  /// Don't remove a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  @redeclare
  void get removeListener {}

  /// Don't add a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  @redeclare
  void get addStatusListener {}

  /// Don't remove a listener directly!
  /// {@macro get_hooked.dont}
  @protected
  @redeclare
  void get removeStatusListener {}
}

/// Encapsulates an [AnimationController].
extension type GetVsyncDouble._(AnimationController _hooked)
    implements GetVsync<double, AnimationController> {
  // ignore: annotate_redeclares, false positive
  set value(double newValue) {
    _hooked.value = newValue;
  }

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
  TickerFuture animateTo(double target, {Duration? duration, Curve curve = Curves.linear}) {
    return _hooked.animateTo(target, duration: duration, curve: curve);
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
  TickerFuture animateBack(double target, {Duration? duration, Curve curve = Curves.linear}) {
    return _hooked.animateBack(target, duration: duration, curve: curve);
  }

  /// Drives the animation according to the given simulation.
  ///
  /// The values from the simulation are clamped to the [lowerBound] and
  /// [upperBound]. To avoid this, consider creating the [AnimationController]
  /// using the [AnimationController.unbounded] constructor.
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  ///
  /// The [status] is always [AnimationStatus.forward] for the entire duration
  /// of the simulation.
  TickerFuture animateWith(Simulation simulation) {
    return _hooked.animateWith(simulation);
  }

  /// The behavior of the controller when [AccessibilityFeatures.disableAnimations]
  /// is true.
  ///
  /// Defaults to [AnimationBehavior.normal] for the [AnimationController.new]
  /// constructor, and [AnimationBehavior.preserve] for the
  /// [AnimationController.unbounded] constructor.
  AnimationBehavior get animationBehavior => _hooked.animationBehavior;

  /// Stops running this animation.
  ///
  /// This does not trigger any notifications. The animation stops in its
  /// current state.
  ///
  /// By default, the most recently returned [TickerFuture] is marked as having
  /// been canceled, meaning the future never completes and its
  /// [TickerFuture.orCancel] derivative future completes with a [TickerCanceled]
  /// error. By passing the `canceled` argument with the value false, this is
  /// reversed, and the futures complete successfully.
  ///
  /// See also:
  ///
  ///  * [reset], which stops the animation and resets it to the [lowerBound],
  ///    and which does send notifications.
  ///  * [forward], [reverse], [animateTo], [animateWith], [fling], and [repeat],
  ///    which restart the animation controller.
  void stop({bool canceled = true}) => _hooked.stop(canceled: canceled);

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
  void reset() => _hooked.reset();

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
  TickerFuture forward({double? from}) => _hooked.forward(from: from);

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
  TickerFuture reverse({double? from}) => _hooked.reverse(from: from);

  /// Toggles the direction of this animation, based on whether it [isForwardOrCompleted].
  ///
  /// Specifically, this function acts the same way as [reverse] if the [status] is
  /// either [AnimationStatus.forward] or [AnimationStatus.completed], and acts as
  /// [forward] for [AnimationStatus.reverse] or [AnimationStatus.dismissed].
  ///
  /// If [from] is non-null, it will be set as the current [value] before running
  /// the animation.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  TickerFuture toggle({double? from}) => _hooked.toggle(from: from);

  /// See [AnimationController.repeat].
  TickerFuture repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
    int? count,
  }) {
    return _hooked.repeat(
      min: min,
      max: max,
      reverse: reverse,
      period: period,
      count: count, //
    );
  }

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
    return _hooked.fling(
      velocity: velocity,
      springDescription: springDescription,
      animationBehavior: animationBehavior,
    );
  }

  /// The amount of time that has passed between the time the animation started
  /// and the most recent tick of the animation.
  ///
  /// If the controller is not animating, the last elapsed duration is null.
  Duration? get lastElapsedDuration => _hooked.lastElapsedDuration;

  /// The value at which this animation is deemed to be dismissed.
  double get lowerBound => _hooked.lowerBound;

  /// The value at which this animation is deemed to be completed.
  double get upperBound => _hooked.upperBound;

  /// The rate of change of [value] per second.
  ///
  /// If [isAnimating] is false, then [value] is not changing and the rate of
  /// change is zero.
  double get velocity => _hooked.velocity;
}

/// Encapsulates a [ValueAnimation].
extension type GetVsyncValue<T>._(ValueAnimation<T> _hooked)
    implements GetVsync<T, ValueAnimation<T>> {
  // ignore: annotate_redeclares, false positive
  set value(T newValue) {
    _hooked.value = newValue;
  }

  /// The length of time this animation should last.
  ///
  /// The duration can be adjusted at any time, but modifying it
  /// while an animation is active could result in sudden visual changes.
  Duration get duration => _hooked.duration;
  set duration(Duration newValue) {
    _hooked.duration = newValue;
  }

  /// Determines how quickly the animation speeds up and slows down.
  ///
  /// For instance, if this is set to [Curves.easeOutExpo], the majority of
  /// the change to the [value] happens right away, whereas [Curves.easeIn]
  /// would start slowly and then pick up speed toward the end.
  Curve get curve => _hooked.curve;
  set curve(Curve newValue) {
    _hooked.curve = curve;
  }

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
  TickerFuture animateTo(T target, {T? from, Duration? duration, Curve? curve}) {
    return _hooked.animateTo(target, from: from, duration: duration, curve: curve);
  }

  /// Immediately set a new value.
  void jumpTo(T target) => _hooked.jumpTo(target);

  /// Stops the animation.
  void stop({bool canceled = true}) => _hooked.stop(canceled: canceled);

  /// The behavior of the controller when [AccessibilityFeatures.disableAnimations]
  /// is true.
  ///
  /// Defaults to [AnimationBehavior.normal] for the [AnimationController.new]
  /// constructor, and [AnimationBehavior.preserve] for the
  /// [AnimationController.unbounded] constructor.
  AnimationBehavior get animationBehavior => _hooked.animationBehavior;
}

/// Encapsulates an [AsyncNotifier].
extension type GetAsync<T>._(AsyncNotifier<T> _hooked) implements Get<T?, AsyncNotifier<T>> {}

/// Encapsulates any [Listenable], using the provided callback to retrieve a value.
extension type GetProxy<T, L extends Listenable>._(ProxyNotifier<T, L> _hooked)
    implements Get<T, ProxyNotifier<T, L>> {}

/// Encapsulates a [Listenable] which notifies based on a [RefComputer] callback.
extension type GetComputed<Result>._(ComputedNoScope<Result> _hooked)
    implements Get<Result, ComputedNoScope<Result>> {}
