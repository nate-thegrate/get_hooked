part of '../get_hooked.dart';

abstract interface class Hooked<T> implements GetIt<T>, Animation<T> {
  abstract final Object key;

  static AnimationController getController({required Object key}) {
    return animationMap.get<_AnimationController>(key: key);
  }

  static void setController({
    required Object key,
    BuildContext? context,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    Duration? duration,
    Duration? reverseDuration,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    double? value,
  }) {
    animationMap.set(
      _AnimationController(
        vsync: Vsync(key, context),
        value: value,
        duration: duration,
        reverseDuration: reverseDuration,
        lowerBound: lowerBound,
        upperBound: upperBound,
        animationBehavior: animationBehavior,
      ),
    );
  }

  static AnimationController useController({
    required Object key,
    double? value,
    Duration? duration,
    Duration? reverseDuration,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    bool listen = true,
    bool autoDispose = true,
  }) {
    return _use<_AnimationController>(
      (context) => _AnimationController(
        vsync: Vsync(key, context),
        value: value,
        duration: duration,
        reverseDuration: reverseDuration,
        lowerBound: lowerBound,
        upperBound: upperBound,
        animationBehavior: animationBehavior,
      ),
      listen,
      autoDispose,
    );
  }

  static ValueAnimation<T> getValue<T>({required Object key}) {
    return animationMap.get<_ValueAnimation<T>>(key: key);
  }

  static void setValue<T>({
    required Object key,
    BuildContext? context,
    required T initialValue,
    required Duration duration,
    Curve curve = Curves.linear,
    LerpCallback<T>? lerp,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    animationMap.set(
      _ValueAnimation<T>(
        vsync: Vsync(key, context),
        initialValue: initialValue,
        duration: duration,
        curve: curve,
        lerp: lerp,
        animationBehavior: animationBehavior,
      ),
    );
  }

  static ValueAnimation<T> useValue<T>({
    required Object key,
    required T initialValue,
    required Duration duration,
    Curve curve = Curves.linear,
    LerpCallback<T>? lerp,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    bool listen = true,
    bool autoDispose = true,
  }) {
    return _use<_ValueAnimation<T>>(
      (context) => _ValueAnimation(
        vsync: Vsync(key, context),
        initialValue: initialValue,
        duration: duration,
        curve: curve,
        lerp: lerp,
        animationBehavior: animationBehavior,
      ),
      listen,
      autoDispose,
    );
  }
}

abstract mixin class HookedKey<T, H extends Hooked<T>> implements Key {
  const factory HookedKey(ValueGetter<H> init) = _HookedKey<T, H>;

  H init();

  H get hooked {
    return animationMap._map.putIfAbsent(this, init) as H;
  }

  T get it => hooked.value;
  set it(T newValue) {
    hooked.value = newValue;
  }

  void dispose() => animationMap.dispose(key: this);

  @override
  String toString() => describeIdentity(this);
}

class _HookedKey<T, H extends Hooked<T>> with HookedKey<T, H> {
  const _HookedKey(this._init);

  final ValueGetter<H> _init;

  @override
  H init() => _init();
}

final _tickers = _Tickers();
extension type _Tickers._(Map<Object, _Ticker> map) implements Map<Object, _Ticker> {
  _Tickers() : map = HashMap<Object, _Ticker>();

  void add(_Ticker ticker) {
    final Object key = ticker.vsync.key;

    assert(() {
      if (map.containsKey(key)) {
        throw FlutterError.fromParts([
          ErrorSummary('Duplicate key found in Vsync: $key'),
          ErrorDescription('message'),
        ]);
      }
      return true;
    }());

    map[key]?.dispose();
    map[key] = ticker;
  }
}

class Vsync implements TickerProvider {
  const Vsync(this.key, [this.context]);

  final Object key;
  final BuildContext? context;

  static bool get muted => _muted;
  static bool _muted = false;
  static set muted(bool newValue) {
    if (newValue != _muted) {
      _muted = newValue;
      for (final Ticker ticker in _tickers.values) {
        ticker.muted = newValue;
      }
    }
  }

  @protected
  @override
  Ticker createTicker(TickerCallback tickerCallback) {
    late final _Ticker ticker;
    void onTick(Duration elapsed) {
      if (context case final context?) {
        if (!context.mounted) {
          return ticker.dispose();
        }
        ticker.updateNotifier();
        if (ticker.muted) return;
      }
      tickerCallback(elapsed);
    }

    return ticker = _Ticker(onTick, this)..start();
  }
}

class _Ticker extends Ticker {
  _Ticker(super.onTick, this.vsync)
      : super(debugLabel: kDebugMode ? vsync.key.toString() : null) {
    _tickers.add(this);
    muted = Vsync._muted;
    if (vsync.context != null) {
      updateNotifier();
    }
  }

  final Vsync vsync;
  ValueListenable<bool> _enabledNotifier = const _UnsetNotifier();

  /// Only when [Vsync.context] is non-null.
  void updateNotifier() {
    final newNotifier = TickerMode.getNotifier(vsync.context!);
    if (newNotifier != _enabledNotifier) {
      _enabledNotifier.removeListener(_listener);
      _enabledNotifier = newNotifier..addListener(_listener);
      muted = !_enabledNotifier.value;
    }
  }

  void _listener() {
    muted = _enabledNotifier.value;
  }

  @override
  void dispose() {
    _enabledNotifier.removeListener(_listener);
    _tickers.remove(this);
    super.dispose();
  }
}

class _UnsetNotifier implements ValueListenable<bool> {
  /// Supports [removeListener] but nothing else.
  const _UnsetNotifier();

  @override
  Never get value => throw StateError("Vsync's ticker notifier is not set");

  @override
  void addListener(VoidCallback listener) => value;

  @override
  void removeListener(VoidCallback listener) {}
}
