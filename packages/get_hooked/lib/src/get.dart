part of '../get_hooked.dart';

typedef VsyncBuilder<T> = T Function(TickerProvider vsync);

sealed class Get<T, V extends ValueListenable<T>> {
  /// Don't get it.
  V get it;

  void update(covariant Function setter);

  Subscription listen(ValueChanged<Object?> listener);

  static GetValue<T> value<T>(T initialValue) => GetValue._(initialValue);

  static GetCustom<T, L> custom<T, L extends Listenable>(
    T Function(L) getValue, {
    required L listenable,
  }) {
    return GetCustom._(getValue, listenable: listenable);
  }

  static GetVsync<double, AnimationController> vsync({
    double? initialValue,
    Duration? duration,
    Duration? reverseDuration,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
  }) {
    return GetVsync._(
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
    );
  }

  static GetVsync<T, ValueAnimation<T>> vsyncValue<T>(
    T initialValue, {
    Duration? duration,
    Curve? curve,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    LerpCallback<T>? lerp,
  }) {
    return GetVsync._(
      (vsync) => ValueAnimation(
        vsync: vsync,
        initialValue: initialValue,
        duration: duration ?? Vsync.defaultDuration,
        curve: curve ?? Vsync.defaultCurve,
        animationBehavior: animationBehavior,
        lerp: lerp,
      ),
    );
  }

  static GetVsync<T, V> customVsync<T, V extends ValueListenable<T>>(VsyncBuilder<V> create) {
    return GetVsync._(create);
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

  static GetList list<T>(Iterable<T> list) => GetList._(list);

  static GetSet set<T>(Iterable<T> set) => GetSet._(set);

  static GetMap map<K, V>(Map<K, V> map) => GetMap._(map);
}

extension type Subscription._(VoidCallback _dispose) {
  factory Subscription(Listenable listenable, VoidCallback listener) {
    listenable.addListener(listener);
    return Subscription._(() => listenable.removeListener(listener));
  }

  void close() => _dispose();
}

mixin _Update<T, V extends ValueListenable<T>> implements Get<T, V> {
  @override
  void update(ValueSetter<V> setter) => setter(it);
}

mixin _Listen<T, V extends ValueListenable<T>> implements Get<T, V> {
  @override
  Subscription listen(ValueChanged<T> listener) {
    return Subscription(it, () => listener(it.value));
  }
}

@visibleForTesting
final class GetList<E> with _Update<List<E>, ListNotifier<E>> {
  GetList._(Iterable<E> list) : it = ListNotifier(list);

  @override
  final ListNotifier<E> it;

  @override
  Subscription listen(ValueChanged<List<E>> listener) {
    return Subscription(it, () => listener(UnmodifiableListView(it)));
  }
}

@visibleForTesting
final class GetSet<E> with _Update<Set<E>, SetNotifier<E>> {
  GetSet._(Iterable<E> set) : it = SetNotifier(set);

  @override
  final SetNotifier<E> it;

  @override
  Subscription listen(ValueChanged<Set<E>> listener) {
    return Subscription(it, () => listener(UnmodifiableSetView(it)));
  }
}

@visibleForTesting
final class GetMap<K, V> with _Update<Map<K, V>, MapNotifier<K, V>> {
  GetMap._(Map<K, V> map) : it = MapNotifier(map);

  @override
  final MapNotifier<K, V> it;

  @override
  Subscription listen(ValueChanged<Map<K, V>> listener) {
    return Subscription(it, () => listener(UnmodifiableMapView(it)));
  }
}

final class GetValue<T> with _Listen<T, ValueNotifier<T>> {
  GetValue._(T initialValue) : it = ValueNotifier(initialValue);

  @override
  final ValueNotifier<T> it;

  @override
  void update(T Function(T value) setter) {
    it.value = setter(it.value);
  }
}

final class GetVsync<T, V extends ValueListenable<T>> with _Update<T, V> {
  GetVsync._(this.create);

  final VsyncBuilder<V> create;

  Vsync? vsync;
  V? _animation;
  @override
  V get it => _animation ??= create(vsync = Vsync());

  V attach(BuildContext context) {
    V? animation = _animation;
    if (animation == null) {
      animation = create(vsync = Vsync(context));
    } else if (vsync case final vsync?) {
      vsync.context = context;
    } else {
      throw StateError('Animation was initialized without a vsync.');
    }
    for (final ticker in tickers) {
      if (ticker.vsync.context == context) {
        ticker.updateNotifier(context);
      }
    }

    return animation;
  }

  @override
  Subscription listen(ValueChanged<V> listener) {
    final animation = it;
    return Subscription(animation, () => listener(animation));
  }
}

final class GetAsync<T> implements Get<AsyncSnapshot<T>, AsyncNotifier<T>> {
  GetAsync._({
    this.futureCallback,
    this.streamCallback,
    this.initialData,
    this.cancelOnError = false,
    this.notifyOnCancel = false,
  });

  bool cancelOnError;
  bool notifyOnCancel;

  Future<T>? _future;
  StreamSubscription<T>? _subscription;

  void _clear() => clear(notify: false);

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
    _clear();
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
    _clear();
    _future = future ??= futureCallback?.call();
    if (future == null) return;

    future.then<void>((T data) {
      if (_future == future) {
        it.value = AsyncSnapshot<T>.withData(ConnectionState.done, data);
      }
    }, onError: (Object error, StackTrace stackTrace) {
      if (_future == future) {
        it.value = AsyncSnapshot<T>.withError(ConnectionState.done, error, stackTrace);
      }
    });

    // An implementation like `SynchronousFuture` may have already called the
    // .then() closure. Do not overwrite it in that case.
    if (it.connectionState != ConnectionState.done) {
      it.connectionState = ConnectionState.waiting;
    }
  }

  @override
  late final AsyncNotifier<T> it = AsyncNotifier.initialData(initialData, autoDispose: _clear);

  AsyncValueGetter<T>? futureCallback;
  StreamCallback<T>? streamCallback;

  T? initialData;

  @override
  void update(AsyncSnapshot<T> Function(AsyncSnapshot<T> snapshot) setter) {
    it.value = setter(it.value);
  }

  @override
  Subscription listen(ValueChanged<AsyncSnapshot<T>> listener, {bool? toStream}) {
    if (toStream ?? streamCallback != null) {
      setStream();
    } else {
      setFuture();
    }
    return Subscription(it, () => listener(it.value));
  }
}

final class GetCustom<T, L extends Listenable> with _Listen<T, ProxyNotifier<T, L>> {
  GetCustom._(T Function(L) getValue, {required this.listenable}) {
    it = ProxyNotifier(getValue, listenable: listenable);
  }

  final L listenable;

  @override
  late final ProxyNotifier<T, L> it;

  @override
  void update(ValueSetter<L> setter) {
    setter(listenable);
  }
}
