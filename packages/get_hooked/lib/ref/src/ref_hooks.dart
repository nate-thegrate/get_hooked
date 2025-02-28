// ignore_for_file: invalid_use_of_visible_for_testing_member, these hooks are meant to access internal stuff :)
// ignore_for_file: avoid_positional_boolean_parameters, private hook functions are more readable this way

part of '../ref.dart';

class _GetSelect<Result, T> extends HookData<Result> {
  const _GetSelect(this.hooked, this.selector, {required this.watching}) : super(key: hooked);

  final bool watching;

  final ValueListenable<T> hooked;
  final Result Function(T value) selector;

  @override
  _SelectHook<Result, T> createHook() => _SelectHook();
}

class _SelectHook<Result, T> extends Hook<Result, _GetSelect<Result, T>> {
  late final ValueListenable<T> listenable = data.hooked;
  late bool watching = data.watching;

  Result get result => data.selector(listenable.value);
  late Result previous = result;

  @override
  void initHook() {
    if (watching) listenable.addListener(markMayNeedRebuild);
  }

  @override
  void didUpdate(_GetSelect<Result, T> oldData) {
    final bool newWatching = data.watching;
    if (!newWatching) {
      listenable.removeListener(markMayNeedRebuild);
    } else if (!watching) {
      listenable.addListener(markMayNeedRebuild);
    }
  }

  @override
  void dispose() => listenable.removeListener(markMayNeedRebuild);

  @override
  bool shouldRebuild() => data.watching && result != previous;

  @override
  Result build() => previous = result;
}

typedef _TickerMode = ValueListenable<bool>;

class _VsyncHook extends Hook<void, GetVsyncAny> implements Vsync {
  late GetVsyncAny get = data;
  Ticker? _ticker;
  StyledAnimation<Object?>? _animation;
  _StyleNotifier? _styleNotifier;
  _TickerMode? _tickerMode;

  @override
  void initHook() {
    registry.activate(data);
  }

  void _updateStyle() {
    _animation?.updateStyle(_styleNotifier!.value);
  }

  void _updateTickerMode() {
    _ticker?.muted = _tickerMode!.value;
  }

  @override
  Ticker createTicker(TickerCallback onTick) {
    final Ticker ticker = _ticker = Ticker(onTick);

    (_tickerMode ??= TickerMode.getNotifier(context)).addListener(_updateTickerMode);
    _updateTickerMode();

    return ticker;
  }

  @override
  void registerAnimation(StyledAnimation<Object?> animation) {
    assert(identical(animation, data), 'An animation tried to register a different animation.');
    _animation = animation;

    (_styleNotifier ??= DefaultAnimationStyle.getNotifier(context)).addListener(_updateStyle);
    _updateStyle();
  }

  @override
  void unregisterAnimation(StyledAnimation<Object?> animation) {
    _styleNotifier?.removeListener(_updateStyle);
  }

  @override
  void activate() {
    if (_styleNotifier != null) {
      final _StyleNotifier newNotifier = DefaultAnimationStyle.getNotifier(context);
      if (newNotifier != _styleNotifier) {
        _styleNotifier?.removeListener(_updateStyle);
        _styleNotifier = newNotifier..addListener(_updateStyle);
        _updateStyle();
      }
    }
    if (_tickerMode != null) {
      final _TickerMode newNotifier = TickerMode.getNotifier(context);
      if (newNotifier != _tickerMode) {
        _tickerMode?.removeListener(_updateTickerMode);
        _tickerMode = newNotifier..addListener(_updateTickerMode);
        _updateTickerMode();
      }
    }
  }

  @override
  void dispose() {
    _styleNotifier?.removeListener(_updateStyle);
    _tickerMode?.removeListener(_updateTickerMode);
    registry.reset(data);
    super.dispose();
  }

  @override
  void build() {}
}

mixin _RefAnimationProvider<Result> on Hook<Result, RefComputer<Result>> implements Vsync {
  Set<Ticker>? _tickers;
  _TickerMode? _tickerMode;

  Set<StyledAnimation<Object?>>? _animations;
  _StyleNotifier? _styleNotifier;

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = Ticker(onTick);
    (_tickers ??= {}).add(ticker);

    return ticker
      ..muted =
          (_tickerMode ??= TickerMode.getNotifier(context)..addListener(_updateTickers)).value;
  }

  @override
  void registerAnimation(StyledAnimation<Object?> animation) {
    (_animations ??= {}).add(animation);
    animation.updateStyle(
      (_styleNotifier ??= DefaultAnimationStyle.getNotifier(context)..addListener(_updateStyles))
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
      final _TickerMode newNotifier = TickerMode.getNotifier(context);
      if (newNotifier != _tickerMode) {
        _tickerMode?.removeListener(_updateTickers);
        _tickerMode = newNotifier..addListener(_updateTickers);
      }
    }

    if (_styleNotifier != null) {
      final _StyleNotifier newNotifier = DefaultAnimationStyle.getNotifier(context);
      if (newNotifier != _styleNotifier) {
        _styleNotifier?.removeListener(_updateStyles);
        _styleNotifier = newNotifier..addListener(_updateStyles);
      }
    }
  }

  @override
  void dispose() {
    for (final Ticker ticker in _tickers ?? const {}) {
      ticker.dispose();
    }
    _tickerMode?.removeListener(_updateTickers);
    _styleNotifier?.removeListener(_updateStyles);
    super.dispose();
  }
}

