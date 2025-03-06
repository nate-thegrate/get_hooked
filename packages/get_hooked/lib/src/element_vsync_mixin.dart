import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/src/hook_ref/hook_ref.dart';
import 'package:get_hooked/src/scoped_selection.dart';
import 'package:get_hooked/src/substitution/substitution.dart';

import '../listenables.dart';

typedef _V = ValueListenable<Object?>;
typedef _StyleNotifier = ValueListenable<AnimationStyle>;
typedef _TickerMode = ValueListenable<bool>;
typedef _AnimationSet = Set<VsyncValue<Object?>>;
typedef _Selection = ScopedSelection<Object?, Object?>;

/// A mixin that implements the [Vsync] interface.
mixin ElementVsync on Element implements VsyncContext {
  Set<Ticker>? _tickers;
  _TickerMode? _tickerMode;

  _AnimationSet? _animations;
  _StyleNotifier? _styleNotifier;

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = Ticker(onTick);
    (_tickers ??= {}).add(ticker);

    return ticker
      ..muted = (_tickerMode ??= TickerMode.getNotifier(this)..addListener(_updateTickers)).value;
  }

  @override
  void registerAnimation(StyledAnimation<Object?> animation) {
    (_animations ??= {}).add(animation);
    animation.updateStyle(
      (_styleNotifier ??= DefaultAnimationStyle.getNotifier(this)..addListener(_updateStyles))
          .value,
    );
  }

  @override
  void unregisterAnimation(StyledAnimation<Object?> animation) {
    _animations?.remove(animation);
  }

  void _updateTickers() {
    for (final Ticker ticker in _tickers ?? const {}) {
      ticker.muted = _tickerMode!.value;
    }
  }

  void _updateStyles() {
    for (final StyledAnimation<Object?> animation in _animations?.whereType() ?? const {}) {
      animation.updateStyle(_styleNotifier!.value);
    }
  }

  @override
  void activate() {
    super.activate();

    if (_tickerMode != null) {
      final _TickerMode newNotifier = TickerMode.getNotifier(this);
      if (newNotifier != _tickerMode) {
        _tickerMode?.removeListener(_updateTickers);
        _tickerMode = newNotifier..addListener(_updateTickers);
      }
    }

    if (_styleNotifier != null) {
      final _StyleNotifier newNotifier = DefaultAnimationStyle.getNotifier(this);
      if (newNotifier != _styleNotifier) {
        _styleNotifier?.removeListener(_updateStyles);
        _styleNotifier = newNotifier..addListener(_updateStyles);
      }
    }
  }

  @override
  void unmount() {
    for (final Ticker ticker in _tickers ?? const {}) {
      ticker.dispose();
    }
    _tickerMode?.removeListener(_updateTickers);
    _styleNotifier?.removeListener(_updateStyles);
    super.unmount();
  }
}

typedef _Selectors = Map<Listenable, _Selection>;

extension on _Selectors {
  Result select<Result, T>(ValueListenable<T> listenable) {
    if (this[listenable] case ScopedSelection(:final Result value)) {
      return value;
    }
    throw StateError('unexpected map entry: (key: "$listenable", value: "${this[listenable]}")');
  }
}

/// Allows any [Element] declaration to act as a [ComputeContext].
mixin ElementCompute on Element implements ComputeContext {
  final _dependencies = SubMap<_V>({});
  final _Selectors _selectors = {};
  bool _needsDependencies = true;

  /// Subtypes implement this method to trigger an update.
  void recompute();

  Set<Ticker>? _tickers;
  _TickerMode? _tickerMode;

  _AnimationSet? _animations;
  _StyleNotifier? _styleNotifier;

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = Ticker(onTick);
    (_tickers ??= {}).add(ticker);

    return ticker
      ..muted = (_tickerMode ??= TickerMode.getNotifier(this)..addListener(_updateTickers)).value;
  }

  @override
  void registerAnimation(StyledAnimation<Object?> animation) {
    (_animations ??= {}).add(animation);
    animation.updateStyle(
      (_styleNotifier ??= DefaultAnimationStyle.getNotifier(this)..addListener(_updateStyles))
          .value,
    );
  }

  @override
  void unregisterAnimation(StyledAnimation<Object?> animation) {
    _animations?.remove(animation);
  }

  void _updateTickers() {
    for (final Ticker ticker in _tickers ?? const {}) {
      ticker.muted = _tickerMode!.value;
    }
  }

  void _updateStyles() {
    for (final StyledAnimation<Object?> animation in _animations?.whereType() ?? const {}) {
      animation.updateStyle(_styleNotifier!.value);
    }
  }

  @override
  void activate() {
    super.activate();

    if (_tickerMode != null) {
      final _TickerMode newNotifier = TickerMode.getNotifier(this);
      if (newNotifier != _tickerMode) {
        _tickerMode?.removeListener(_updateTickers);
        _tickerMode = newNotifier..addListener(_updateTickers);
      }
    }

    if (_styleNotifier != null) {
      final _StyleNotifier newNotifier = DefaultAnimationStyle.getNotifier(this);
      if (newNotifier != _styleNotifier) {
        _styleNotifier?.removeListener(_updateStyles);
        _styleNotifier = newNotifier..addListener(_updateStyles);
      }
    }
  }

  @override
  void unmount() {
    for (final Ticker ticker in _tickers ?? const {}) {
      ticker.dispose();
    }
    _tickerMode?.removeListener(_updateTickers);
    _styleNotifier?.removeListener(_updateStyles);
    _animations?.forEach(registry.remove);
    for (final _Selection selection in _selectors.values) {
      selection.dispose();
    }
    super.unmount();
  }

  @override
  T watch<T>(ValueListenable<T> get, {bool autoVsync = true, bool useScope = true}) {
    if (_needsDependencies) {
      if (autoVsync && get is VsyncValue<T>) {
        registry.add(get);
      }
      final ValueListenable<T> scoped = useScope ? GetScope.of(this, get) : get;
      _dependencies[get] = scoped;
      return scoped.value;
    }
    return _dependencies.get(get).value;
  }

  @override
  Result select<Result, T>(
    ValueListenable<T> get,
    Result Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    if (_needsDependencies) {
      final ScopedSelection<Result, T> selection =
          _selectors[get] = ScopedSelection<Result, T>(this, get, selector, recompute);
      return selection.value;
    }
    return _selectors.select(get);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _needsDependencies = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Set<_V> oldDependencies = _dependencies.values.toSet();
    final newDependencies = <_V>{
      for (final dependency in _dependencies.keys) GetScope.of(this, dependency),
    };
    if (!setEquals(oldDependencies, newDependencies)) {
      Listenable.merge(oldDependencies.difference(newDependencies)).removeListener(recompute);
      Listenable.merge(newDependencies.difference(oldDependencies)).addListener(recompute);
    }
    for (final _Selection selection in _selectors.values) {
      selection.rescope();
    }
  }

  @override
  void reassemble() {
    _animations?.forEach(registry.remove);
    for (final _Selection selection in _selectors.values) {
      selection.dispose();
    }
    _dependencies.clear();
    _selectors.clear();
    _needsDependencies = true;
    super.reassemble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _needsDependencies = false;
    });
  }
}
