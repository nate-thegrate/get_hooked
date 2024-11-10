part of '../get_hooked.dart';

/// Creates an object (of type `T`) using a [TickerProvider].
typedef VsyncBuilder<T> = T Function(TickerProvider vsync);

/// Encapsulates a listenable object with an interface for
/// easy updates and automatic lifecycle management.
abstract interface class Get<T, V extends ValueListenable<T>> {
  /// Don't get it.
  V get it;

  /// Updates [it]s value.
  void update(covariant Function setter);

  /// Encapsulates a [ValueNotifier].
  @factory
  static GetValue<T> value<T>(T initialValue) => GetValue._(initialValue);

  /// Encapsulates a [ListNotifier].
  @factory
  static GetList<E> list<E>(Iterable<E> list) => GetList._(list);

  /// Encapsulates a [SetNotifier].
  @factory
  static GetSet<E> set<E>(Iterable<E> set) => GetSet._(set);

  /// Encapsulates a [MapNotifier].
  @factory
  static GetMap<K, V> map<K, V>(Map<K, V> map) => GetMap._(map);

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
      GetVsync._(
        (vsync) => AnimationController(
          vsync: vsync,
          duration: duration ?? Vsync.defaultDuration,
          reverseDuration: reverseDuration,
          animationBehavior: animationBehavior,
          debugLabel: debugLabel,
          lowerBound: lowerBound,
          upperBound: upperBound,
          value: initialValue,
        ),
        VsyncControls._,
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
      GetVsync._(
        (vsync) => ValueAnimation(
          vsync: vsync,
          initialValue: initialValue,
          duration: duration ?? Vsync.defaultDuration,
          curve: curve ?? Vsync.defaultCurve,
          animationBehavior: animationBehavior,
          lerp: lerp,
        ),
        VsyncValueControls._,
      ),
    );
  }

  /// Encapsulates any [Animation] via the provided [VsyncBuilder].
  @factory
  static GetVsync<T, V, V> customVsync<T, V extends ValueListenable<T>>(VsyncBuilder<V> create) {
    return GetVsync._(create, _getVsync<V>);
  }

  /// Encapsulates an [AsyncNotifier] with a preconfigured [futureCallback].
  @factory
  static GetAsync<T> async<T>(AsyncValueGetter<T> futureCallback, {T? initialData}) {
    return GetAsync._(futureCallback: futureCallback, initialData: initialData);
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
      streamCallback: streamCallback,
      initialData: initialData,
      cancelOnError: cancelOnError,
      notifyOnCancel: notifyOnCancel,
    );
  }

  /// Encapsulates any [Listenable], using a [Function] to retrieve a value.
  @factory
  static GetCustom<T, L> custom<T, L extends Listenable>(L listenable, T Function(L) getValue) {
    return GetCustom._(listenable, getValue);
  }
}

/// Encapsulates a [ValueNotifier].
interface class GetValue<T> implements Get<T, ValueNotifier<T>> {
  GetValue._(T initialValue) : it = ValueNotifier(initialValue);

  @override
  final ValueNotifier<T> it;

  @override
  void update(T Function(T value) setter) {
    it.value = setter(it.value);
  }
}

/// Encapsulates a [ListNotifier].
interface class GetList<E> implements Get<List<E>, ListNotifier<E>> {
  GetList._(Iterable<E> list) : it = ListNotifier(list);

  @override
  final ListNotifier<E> it;

  @override
  void update(ValueSetter<List<E>> setter) => setter(it);
}

/// Encapsulates a [SetNotifier].
interface class GetSet<E> implements Get<Set<E>, SetNotifier<E>> {
  GetSet._(Iterable<E> set) : it = SetNotifier(set);

  @override
  final SetNotifier<E> it;

  @override
  void update(ValueSetter<Set<E>> setter) => setter(it);
}

/// Encapsulates a [MapNotifier].
interface class GetMap<K, V> implements Get<Map<K, V>, MapNotifier<K, V>> {
  GetMap._(Map<K, V> map) : it = MapNotifier(map);

  @override
  final MapNotifier<K, V> it;

  @override
  void update(ValueSetter<Map<K, V>> setter) => setter(it);
}

/// Encapsulates an [Animation].
interface class GetVsync<T, V extends ValueListenable<T>, C> implements Get<T, V> {
  GetVsync._(VsyncBuilder<V> create, C Function(V) getControls) {
    controls = getControls(it = create(vsync));
  }

  /// A [TickerProvider] that functions based on a reconfigurable [BuildContext].
  final vsync = Vsync();

  @override
  late final V it;