class _RefComputerHook<Result> extends Hook<Result, RefComputer<Result>>
    with _RefAnimationProvider
    implements ComputeRef {
  bool _needsDependencies = true;
  final _rootDependencies = <ValueRef>{};
  var _scopedDependencies = <Listenable>{};
  Listenable get _listenable => Listenable.merge(_scopedDependencies);

  final _selections = <_ScopedSelection<Object?, Object?>>{};

  final _rootAnimations = <Animation<Object?>>{};
  var _managedAnimations = <Animation<Object?>>{};

  late Result result;
  bool _dirty = true;

  Result compute() => data(this);

  @override
  bool shouldRebuild() {
    final Result newResult = compute();
    _dirty = false;

    final bool changed = newResult != result;
    result = newResult;
    return changed;
  }

  @override
  void initHook() {
    result = compute();
    _needsDependencies = false;
    _listenable.addListener(markMayNeedRebuild);
  }

  G _read<G extends ValueRef>(G get, {bool autoVsync = true, bool useScope = true}) {
    final G scoped = useScope ? GetScope.of(context, get) : get;
    if (_needsDependencies && autoVsync && get is Animation<Object?>) {
      if (scoped is! Animation<Object?>) {
        assert(() {
          // An invalid substitution was made, so throw the FlutterError from GetScope.
          GetScope.of<Animation<Object?>>(context, get);
          throw StateError(
            'That GetScope.of(context) method should have thrown an error.\n'
            "If somehow you've managed to trigger this message, that's wild! "
            '$bugReport',
          );
        }());
        return scoped;
      }
      _rootAnimations.add(get);
      if (get == scoped) {
        // If a substitution was made, the GetScope acts as the ticker provider.
        // Otherwise, this hook does it.
        _managedAnimations.add(get);
        registry.activate(get);
      }
    }
    return scoped;
  }

  @override
  T watch<T>(GetT<T> get, {bool autoVsync = true, bool useScope = true}) {
    final GetT<T> scoped = _read(get, useScope: useScope);
    if (_needsDependencies) {
      _rootDependencies.add(get);
      _scopedDependencies.add(scoped);
    }
    return scoped.value;
  }

  @override
  R select<R, T>(
    ValueListenable<T> get,
    R Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    final ValueListenable<T> scoped = _read(get, useScope: useScope, autoVsync: autoVsync);
    if (_needsDependencies) {
      _selections.add(_ScopedSelection<R, T>(context, get, selector, markMayNeedRebuild));
    }
    return selector(scoped.value);
  }

  @override
  void didChangeDependencies() {
    final newDependencies = <Listenable>{
      for (final get in _rootDependencies) GetScope.of(context, get),
    };
    if (!setEquals(newDependencies, _scopedDependencies)) {
      _listenable.removeListener(markMayNeedRebuild);
      _scopedDependencies = newDependencies;
      _listenable.addListener(markMayNeedRebuild);
    }

    final animations = <Animation<Object?>>{
      for (final Animation<Object?> animation in _rootAnimations)
        if (GetScope.maybeOf(context, animation) == null) animation,
    };
    if (!setEquals(animations, _managedAnimations)) {
      _managedAnimations.difference(animations).forEach(registry.reset);
      animations.difference(_managedAnimations).forEach(registry.activate);
      _managedAnimations = animations;
    }

    for (final _ScopedSelection<Object?, Object?> selection in _selections) {
      selection.rescope();
    }
  }

  @override
  void dispose() {
    _listenable.removeListener(markMayNeedRebuild);
    _managedAnimations.forEach(registry.reset);
    for (final _ScopedSelection<Object?, Object?> selection in _selections) {
      selection.dispose();
    }
  }

  /// Calls [compute] to update the [result], unless [shouldRebuild] has just been called.
  @override
  Result build() {
    if (_dirty) result = compute();
    _dirty = true;
    return result;
  }
}

/// Listens to the scoped version of [root], calling [listener] when the selected value changes.
class _ScopedSelection<Result, T> {
  _ScopedSelection(this.context, this.root, this.selector, this.listener)
    : scoped = GetScope.of(context, root) {
    scoped.addListener(_scopedListener);
    value = selector(scoped.value);
  }

  final BuildContext context;
  final ValueListenable<T> root;
  ValueListenable<T> scoped;

  final Result Function(T) selector;
  late Result value;
  final VoidCallback listener;

  void _scopedListener() {
    final Result newValue = selector(scoped.value);
    if (newValue == value) return;

    value = newValue;
    listener();
  }

  void rescope() {
    final ValueListenable<T> newScoped = GetScope.of(context, root);
    if (newScoped == scoped) return;

    scoped.removeListener(_scopedListener);
    scoped = newScoped..addListener(_scopedListener);
    _scopedListener();
  }

  void dispose() {
    scoped.removeListener(_scopedListener);
  }
}
