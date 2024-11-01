part of '../get_hooked.dart';

typedef VsyncBuilder<T> = T Function(TickerProvider vsync);

abstract interface class Get<T, V extends ValueListenable<T>> {
  /// Don't get it.
  V get it;

  void update(covariant Function setter);

  static GetValue<T> value<T>(T initialValue) => GetValue._(initialValue);

  static GetList<E> list<E>(Iterable<E> list) => GetList._(list);

  static GetSet<E> set<E>(Iterable<E> set) => GetSet._(set);

  static GetMap<K, V> map<K, V>(Map<K, V> map) => GetMap._(map);

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

  static GetVsync<T, V, V> customVsync<T, V extends ValueListenable<T>>(VsyncBuilder<V> create) {
    return GetVsync._(create, _getVsync<V>);
  }

  static GetAsync<T> async<T>(AsyncValueGetter<T> futureCallback, {T? initialData}) {
    return GetAsync._(futureCallback: futureCallback, initialData: initialData);
  }

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

  static GetCustom<T, L> custom<T, L extends Listenable>(L listenable, T Function(L) getValue) {
    return GetCustom._(listenable, getValue);
  }
}

interface class GetValue<T> implements Get<T, ValueNotifier<T>> {
  GetValue._(T initialValue) : it = ValueNotifier(initialValue);

  @override
  final ValueNotifier<T> it;

  @override
  void update(T Function(T value) setter) {
    it.value = setter(it.value);
  }
}

interface class GetList<E> implements Get<List<E>, ListNotifier<E>> {
  GetList._(Iterable<E> list) : it = ListNotifier(list);

  @override
  final ListNotifier<E> it;

  @override
  void update(ValueSetter<List<E>> setter) => setter(it);
}

interface class GetSet<E> implements Get<Set<E>, SetNotifier<E>> {
  GetSet._(Iterable<E> set) : it = SetNotifier(set);

  @override
  final SetNotifier<E> it;

  @override
  void update(ValueSetter<Set<E>> setter) => setter(it);
}

interface class GetMap<K, V> implements Get<Map<K, V>, MapNotifier<K, V>> {
  GetMap._(Map<K, V> map) : it = MapNotifier(map);

  @override
  final MapNotifier<K, V> it;

  @override
  void update(ValueSetter<Map<K, V>> setter) => setter(it);
}

interface class GetVsync<T, V extends ValueListenable<T>, C> implements Get<T, V> {
  GetVsync._(VsyncBuilder<V> create, C Function(V) getControls) {
    controls = getControls(it = create(vsync));
  }

  final vsync = Vsync();

  @override
  late final V it;

  late final C controls;

  V attach(BuildContext context) {
    vsync.context = context;

    return it;
  }

  @override
  void update(ValueSetter<C> setter) => setter(controls);
}

typedef _GetVsyncDouble = GetVsync<double, AnimationController, VsyncControls>;
extension type GetVsyncDouble._(_GetVsyncDouble _get) implements _GetVsyncDouble {}

typedef _GetVsyncValue<T> = GetVsync<T, ValueAnimation<T>, VsyncValueControls<T>>;
extension type GetVsyncValue<T>._(_GetVsyncValue<T> _get) implements _GetVsyncValue<T> {}

V _getVsync<V>(V v) => v;

interface class GetAsync<T> implements Get<AsyncSnapshot<T>, AsyncNotifier<T>> {
  GetAsync._({
    this.futureCallback,
    this.streamCallback,
    this.initialData,
    this.cancelOnError = false,
    this.notifyOnCancel = false,
  });

  AsyncValueGetter<T>? futureCallback;
  StreamCallback<T>? streamCallback;

  T? initialData;

  bool cancelOnError;
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

interface class GetCustom<T, L extends Listenable> implements Get<T, ProxyNotifier<T, L>> {
  GetCustom._(this.listenable, T Function(L) getValue) : it = ProxyNotifier(listenable, getValue);

  final L listenable;

  @override
  late final ProxyNotifier<T, L> it;

  @override
  void update(ValueSetter<L> setter) {
    setter(listenable);
  }
}
