// ignore_for_file: use_setters_to_change_properties, avoid_setters_without_getters, intentional design :)

part of '../get.dart';

/// Encapsulates a [ValueListenable] object with an interface for
/// easy updates and automatic lifecycle management.
extension type Get<T, V extends ValueListenable<T>>.custom(V _hooked) implements Object {
  /// Returns the [ValueListenable]'s current value.
  T get value => _hooked.value;

  /// Encapsulates a [ValueNotifier].
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
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
  }) {
    return GetVsyncDouble._(
      Vsync.build(
        (vsync) => _AnimationController(
          vsync: vsync,
          duration: duration ?? Vsync.defaultDuration,
          reverseDuration: reverseDuration,
          animationBehavior: animationBehavior,
          debugLabel: debugLabel,
          lowerBound: lowerBound,
          upperBound: upperBound,
          value: initialValue,
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
        (vsync) => _ValueAnimation(
          vsync: vsync,
          initialValue: initialValue,
          duration: duration ?? Vsync.defaultDuration,
          curve: curve ?? Vsync.defaultCurve,
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

  /// Encapsulates an [AsyncController] with a preconfigured [futureCallback].
  @factory
  static GetAsync<T> async<T>(AsyncValueGetter<T> futureCallback, {T? initialData}) {
    return GetAsync._(_AsyncController(futureCallback: futureCallback, initialData: initialData));
  }

  /// Encapsulates an [AsyncController] with a preconfigured [streamCallback].
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

  /// Encapsulates a [ProxyNotifier2], using the provided callback to retrieve a value.
  ///
  /// At least one of these two values should be a [Listenable] or [Get] object,
  /// so that the proxy knows when to send its own notifications.
  @factory
  static GetProxy2<T, L1, L2> proxy2<T, L1, L2>(
    L1 l1,
    L2 l2,
    T Function(L1 l1, L2 l2) getValue, {
    bool concurrent = false,
  }) {
    return GetProxy2._(_ProxyNotifier2(l1, l2, getValue, concurrent: concurrent));
  }

  /// Encapsulates a [ProxyNotifier3], using the provided callback to retrieve a value.
  ///
  /// At least one of these three values should be a [Listenable] or [Get] object,
  /// so that the proxy knows when to send its own notifications.
  @factory
  static GetProxy3<T, L1, L2, L3> proxy3<T, L1, L2, L3>(
    L1 l1,
    L2 l2,
    L3 l3,
    T Function(L1 l1, L2 l2, L3 l3) getValue, {
    bool concurrent = false,
  }) {
    return GetProxy3._(_ProxyNotifier3(l1, l2, l3, getValue, concurrent: concurrent));
  }

  /// Encapsulates a [ProxyNotifier4], using the provided callback to retrieve a value.
  ///
  /// At least one of these four values should be a [Listenable] or [Get] object,
  /// so that the proxy knows when to send its own notifications.
  @factory
  static GetProxy4<T, L1, L2, L3, L4> proxy4<T, L1, L2, L3, L4>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    T Function(L1 l1, L2 l2, L3 l3, L4 l4) getValue, {
    bool concurrent = false,
  }) {
    return GetProxy4._(_ProxyNotifier4(l1, l2, l3, l4, getValue, concurrent: concurrent));
  }

  /// Encapsulates a [ProxyNotifier5], using the provided callback to retrieve a value.
  ///
  /// At least one of these five values should be a [Listenable] or [Get] object,
  /// so that the proxy knows when to send its own notifications.
  @factory
  static GetProxy5<T, L1, L2, L3, L4, L5> proxy5<T, L1, L2, L3, L4, L5>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    T Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5) getValue, {
    bool concurrent = false,
  }) {
    return GetProxy5._(_ProxyNotifier5(l1, l2, l3, l4, l5, getValue, concurrent: concurrent));
  }

  /// Encapsulates a [ProxyNotifier6], using the provided callback to retrieve a value.
  ///
  /// At least one of these six values should be a [Listenable] or [Get] object,
  /// so that the proxy knows when to send its own notifications.
  @factory
  static GetProxy6<T, L1, L2, L3, L4, L5, L6> proxy6<T, L1, L2, L3, L4, L5, L6>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    L6 l6,
    T Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6) getValue, {
    bool concurrent = false,
  }) {
    return GetProxy6._(_ProxyNotifier6(l1, l2, l3, l4, l5, l6, getValue, concurrent: concurrent));
  }

  /// Encapsulates a [ProxyNotifier7], using the provided callback to retrieve a value.
  ///
  /// At least one of these seven values should be a [Listenable] or [Get] object,
  /// so that the proxy knows when to send its own notifications.
  @factory
  static GetProxy7<T, L1, L2, L3, L4, L5, L6, L7> proxy7<T, L1, L2, L3, L4, L5, L6, L7>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    L6 l6,
    L7 l7,
    T Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7) getValue, {
    bool concurrent = false,
  }) {
    return GetProxy7._(
      _ProxyNotifier7(l1, l2, l3, l4, l5, l6, l7, getValue, concurrent: concurrent),
    );
  }

  /// Encapsulates a [ProxyNotifier8], using the provided callback to retrieve a value.
  ///
  /// At least one of these eight values should be a [Listenable] or [Get] object,
  /// so that the proxy knows when to send its own notifications.
  @factory
  static GetProxy8<T, L1, L2, L3, L4, L5, L6, L7, L8> proxy8<T, L1, L2, L3, L4, L5, L6, L7, L8>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    L6 l6,
    L7 l7,
    L8 l8,
    T Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7, L8 l8) getValue, {
    bool concurrent = false,
  }) {
    return GetProxy8._(
      _ProxyNotifier8(l1, l2, l3, l4, l5, l6, l7, l8, getValue, concurrent: concurrent),
    );
  }

  /// Encapsulates a [ProxyNotifier9], using the provided callback to retrieve a value.
  ///
  /// At least one of these nine values should be a [Listenable] or [Get] object,
  /// so that the proxy knows when to send its own notifications.
  @factory
  static GetProxy9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9>
  proxy9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    L6 l6,
    L7 l7,
    L8 l8,
    L9 l9,
    T Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7, L8 l8, L9 l9) getValue, {
    bool concurrent = false,
  }) {
    return GetProxy9._(
      _ProxyNotifier9(l1, l2, l3, l4, l5, l6, l7, l8, l9, getValue, concurrent: concurrent),
    );
  }
}

