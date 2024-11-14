// ignore_for_file: use_setters_to_change_properties, avoid_setters_without_getters, intentional design :)

part of '../get_hooked.dart';

/// Encapsulates a [ValueListenable] object with an interface for
/// easy updates and automatic lifecycle management.
extension type Get<T, V extends ValueListenable<T>>.custom(V _hooked) implements Object {
  /// Returns the [ValueListenable]'s current value.
  T get value => _hooked.value;

  /// Encapsulates a [ValueNotifier].
  @factory
  static GetValue<T> it<T>(T initialValue) => GetValue._(_ValueNotifier(initialValue));

  /// Encapsulates a [ListNotifier].
  @factory
  static GetList<E> list<E>(Iterable<E> list) => GetList._(_ListNotifier(list));

  /// Encapsulates a [SetNotifier].
  @factory
  static GetSet<E> set<E>(Iterable<E> set) => GetSet._(_SetNotifier(set));

  /// Encapsulates a [MapNotifier].
  @factory
  static GetMap<K, V> map<K, V>(Map<K, V> map) => GetMap._(_MapNotifier(map));

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

  /// Encapsulates any [Listenable], using a [Function] to retrieve a value.
  @factory
  static GetFrom<T, L> from<T, L extends Listenable>(L listenable, T Function(L) getValue) {
    return GetFrom._(_ProxyNotifier(listenable, getValue));
  }
}

/// A generic type implemented by all [Get] objects.
typedef GetAny = Get<Object?, ValueListenable<Object?>>;

/// A generic type implemented by all [GetVsync] objects.
typedef GetVsyncAny = GetVsync<Object?, Animation<Object?>>;

/// Encapsulates a [ValueNotifier].
extension type GetValue<T>._(ValueNotifier<T> _hooked) implements Get<T, ValueNotifier<T>> {
  /// Sets a new value and emits a notification.
  void emit(T newValue) {
    _hooked.value = newValue;
  }

  /// Use the notifier's current value to [emit] a new one.
  void modify(T Function(T) modifier) => emit(modifier(_hooked.value));
}

/// Toggles a boolean [GetValue].
extension ToggleValue on GetValue<bool> {
  /// Convenience method for toggling a [bool] value back and forth.
  void toggle() => emit(!value);
}

/// Encapsulates a [ListNotifier].
extension type GetList<E>._(ListNotifier<E> _hooked)
    implements List<E>, Get<List<E>, ListNotifier<E>> {
  @redeclare
  List<E> get value => UnmodifiableListView(_hooked);
}

/// Encapsulates a [SetNotifier].
extension type GetSet<E>._(SetNotifier<E> _hooked)
    implements Set<E>, Get<Set<E>, SetNotifier<E>> {
  @redeclare
  Set<E> get value => UnmodifiableSetView(_hooked);
}

/// Encapsulates a [MapNotifier].
extension type GetMap<K, V>._(MapNotifier<K, V> _hooked)
    implements Map<K, V>, Get<Map<K, V>, MapNotifier<K, V>> {
  @redeclare
  Map<K, V> get value => UnmodifiableMapView(_hooked);
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

/// Encapsulates any [Listenable], using a [Function] to retrieve a value.
extension type GetFrom<T, L extends Listenable>._(ProxyNotifier<T, L> _hooked)
    implements Get<T, ProxyNotifier<T, L>> {}
