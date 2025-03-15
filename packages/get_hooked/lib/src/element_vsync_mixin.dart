import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/src/hook_ref/hook_ref.dart';
import 'package:get_hooked/src/substitution/substitution.dart';

import '../listenables.dart';

typedef _StyleNotifier = ValueListenable<AnimationStyle>;
typedef _TickerMode = ValueListenable<bool>;
typedef _AnimationSet = Set<StyledAnimation<Object?>>;

/// A mixin that implements the [Vsync] interface.
mixin ElementVsync on Element implements VsyncContext {
  Set<Ticker>? _tickers;
  _TickerMode? _tickerMode;

  _AnimationSet? _animations;
  _StyleNotifier? _styleNotifier;

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = _ElementVsyncTicker(onTick, this);
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
    for (final StyledAnimation<Object?> animation in _animations ?? const {}) {
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
    _tickerMode?.removeListener(_updateTickers);
    _styleNotifier?.removeListener(_updateStyles);
    super.unmount();
  }
}

/// Allows any [Element] declaration to act as a [ComputeContext].
//
// Duplicated logic, since we don't have mixin composition!
mixin ElementCompute on Element implements ComputeContext, ElementVsync {
  final _disposers = <VoidCallback>{};
  bool _needsDependencies = true;

  /// Subtypes implement this method to trigger an update.
  void recompute();

  @override
  Set<Ticker>? _tickers;
  @override
  _TickerMode? _tickerMode;

  @override
  _AnimationSet? _animations;
  @override
  _StyleNotifier? _styleNotifier;

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = _ElementVsyncTicker(onTick, this);
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

  @override
  void _updateTickers() {
    for (final Ticker ticker in _tickers ?? const {}) {
      ticker.muted = _tickerMode!.value;
    }
  }

  @override
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
  T watch<T>(ValueListenable<T> get, {bool autoVsync = true, bool useScope = true}) {
    final ValueListenable<T> scoped = useScope && _hasScope ? GetScope.of(this, get) : get;
    if (_needsDependencies) {
      scoped.addListener(recompute);
      _disposers.add(() => scoped.removeListener(recompute));

      if (get == scoped && autoVsync && get is VsyncValue<T>) {
        if (registry.add(get)) _disposers.add(() => registry.remove(get));
      }
    }
    return scoped.value;
  }

  @override
  Result select<Result, T>(
    ValueListenable<T> get,
    Result Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    final ValueListenable<T> scoped = useScope && _hasScope ? GetScope.of(this, get) : get;
    Result currentValue = selector(scoped.value);
    if (_needsDependencies) {
      void checkSelection() {
        final Result newValue = selector(get.value);
        if (newValue != currentValue) {
          currentValue = newValue;
          recompute();
        }
      }

      scoped.addListener(checkSelection);
      _disposers.add(() => scoped.removeListener(checkSelection));

      if (get == scoped && autoVsync && get is VsyncValue<T>) {
        if (registry.add(get)) _disposers.add(() => registry.remove(get));
      }
    }
    return currentValue;
  }

  bool get _hasScopeNow =>
      getInheritedWidgetOfExactType<SubModel<ValueListenable<Object?>>>() != null;
  bool _hasScope = true;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    recompute();
    _needsDependencies = false;
    _hasScope = _hasScopeNow;
  }

  void _resetListeners() {
    for (final VoidCallback dispose in _disposers) {
      dispose();
    }
    _disposers.clear();
    _needsDependencies = true;
    recompute();
    _needsDependencies = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool hasScopeNow = _hasScopeNow;
    if (_hasScope || hasScopeNow) _resetListeners();
    _hasScope = hasScopeNow;
  }

  @override
  void reassemble() {
    super.reassemble();
    _resetListeners();
  }

  @override
  void unmount() {
    for (final VoidCallback dispose in _disposers) {
      dispose();
    }
    _disposers.clear();

    for (final Ticker ticker in _tickers ?? const {}) {
      ticker.dispose();
    }
    _tickerMode?.removeListener(_updateTickers);
    _styleNotifier?.removeListener(_updateStyles);
    _animations?.forEach(registry.remove);
    super.unmount();
  }
}

class _ElementVsyncTicker extends Ticker {
  _ElementVsyncTicker(super.onTick, this._creator)
    : super(debugLabel: 'created by ${describeIdentity(_creator.widget)}');

  final ElementVsync _creator;

  @override
  void dispose() {
    _creator._tickers?.remove(this);
    super.dispose();
  }
}

mixin _Render<R extends RenderObject> on RenderObjectElement {
  @override
  late final R renderObject = super.renderObject as R;
}

/// A convenience class for making a [SingleChildRenderObjectWidget] with a
/// [RefComputer].
//
// dart format off
abstract class SingleChildComputeElement<Render extends RenderObject> =
    SingleChildRenderObjectElement with ElementCompute, _Render<Render>;
