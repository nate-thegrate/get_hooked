import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/src/hook_ref/hook_ref.dart';
import 'package:get_hooked/src/substitution/substitution.dart';

import '../listenables.dart';

typedef _StyleNotifier = ValueListenable<AnimationStyle>;
typedef _TickerMode = ValueListenable<TickerModeData>;
typedef _AnimationSet = Set<StyledAnimation<Object?>>;

abstract interface class _Tickers {
  abstract final Set<Ticker>? _tickers;

  Widget get widget;
}

/// A mixin that implements the [Vsync] interface.
@optionalTypeArgs // as if anyone is using always_specify_types, lol
mixin StateVsync<T extends StatefulWidget> on State<T> implements Vsync, _Tickers {
  @override
  Set<Ticker>? _tickers;
  _TickerMode? _tickerMode;

  _AnimationSet? _animations;
  _StyleNotifier? _styleNotifier;

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = _ElementVsyncTicker(onTick, this);
    (_tickers ??= {}).add(ticker);

    final ValueListenable<TickerModeData> tickerMode = _tickerMode ??=
        TickerMode.getValuesNotifier(context)..addListener(_updateTickers);

    return ticker
      ..muted = !tickerMode.value.enabled
      ..forceFrames = tickerMode.value.forceFrames;
  }

  @override
  void registerAnimation(StyledAnimation<Object?> animation) {
    (_animations ??= {}).add(animation);
    animation.updateStyle(
      (_styleNotifier ??= DefaultAnimationStyle.getNotifier(
        context,
      )..addListener(_updateStyles)).value,
    );
  }

  @override
  void unregisterAnimation(StyledAnimation<Object?> animation) {
    _animations?.remove(animation);
  }

  void _updateTickers() {
    final TickerModeData(:bool enabled, :bool forceFrames) = _tickerMode!.value;
    for (final Ticker ticker in _tickers ?? const {}) {
      ticker
        ..muted = !enabled
        ..forceFrames = forceFrames;
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
      final _TickerMode newNotifier = TickerMode.getValuesNotifier(context);
      if (newNotifier != _tickerMode) {
        _tickerMode?.removeListener(_updateTickers);
        _tickerMode = newNotifier..addListener(_updateTickers);
        _updateTickers();
      }
    }

    if (_styleNotifier != null) {
      final _StyleNotifier newNotifier = DefaultAnimationStyle.getNotifier(context);
      if (newNotifier != _styleNotifier) {
        _styleNotifier?.removeListener(_updateStyles);
        _styleNotifier = newNotifier..addListener(_updateStyles);
        _updateStyles();
      }
    }
  }

  @override
  void dispose() {
    _tickerMode?.removeListener(_updateTickers);
    _styleNotifier?.removeListener(_updateStyles);
    super.dispose();
  }
}

/// A mixin that implements the [Vsync] interface.
mixin HookVsync<Result, Data> on Hook<Result, Data> implements Vsync, _Tickers {
  @override
  Widget get widget => context.widget;

  @override
  Set<Ticker>? _tickers;
  _TickerMode? _tickerMode;

  _AnimationSet? _animations;
  _StyleNotifier? _styleNotifier;

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = _ElementVsyncTicker(onTick, this);
    (_tickers ??= {}).add(ticker);

    final ValueListenable<TickerModeData> tickerMode = _tickerMode ??=
        TickerMode.getValuesNotifier(context)..addListener(_updateTickers);

    return ticker
      ..muted = !tickerMode.value.enabled
      ..forceFrames = tickerMode.value.forceFrames;
  }

  @override
  void registerAnimation(StyledAnimation<Object?> animation) {
    (_animations ??= {}).add(animation);
    animation.updateStyle(
      (_styleNotifier ??= DefaultAnimationStyle.getNotifier(
        context,
      )..addListener(_updateStyles)).value,
    );
  }

  @override
  void unregisterAnimation(StyledAnimation<Object?> animation) {
    _animations?.remove(animation);
  }

  void _updateStyles() {
    for (final StyledAnimation<Object?> animation in _animations ?? const {}) {
      animation.updateStyle(_styleNotifier!.value);
    }
  }

  void _updateTickers() {
    final TickerModeData(:bool enabled, :bool forceFrames) = _tickerMode!.value;
    for (final Ticker ticker in _tickers ?? const {}) {
      ticker
        ..muted = !enabled
        ..forceFrames = forceFrames;
    }
  }

  @override
  void activate() {
    if (_styleNotifier != null) {
      final _StyleNotifier newNotifier = DefaultAnimationStyle.getNotifier(context);
      if (newNotifier != _styleNotifier) {
        _styleNotifier?.removeListener(_updateStyles);
        _styleNotifier = newNotifier..addListener(_updateStyles);
        _updateStyles();
      }
    }
    if (_tickerMode != null) {
      final _TickerMode newNotifier = TickerMode.getValuesNotifier(context);
      if (newNotifier != _tickerMode) {
        _tickerMode?.removeListener(_updateTickers);
        _tickerMode = newNotifier..addListener(_updateTickers);
        _updateTickers();
      }
    }
  }

  @override
  void dispose() {
    _tickerMode?.removeListener(_updateTickers);
    _styleNotifier?.removeListener(_updateStyles);
    super.dispose();
  }
}

