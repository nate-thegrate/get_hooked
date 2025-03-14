/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/scoped_selection.dart';
import 'package:get_hooked/src/substitution/substitution.dart';

import 'get/get.dart';
import 'hooked/hooked.dart';

export 'get/get.dart' hide ComputedNoScope;
export 'hooked/hooked.dart';

/// A [Ref] that works inside a [HookWidget.build].
///
/// A globally-scoped function can call [use] or [HookRef.watch],
/// as long as that function is only called while a hook widget is building.
const HookRef ref = HookRef._();

/// The interface implemented by the global [ref] constant.
///
/// Includes the [Ref] methods along with [compute] and [sub].
interface class HookRef implements Ref {
  const HookRef._();

  /// This hook function watches a [Get] object
  /// and triggers a rebuild when it sends a notification.
  ///
  /// {@template get_hooked.Ref.watch}
  /// Must be called inside a [HookWidget.build] method.
  ///
  /// Notifications are not sent when [watching] is `false`
  /// (changes to this value will apply the next time the [HookWidget]
  /// is built).
  ///
  /// If a [GetVsync] object is passed, this hook will check if the
  /// [Vsync] is attached to a [BuildContext] (which is typically achieved
  /// via [ref.vsync]) and throws an error if it fails. The check can be
  /// bypassed by setting [checkVsync] to `false`.
  ///
  /// By default, if an ancestor [GetScope] overrides the [Get] object's
  /// value, the new object is used instead. Setting [useScope] to `false`
  /// will ignore any overrides.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  /// * [Ref.select], which allows rebuilding only when a specified part
  ///   of the listenable's value changes.
  /// * [GetScope.of], for retrieving a [Substitution]'s new value outside of
  ///   a [HookWidget.build] method.
  @override
  T watch<T>(
    ValueListenable<T> listenable, {
    bool watching = true,
    bool autoVsync = true,
    bool useScope = true,
  }) {
    if (useScope) listenable = GetScope.of(useContext(), listenable);
    if (autoVsync) _autoVsync(listenable);
    return useValueListenable(listenable, watching: watching);
  }

  /// Selects a value from a complex [Get] object and triggers a rebuild when
  /// the selected value changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  @override
  Result select<Result, T>(
    ValueListenable<T> listenable,
    Result Function(T value) selector, {
    bool watching = true,
    bool autoVsync = true,
    bool useScope = true,
  }) {
    if (useScope) listenable = GetScope.of(useContext(), listenable);

    return HookData.use(
      _GetSelect<Result, T>(listenable, selector, watching: watching),
      debugLabel: 'Ref.select',
    );
  }

  /// Returns the provided [RefComputer]'s output and triggers a rebuild
  /// when any of the referenced values change.
  Result compute<Result>(RefComputer<Result> computeCallback) {
    return use(
      _RefComputerHook.new,
      key: null,
      data: computeCallback,
      debugLabel: 'compute<$Result>',
    );
  }

  /// Performs a substitution in the nearest ancestor [GetScope].
  ///
  /// The `replacer` object should be another [ValueListenable] object
  /// that implements the same interface as `listenable`,
  /// or a function that returns such an object (a.k.a. a [ValueGetter<ValueListenable>]).
  V sub<V extends ValueListenable<Object?>>(V listenable, Object replacer, {Object? key}) {
    return use(
      _SubHook.new,
      data: (listenable, replacer),
      key: key,
      debugLabel: 'useSubstitute<$V>',
    );
  }
}

/// An animation object is synced to an [Vsync] via the first build context
/// that uses it.
void _autoVsync(Listenable get) {
  if (get is VsyncValue<Object?>) {
    use(_VsyncHook.new, key: get, data: get, debugLabel: 'auto-vsync');
  }
}

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
typedef _StyleNotifier = ValueListenable<AnimationStyle>;
typedef _Animation = VsyncValue<Object?>;

class _VsyncHook extends Hook<void, _Animation> implements Vsync {
  Ticker? _ticker;
  StyledAnimation<Object?>? _animation;
  _StyleNotifier? _styleNotifier;
  _TickerMode? _tickerMode;

