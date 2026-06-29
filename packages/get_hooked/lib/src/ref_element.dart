import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/src/scope.dart';

import '../listenables.dart';

typedef _StyleNotifier = ValueListenable<AnimationStyle>;
typedef _TickerMode = ValueListenable<TickerModeData>;
typedef _AnimationSet = Set<StyledAnimation<Object?>>;

abstract interface class _Tickers {
  abstract final Set<Ticker>? _tickers;

  Widget get widget;
}

/// An extension that provides a [Vsync] from the element's [BuildContext].
///
/// Replaces the former `StateVsync` mixin.
extension StateVsync<T extends StatefulWidget> on State<T> {
  /// Returns the [Vsync] associated with this [State]'s [BuildContext].
  Vsync get vsync => context as Vsync;
}

/// A mixin that implements the [Vsync] interface.
mixin ElementVsync on Element implements Vsync, _Tickers {
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

/// Allows any [Element] declaration to act as a [RefContext].
//
// Duplicated logic, since we don't have mixin composition!
mixin ElementCompute on Element implements RefContext, _Tickers {
  final _subscriptions = <ValueListenable<Object?>>{};
  final _disposers = <VoidCallback>{};

  /// Keys are listenables, values are disposers
  final _selectors = <ValueListenable<Object?>, VoidCallback>{};

  /// Subtypes implement this method to trigger an update.
  void recompute();

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
  T watch<T>(ValueListenable<T> listenable, {bool autoVsync = true, bool useScope = true}) {
    final (scoped, value) = read(listenable, useScope: useScope && _hasScope);
    if (_subscriptions.add(listenable)) {
      scoped.addListener(recompute);
      _disposers.add(() => scoped.removeListener(recompute));

      if (listenable == scoped && autoVsync && listenable is VsyncValue<T>) {
        if (registry.add(listenable)) _disposers.add(() => registry.remove(listenable));
      }
    }
    return value;
  }

  @override
  Result select<Result, T>(
    ValueListenable<T> listenable,
    Result Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    final (scoped, value) = read(listenable, useScope: useScope && _hasScope);
    Result currentValue = selector(value);
    void checkSelection() {
      final Result newValue = selector(read(listenable, useScope: useScope && _hasScope).$2);
      if (newValue != currentValue) {
        currentValue = newValue;
        recompute();
      }
    }

    _selectors.remove(listenable)?.call();
    scoped.addListener(checkSelection);
    _selectors[listenable] = () => scoped.removeListener(checkSelection);

    if (listenable == scoped && autoVsync && listenable is VsyncValue<T>) {
      if (registry.add(listenable)) _disposers.add(() => registry.remove(listenable));
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
  }

  void _resetListeners() {
    for (final VoidCallback dispose in _disposers.followedBy(_selectors.values)) {
      dispose();
    }
    _disposers.clear();
    _selectors.clear();
    recompute();
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

/// Provides access to the current [RefElement] during a build.
///
/// Must only be accessed inside a [RefWidget.build] or [RefBuilder] callback.
///
/// In debug mode, gives a detailed error message when accessed outside of a build.
Ref get ref {
  final RefContext? current = RefContext.current;
  if (kDebugMode && current == null) {
    throw FlutterError.fromParts([
      ErrorSummary('ref was accessed outside of a RefWidget build method.'),
      ErrorDescription(
        'The ref getter can only be used inside a RefWidget.build, '
        'StatefulRefWidget State.build, or RefBuilder callback.',
      ),
      ErrorHint(
        'If you need to watch a ValueListenable outside of a build method, '
        'consider using ValueListenableBuilder or directly adding a listener.',
      ),
    ]);
  }
  return current!;
}

/// A mixin on [ComponentElement] that implements the [Ref] interface
/// for [RefWidget], [StatefulRefWidget], and [RefBuilder].
///
/// Instead of using hooks with positional tracking, [RefElement] tracks
/// subscriptions by identity: calling [watch] with the same listenable
/// multiple times is safe (it simply reuses the existing subscription).
///
/// Calling [select] with the same listenable more than once during a
/// single build will throw in debug mode.
base mixin RefElement on ComponentElement implements RefContext, _Tickers {

  /// Listeners added by [watch].
  final _watchedListenables = <Listenable, VoidCallback>{};

  /// Listenables subscribed to via [select].
  final _selectedListenables = <Listenable, VoidCallback>{};

  /// Tracks listenables selected during the current build, for duplicate detection.
  Set<Listenable>? _selectionsThisBuild;

  /// Animations auto-registered with the vsync provider.
  final _managedAnimations = <VsyncValue<Object?>>{};

  /// Scope tag, used to detect scope changes.
  Object? _scopeTag;

  Object? get _newScopeTag => getInheritedWidgetOfExactType<SubstitutionModel>()?.equalityTag;


  @override
  T watch<T>(ValueListenable<T> listenable, {bool autoVsync = true, bool useScope = true}) {
    final (scoped, value) = read(listenable, useScope: useScope);

    // Subscribe if not already subscribed.
    if (!_watchedListenables.containsKey(scoped)) {
      void listener() => markNeedsBuild();
      scoped.addListener(listener);
      _watchedListenables[scoped] = listener;
    }

    // Auto-vsync: register animations with the ticker provider.
    if (autoVsync && scoped == listenable && listenable is VsyncValue<Object?>) {
      final animation = listenable as VsyncValue<Object?>;
      if (_managedAnimations.add(animation)) {
        registry.add(animation);
      }
    }

    return value;
  }

  @override
  Result select<Result, T>(
    ValueListenable<T> listenable,
    Result Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    final (scoped, value) = read(listenable, useScope: useScope);

    // In debug mode, throw if the same listenable is selected twice in one build.
    assert(() {
      if (_selectionsThisBuild != null && !_selectionsThisBuild!.add(scoped)) {
        throw FlutterError.fromParts([
          ErrorSummary('ref.select() called multiple times with the same listenable.'),
          ErrorDescription(
            'A build method or RefComputer callback called ref.select() more than once '
            'with ${describeIdentity(listenable)}.',
          ),
          ErrorHint(
            'Combine multiple selections into a single ref.select() call '
            'that returns a Record, for example:\n'
            '  final (a, b) = ref.select(listenable, (v) => (v.a, v.b));',
          ),
        ]);
      }
      return true;
    }());

    Result currentValue = selector(value);

    // Subscribe if not already subscribed for selection.
    if (!_selectedListenables.containsKey(scoped)) {
      void listener() {
        final Result newValue = selector(read(listenable, useScope: useScope).$2);
        if (newValue != currentValue) {
          currentValue = newValue;
          markNeedsBuild();
        }
      }

      scoped.addListener(listener);
      _selectedListenables[scoped] = listener;
    }

    // Auto-vsync.
    if (autoVsync && scoped == listenable && listenable is VsyncValue<Object?>) {
      final animation = listenable as VsyncValue<Object?>;
      if (_managedAnimations.add(animation)) {
        registry.add(animation);
      }
    }

    return currentValue;
  }

  /// Returns the provided [RefComputer]'s output and triggers a rebuild
  /// when any of the referenced values change.
  Result compute<Result>(RefComputer<Result> computeCallback) {
    return computeCallback(this);
  }

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
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _scopeTag = _newScopeTag;
  }

  @override
  Widget build() {
    assert(() {
      _selectionsThisBuild = <Listenable>{};
      return true;
    }());

    RefContext.current = this;
    try {
      return super.build();
    } finally {
      RefContext.current = null;
      assert(() {
        _selectionsThisBuild = null;
        return true;
      }());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Object? newTag = _newScopeTag;
    if (newTag != _scopeTag) {
      _scopeTag = newTag;
      _resetSubscriptions();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _resetSubscriptions();
  }

  void _resetSubscriptions() {
    for (final entry in _watchedListenables.entries) {
      entry.key.removeListener(entry.value);
    }
    _watchedListenables.clear();

    for (final entry in _selectedListenables.entries) {
      entry.key.removeListener(entry.value);
    }
    _selectedListenables.clear();

    _managedAnimations.forEach(registry.remove);
    _managedAnimations.clear();
  }

  @override
  void unmount() {
    _resetSubscriptions();
    _tickerMode?.removeListener(_updateTickers);
    _styleNotifier?.removeListener(_updateStyles);
    super.unmount();
  }
}