  /// Intended to store an interface for the listenable that blocks access
  /// to methods like [Listenable.addListener] and [ChangeNotifier.dispose].
  late final C controls;

  /// Attaches this object to the provided [context].
  V attach(BuildContext context) {
    vsync.context = context;

    return it;
  }

  @override
  void update(ValueSetter<C> setter) => setter(controls);
}

/// Encapsulates an [AnimationController].
extension type GetVsyncDouble._(_GetVsyncDouble _get) implements _GetVsyncDouble {}
typedef _GetVsyncDouble = GetVsync<double, AnimationController, VsyncControls>;

/// Encapsulates a [ValueAnimation].
extension type GetVsyncValue<T>._(_GetVsyncValue<T> _get) implements _GetVsyncValue<T> {}
typedef _GetVsyncValue<T> = GetVsync<T, ValueAnimation<T>, VsyncValueControls<T>>;

V _getVsync<V>(V v) => v;

/// Encapsulates an [AsyncNotifier].
interface class GetAsync<T> implements Get<AsyncSnapshot<T>, AsyncNotifier<T>> {
  GetAsync._({
    this.futureCallback,
    this.streamCallback,
    this.initialData,
    this.cancelOnError = false,
    this.notifyOnCancel = false,
  });

  /// Can be invoked to update the [AsyncNotifier] based on a [Future].
  AsyncValueGetter<T>? futureCallback;

  /// Can be invoked to update the [AsyncNotifier] based on a [Stream].
  StreamCallback<T>? streamCallback;

  // ignore: public_member_api_docs, good luck lol
  T? initialData;

  /// Whether a [StreamSubscription] should end if it encounters an error.
  bool cancelOnError;

  /// Whether the [AsyncNotifier] should send a notification when
  /// the connection ends.
  bool notifyOnCancel;

  @override
  late final AsyncNotifier<T> it = AsyncNotifier.initialData(initialData, autoDispose: clear);

  @override
  void update(AsyncSnapshot<T> Function(AsyncSnapshot<T> snapshot) setter) {
    it.value = setter(it.value);
  }

  Future<T>? _future;
  // ignore: cancel_subscriptions, canceled in clear()
  StreamSubscription<T>? _subscription;

  /// Cancels the [StreamSubscription] and ignores the [Future] if applicable.
  void clear({bool? notify}) {
    bool canceled = false;
    if (_future case final future?) {
      future.ignore();
      _future = null;
      canceled = true;
    }
    if (_subscription case final subscription?) {
      subscription.cancel();
      _subscription = null;
      canceled = true;
    }
    if (canceled) {
      notify ?? notifyOnCancel
          ? it.value = it.value.inState(ConnectionState.none)
          : it.connectionState = ConnectionState.none;
    }
  }

  /// Invokes the stored [StreamCallback], or alternatively can accept a new
  /// [Stream] object.
  void setStream([Stream<T>? stream]) {
    clear();
    stream ??= streamCallback?.call();
    if (stream == null) return;

    _subscription = stream.listen(
      (T data) => it.value = AsyncSnapshot.withData(ConnectionState.active, data),
      onError: (Object error, StackTrace stackTrace) {
        it.value = AsyncSnapshot.withError(
          cancelOnError ? ConnectionState.done : ConnectionState.active,
          error,
          stackTrace,
        );
      },
      cancelOnError: cancelOnError,
      onDone: () {
        it.value = it.value.inState(ConnectionState.done);
      },
    );
  }

  /// Invokes the stored [futureCallback], or alternatively can accept a new
  /// [Future] object.
  void setFuture([Future<T>? future]) {
    clear();
    _future = future ??= futureCallback?.call();
    if (future == null) return;

    future.then<void>(
      (T data) {
        if (identical(_future, future)) {
          it.value = AsyncSnapshot<T>.withData(ConnectionState.done, data);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_future, future)) {
          it.value = AsyncSnapshot<T>.withError(ConnectionState.done, error, stackTrace);
        }
      },
    );

    // An implementation like `SynchronousFuture` may have already called the
    // .then() closure. Do not overwrite it in that case.
    if (it.connectionState != ConnectionState.done) {
      it.connectionState = ConnectionState.waiting;
    }
  }
}

/// Encapsulates any [Listenable], using a [Function] to retrieve a value.
interface class GetCustom<T, L extends Listenable> implements Get<T, ProxyNotifier<T, L>> {
  GetCustom._(this.listenable, T Function(L) getValue) : it = ProxyNotifier(listenable, getValue);

  /// The input [Listenable] object.
  final L listenable;

  @override
  late final ProxyNotifier<T, L> it;

  @override
  void update(ValueSetter<L> setter) {
    setter(listenable);
  }
}