  @override
  void initHook() {
    registry.add(data);
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
    registry.remove(data);
    super.dispose();
  }

  @override
  void build() {}
}

mixin _ComputeRefVsync<Result> on Hook<Result, RefComputer<Result>> implements Vsync {
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
    with _ComputeRefVsync
    implements Ref {
  bool _needsDependencies = true;
  final _rootDependencies = <Listenable>{};
  var _scopedDependencies = <Listenable>{};
  Listenable get _listenable => Listenable.merge(_scopedDependencies);

  final _selections = <ScopedSelection<Object?, Object?>>{};

  final _rootAnimations = <_Animation>{};
  var _managedAnimations = <_Animation>{};

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

  G _read<G extends ValueListenable<Object?>>(
    G get, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    final G scoped = useScope ? SubScope.of(context, get) : get;
    if (get case final _Animation animation when _needsDependencies && autoVsync) {
      if (scoped is! _Animation) {
        assert(
          throw FlutterError.fromParts([
            ErrorSummary('An invalid substitution was made for a $G.'),
            ErrorDescription(
              'A ${get.runtimeType} was substituted with a ${scoped.runtimeType}.',
            ),
            if (Substitution.debugSubWidget(context, get) case final widget?) ...[
              ErrorDescription('The invalid substitution was made by the following widget:'),
              widget.toDiagnosticsNode(style: DiagnosticsTreeStyle.error),
            ],
          ]),
        );
        return scoped;
      }
      _rootAnimations.add(animation);
      if (animation == scoped) {
        // If a substitution was made, the GetScope acts as the ticker provider.
        // Otherwise, this hook does it.
        _managedAnimations.add(animation);
        registry.add(animation);
      }
    }
    return scoped;
  }

  @override
  T watch<T>(ValueListenable<T> get, {bool autoVsync = true, bool useScope = true}) {
    final ValueListenable<T> scoped = _read(get, useScope: useScope);
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
      _selections.add(ScopedSelection<R, T>(context, get, selector, markMayNeedRebuild));
    }
    return selector(scoped.value);
  }

  @override
  void didChangeDependencies() {
    final newDependencies = <Listenable>{
      for (final get in _rootDependencies) SubScope.of(context, get),
    };
    if (!setEquals(newDependencies, _scopedDependencies)) {
      _listenable.removeListener(markMayNeedRebuild);
      _scopedDependencies = newDependencies;
      _listenable.addListener(markMayNeedRebuild);
    }

    final animations = <_Animation>{
      for (final _Animation animation in _rootAnimations)
        if (SubScope.maybeOf(context, animation) == null) animation,
    };
    if (!setEquals(animations, _managedAnimations)) {
      _managedAnimations.difference(animations).forEach(registry.remove);
      animations.difference(_managedAnimations).forEach(registry.add);
      _managedAnimations = animations;
    }

    for (final ScopedSelection<Object?, Object?> selection in _selections) {
      selection.rescope();
    }
  }

  @override
  void dispose() {
    _listenable.removeListener(markMayNeedRebuild);
    _managedAnimations.forEach(registry.remove);
    for (final ScopedSelection<Object?, Object?> selection in _selections) {
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

class _SubHook<G extends ValueListenable<Object?>> extends Hook<G, (G, Object?)> {
  late final G newGet;

  @override
  void initHook() {
    var (G replaced, Object? replacer) = data;
    if (replacer is ValueGetter<Object?>) replacer = replacer();
    assert(() {
      if (replacer is G) return true;
      throw ArgumentError(
        'Invalid replacer passed to useSubstitute.\n'
        'The useSubstitute function expects the replacer '
        'to be an instance of $G (or an instance of the listenable it encapsulates). '
        'Instead, a ${data.runtimeType} was received.\n'
        'Consider double-checking the arguments passed to useSubstitute.',
      );
    }());
    newGet = replacer is G ? replacer : replaced;
    SubScope.add<ValueListenable<Object?>>(context, map: {replaced: newGet});
  }

  @override
  G build() => newGet;
}
