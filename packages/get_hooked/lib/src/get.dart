part of '../get_hooked.dart';

typedef VsyncBuilder<T> = T Function(TickerProvider vsync);

abstract final class Get {
  ValueListenable get get;

  void update(covariant Function setter);

  Subscription listen(ValueChanged<Object?> listener);

  static GetValue<T> value<T>(T initialValue) => GetValue._(initialValue);

  static GetVsync<T, V> vsync<T, V extends ValueListenable<T>>(VsyncBuilder<V> create) {
    return GetVsync._(create);
  }

  static GetVsync<double, AnimationController> vsyncController({
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

  static GetGroup<Collection> collection<Collection extends Object>(Collection initialData) {
    return switch (initialData) {
      Set() => GetSet._(initialData),
      Iterable() => GetList._(initialData),
      Map() => GetMap._(initialData),
      _ => throw Exception(
          'GetIt.collection() expected a List, Set, or Map; got $initialData',
        ),
    } as GetGroup<Collection>;
  }
}

extension type Subscription._(VoidCallback _dispose) {
  factory Subscription(Listenable listenable, VoidCallback listener) {
    listenable.addListener(listener);
    return Subscription._(() => listenable.removeListener(listener));
  }

  void close() => _dispose();
}

base mixin _Update<T, V extends ValueListenable<T>> on Get implements Use<T, V> {
  @override
  V get get;

  @override
  V get _get => get;

  @override
  void update(ValueSetter<V> setter) => setter(get);
}

sealed class GetGroup<Group extends Object> implements Get {}

@visibleForTesting
final class GetList<E> extends GetGroup<List<E>> with _Update<List<E>, ListNotifier<E>> {
  GetList._(Iterable<E> list) : get = ListNotifier(list);

  @override
  final ListNotifier<E> get;

  @override
  Subscription listen(ValueChanged<List<E>> listener) {
    return Subscription(get, () => listener(UnmodifiableListView(get)));
  }
}

@visibleForTesting
final class GetSet<E> extends GetGroup<Set<E>> with _Update<Set<E>, SetNotifier<E>> {
  GetSet._(Iterable<E> set) : get = SetNotifier(set);

  @override
  final SetNotifier<E> get;

  @override
  Subscription listen(ValueChanged<Set<E>> listener) {
    return Subscription(get, () => listener(UnmodifiableSetView(get)));
  }
}

@visibleForTesting
final class GetMap<K, V> extends GetGroup<Map<K, V>> with _Update<Map<K, V>, MapNotifier<K, V>> {
  GetMap._(Map<K, V> map) : get = MapNotifier(map);

  @override
  final MapNotifier<K, V> get;

  @override
  Subscription listen(ValueChanged<Map<K, V>> listener) {
    return Subscription(get, () => listener(UnmodifiableMapView(get)));
  }
}

final class GetValue<T> extends Get implements Use<T, ValueNotifier<T>> {
  GetValue._(T initialValue) : get = ValueNotifier(initialValue);

  @override
  final ValueNotifier<T> get;
  @override
  ValueNotifier<T> get _get => get;

  @override
  void update(T Function(T value) setter) {
    get.value = setter(get.value);
  }

  @override
  Subscription listen(ValueChanged<T> listener) {
    return Subscription(get, () => listener(get.value));
  }
}

final class GetVsync<T, V extends ValueListenable<T>> extends Get with _Update<T, V> {
  GetVsync._(this.create);

  final VsyncBuilder<V> create;

  Vsync? vsync;
  V? _animation;
  @override
  V get get => _animation ??= create(vsync = Vsync());

  bool attach(BuildContext context) {
    if (_animation != null) return false;

    _animation = create(vsync = Vsync(context));
    return true;
  }

  @override
  Subscription listen(ValueChanged<V> listener) {
    final animation = get;
    return Subscription(animation, () => listener(animation));
  }
}

final class GetAsync<T> extends Get implements Use<AsyncSnapshot<T>, AsyncNotifier<T>> {
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
          ? get.value = get.value.inState(ConnectionState.none)
          : get.connectionState = ConnectionState.none;
    }
  }

  void setStream([Stream<T>? stream]) {
    _clear();
    stream ??= streamCallback?.call();
    if (stream == null) return;

    _subscription = stream.listen(
      (T data) => get.value = AsyncSnapshot.withData(ConnectionState.active, data),
      onError: (Object error, StackTrace stackTrace) {
        get.value = AsyncSnapshot.withError(
          cancelOnError ? ConnectionState.done : ConnectionState.active,
          error,
          stackTrace,
        );
      },
      cancelOnError: cancelOnError,
      onDone: () {
        get.value = get.value.inState(ConnectionState.done);
      },
    );
  }

  void setFuture([Future<T>? future]) {
    _clear();
    _future = future ??= futureCallback?.call();
    if (future == null) return;

    future.then<void>((T data) {
      if (_future == future) {
        get.value = AsyncSnapshot<T>.withData(ConnectionState.done, data);
      }
    }, onError: (Object error, StackTrace stackTrace) {
      if (_future == future) {
        get.value = AsyncSnapshot<T>.withError(ConnectionState.done, error, stackTrace);
      }
    });

    // An implementation like `SynchronousFuture` may have already called the
    // .then() closure. Do not overwrite it in that case.
    if (get.connectionState != ConnectionState.done) {
      get.connectionState = ConnectionState.waiting;
    }
  }

  @override
  late final AsyncNotifier<T> get = AsyncNotifier.initialData(initialData, autoDispose: _clear);

  @override
  AsyncNotifier<T> get _get => get;

  AsyncValueGetter<T>? futureCallback;
  StreamCallback<T>? streamCallback;

  T? initialData;

  @override
  void update(AsyncSnapshot<T> Function(AsyncSnapshot<T> snapshot) setter) {
    get.value = setter(get.value);
  }

  @override
  Subscription listen(ValueChanged<AsyncSnapshot<T>> listener) {
    return Subscription(get, () => listener(get.value));
  }
}