/// A generic type implemented by all [Get] objects.
typedef GetAny = Get<Object?, ValueRef>;

/// A generic type implemented by all [GetVsync] objects.
typedef GetVsyncAny = GetVsync<Object?, Animation<Object?>>;

/// Encapsulates a [ValueNotifier].
extension type GetValue<T>._(ValueNotifier<T> _hooked) implements Get<T, ValueNotifier<T>> {
  // ignore: annotate_redeclares, false positive
  set value(T newValue) => emit(newValue);

  /// Sets a new value and emits a notification.
  void emit(T newValue) {
    _hooked.value = newValue;
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
  List<E> get value => UnmodifiableListView(this);
}

/// Encapsulates a [SetNotifier] and can be used as a [Set] directly.
extension type GetSet<E>._(SetNotifier<E> _hooked)
    implements Set<E>, Get<Set<E>, SetNotifier<E>> {
  /// Returns an [UnmodifiableSetView] of this object.
  @redeclare
  Set<E> get value => UnmodifiableSetView(this);
}

/// Encapsulates a [MapNotifier] and can be used as a [Map] directly.
extension type GetMap<K, V>._(MapNotifier<K, V> _hooked)
    implements Map<K, V>, Get<Map<K, V>, MapNotifier<K, V>> {
  /// Returns an [UnmodifiableMapView] of this object.
  @redeclare
  Map<K, V> get value => UnmodifiableMapView(this);
}

/// Encapsulates an [Animation].
extension type GetVsync<T, A extends Animation<T>>._(A _hooked)
    implements AnimationView<T>, Get<T, A> {
  /// The [Vsync] associated with this animation.
  Vsync get vsync {
    assert(() {
      if (Vsync.cache[this] == null) {
        throw FlutterError.fromParts([
          ErrorSummary('Vsync not found: $this'),
          ErrorDescription(
            'This is most likely caused by creating an animation without calling GetVsync.build.',
          ),
          ErrorHint('Consider initializing the animation via Get.vsync().'),
        ]);
      }
      return true;
    }());
    return Vsync.cache[this]!;
  }

  @redeclare
  T get value => _hooked.value;
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
    // int? count,
  }) {
    return _hooked.repeat(
      min: min,
      max: max,
      reverse: reverse,
      period: period,
      // count: count,
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
extension type GetAsync<T>._(AsyncController<T> _hooked)
    implements Get<AsyncSnapshot<T>, AsyncController<T>> {}

// dart format off
/// Encapsulates any [Listenable], using the provided callback to retrieve a value.
extension type GetProxy<T, L extends Listenable>._(ProxyNotifier<T, L> _hooked)
implements Get<T, ProxyNotifier<T, L>> {}

/// Encapsulates a [ProxyNotifier2], using the provided callback to retrieve a value.
extension type GetProxy2<T, L1, L2>._(ProxyNotifier2<T, L1, L2> _hooked)
implements Get<T, ProxyNotifier2<T, L1, L2>> {}

/// Encapsulates a [ProxyNotifier3], using the provided callback to retrieve a value.
extension type GetProxy3<T, L1, L2, L3>._(ProxyNotifier3<T, L1, L2, L3> _hooked)
implements Get<T, ProxyNotifier3<T, L1, L2, L3>> {}

/// Encapsulates a [ProxyNotifier4], using the provided callback to retrieve a value.
extension type GetProxy4<T, L1, L2, L3, L4>._(ProxyNotifier4<T, L1, L2, L3, L4> _hooked)
implements Get<T, ProxyNotifier4<T, L1, L2, L3, L4>> {}

/// Encapsulates a [ProxyNotifier5], using the provided callback to retrieve a value.
extension type GetProxy5<T, L1, L2, L3, L4, L5>._(ProxyNotifier5<T, L1, L2, L3, L4, L5> _hooked)
implements Get<T, ProxyNotifier5<T, L1, L2, L3, L4, L5>> {}

/// Encapsulates a [ProxyNotifier6], using the provided callback to retrieve a value.
extension type GetProxy6<T, L1, L2, L3, L4, L5, L6>._(ProxyNotifier6<T, L1, L2, L3, L4, L5, L6> _hooked)
implements Get<T, ProxyNotifier6<T, L1, L2, L3, L4, L5, L6>> {}

/// Encapsulates a [ProxyNotifier7], using the provided callback to retrieve a value.
extension type GetProxy7<T, L1, L2, L3, L4, L5, L6, L7>._(ProxyNotifier7<T, L1, L2, L3, L4, L5, L6, L7> _hooked)
implements Get<T, ProxyNotifier7<T, L1, L2, L3, L4, L5, L6, L7>> {}

/// Encapsulates a [ProxyNotifier8], using the provided callback to retrieve a value.
extension type GetProxy8<T, L1, L2, L3, L4, L5, L6, L7, L8>._(ProxyNotifier8<T, L1, L2, L3, L4, L5, L6, L7, L8> _hooked)
implements Get<T, ProxyNotifier8<T, L1, L2, L3, L4, L5, L6, L7, L8>> {}

/// Encapsulates a [ProxyNotifier9], using the provided callback to retrieve a value.
extension type GetProxy9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9>._(ProxyNotifier9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9> _hooked)
implements Get<T, ProxyNotifier9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9>> {}
// dart format on