/// A mixin that implements the [Vsync] interface.
mixin ElementVsync on Element implements VsyncContext, _Tickers {
  @override
  Set<Ticker>? _tickers;
  _TickerMode? _tickerMode;

  _AnimationSet? _animations;
  _StyleNotifier? _styleNotifier;

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = _ElementVsyncTicker(onTick, this);
    (_tickers ??= {}).add(ticker);

    final ValueListenable<TickerModeData> tickerMode = _tickerMode ??=
        TickerMode.getValuesNotifier(this)..addListener(_updateTickers);

    return ticker
      ..muted = !tickerMode.value.enabled
      ..forceFrames = tickerMode.value.forceFrames;
  }

  @override
  void registerAnimation(StyledAnimation<Object?> animation) {
    (_animations ??= {}).add(animation);
    animation.updateStyle(
      (_styleNotifier ??= DefaultAnimationStyle.getNotifier(
        this,
      )..addListener(_updateStyles)).value,
    );
  }

  @override
  void unregisterAnimation(StyledAnimation<Object?> animation) {
    _animations?.remove(animation);
  }

  void _updateTickers() {
    final TickerModeData(:bool enabled, :bool forceFrames) = _tickerMode!.value;
    for (final Ticker ticker in _tickers ?? const {}) {
      ticker
        ..muted = !enabled
        ..forceFrames = forceFrames;
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
      final _TickerMode newNotifier = TickerMode.getValuesNotifier(this);
      if (newNotifier != _tickerMode) {
        _tickerMode?.removeListener(_updateTickers);
        _tickerMode = newNotifier..addListener(_updateTickers);
        _updateTickers();
      }
    }

    if (_styleNotifier != null) {
      final _StyleNotifier newNotifier = DefaultAnimationStyle.getNotifier(this);
      if (newNotifier != _styleNotifier) {
        _styleNotifier?.removeListener(_updateStyles);
        _styleNotifier = newNotifier..addListener(_updateStyles);
        _updateStyles();
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

    final ValueListenable<TickerModeData> tickerMode = _tickerMode ??=
        TickerMode.getValuesNotifier(this)..addListener(_updateTickers);

    return ticker
      ..muted = !tickerMode.value.enabled
      ..forceFrames = tickerMode.value.forceFrames;
  }

  @override
  void registerAnimation(StyledAnimation<Object?> animation) {
    (_animations ??= {}).add(animation);
    animation.updateStyle(
      (_styleNotifier ??= DefaultAnimationStyle.getNotifier(
        this,
      )..addListener(_updateStyles)).value,
    );
  }

  @override
  void unregisterAnimation(StyledAnimation<Object?> animation) {
    _animations?.remove(animation);
  }

  @override
  void _updateTickers() {
    final TickerModeData(:bool enabled, :bool forceFrames) = _tickerMode!.value;
    for (final Ticker ticker in _tickers ?? const {}) {
      ticker
        ..muted = !enabled
        ..forceFrames = forceFrames;
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
      final _TickerMode newNotifier = TickerMode.getValuesNotifier(this);
      if (newNotifier != _tickerMode) {
        _tickerMode?.removeListener(_updateTickers);
        _tickerMode = newNotifier..addListener(_updateTickers);
        _updateTickers();
      }
    }

    if (_styleNotifier != null) {
      final _StyleNotifier newNotifier = DefaultAnimationStyle.getNotifier(this);
      if (newNotifier != _styleNotifier) {
        _styleNotifier?.removeListener(_updateStyles);
        _styleNotifier = newNotifier..addListener(_updateStyles);
        _updateStyles();
      }
    }
  }

  @override
  T watch<T>(ValueListenable<T> get, {bool autoVsync = true, bool useScope = true}) {
    final (scoped, value) = read(get, useScope: useScope && _hasScope);
    if (_needsDependencies) {
      scoped.addListener(recompute);
      _disposers.add(() => scoped.removeListener(recompute));

      if (get == scoped && autoVsync && get is VsyncValue<T>) {
        if (registry.add(get)) _disposers.add(() => registry.remove(get));
      }
    }
    return value;
  }

  @override
  Result select<Result, T>(
    ValueListenable<T> get,
    Result Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    final (scoped, value) = read(get, useScope: useScope && _hasScope);
    Result currentValue = selector(value);
    if (_needsDependencies) {
      void checkSelection() {
        final Result newValue = selector(read(get, useScope: useScope && _hasScope).$2);
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

  bool get _hasScope => _subTag != null;
  Object? _subTag;
  Object? get _newTag => getInheritedWidgetOfExactType<SubstitutionModel>()?.equalityTag;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _subTag = _newTag;
    recompute();
    _needsDependencies = false;
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

    final Object? newTag = _newTag;
    if (newTag != _subTag) {
      _subTag = newTag;
      _resetListeners();
    }
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

  final _Tickers _creator;

  @override
  void dispose() {
    _creator._tickers?.remove(this);
    super.dispose();
  }
}

mixin _Render<R extends RenderObject> on RenderObjectElement {
  R get renderer => renderObject as R;
}

/// A convenience class for making a [SingleChildRenderObjectWidget] with a
/// [RefComputer].
//
// dart format off
abstract class SingleChildComputeElement<Render extends RenderObject> =
    SingleChildRenderObjectElement with ElementCompute, _Render<Render>;
