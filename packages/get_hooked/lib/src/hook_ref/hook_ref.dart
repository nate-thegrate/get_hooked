/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/scoped_selection.dart';
import 'package:get_hooked/src/substitution/substitution.dart';
import 'package:get_hooked/src/vsync_mixin.dart';

import 'get/get.dart';
import 'hooked/hooked.dart';

export 'get/get.dart';
export 'hooked/hooked.dart';

/// A [Ref] that works inside [HookWidget.build] methods.
///
/// A globally-scoped function can call [use] or any of this [ref]'s methods,
/// as long as that function is only called while a hook widget is building.
const HookRef ref = HookRef._();

/// The class declaration for the global [ref] constant.
///
/// In addition to the methods from [Ref], provides [compute] for
/// derived values that automatically rebuild when their dependencies change.
final class HookRef implements Ref {
  const HookRef._();

  /// Watches a [ValueListenable] and triggers a rebuild when it sends a notification.
  ///
  /// {@template get_hooked.HookRef.watch}
  /// Must be called inside a [HookWidget.build] method.
  ///
  /// If an ancestor [GetScope] overrides the listened object,
  /// the replacement value is used instead. Set [useScope] to `false` to
  /// bypass any active [Substitution].
  ///
  /// When [autoVsync] is `true` (the default) and the listened object is a
  /// [VsyncValue] (such as those returned by [Get.vsync] or [Get.vsyncValue]),
  /// it is automatically registered with a [Vsync] from the current context
  /// so that animations receive ticks.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  /// * [Ref.select], which allows rebuilding only when a specified part
  ///   of the listenable's value changes.
  /// * [GetScope.of], for retrieving a [Substitution]'s new value outside of
  ///   a [HookWidget.build] method.
  @override
  T watch<T>(ValueListenable<T> listenable, {bool autoVsync = true, bool useScope = true}) {
    final (scoped, value) = useContext().read(listenable, useScope: useScope);
    if (autoVsync && scoped == listenable) _autoVsync(listenable);
    useListenable(scoped);
    return value;
  }

  /// Selects a value from a [ValueListenable] and triggers a rebuild when
  /// the selected value changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.HookRef.watch}
  ///
  /// When [watching] is `false`, the selector is evaluated once but no listener
  /// is attached; the widget will not rebuild when the selected value changes.
  @override
  Result select<Result, T>(
    ValueListenable<T> listenable,
    Result Function(T value) selector, {
    bool watching = true,
    bool autoVsync = true,
    bool useScope = true,
  }) {
    final (scoped, value) = useContext().read(listenable, useScope: useScope);

    return HookData.use(
      _GetSelect<Result, T>(scoped, value, selector, watching: watching),
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
}

/// Attaches a [VsyncValue] (animation) to a [Vsync] using the first
/// [BuildContext] that watches it.
void _autoVsync(Listenable get) {
  if (get is VsyncValue<Object?>) {
    use(_VsyncHook.new, key: get, data: get, debugLabel: 'auto-vsync');
  }
}

class _GetSelect<Result, T> extends HookData<Result> {
  const _GetSelect(this.hooked, this.value, this.selector, {required this.watching})
    : super(key: hooked);

  final bool watching;

  final Listenable hooked;
  final T value;
  final Result Function(T value) selector;

  @override
  _SelectHook<Result, T> createHook() => _SelectHook();
}

class _SelectHook<Result, T> extends Hook<Result, _GetSelect<Result, T>> {
  late final Listenable listenable = data.hooked;
  late bool watching = data.watching;

  Result get result => data.selector(data.value);
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

typedef _Animation = VsyncValue<Object?>;

class _VsyncHook extends Hook<void, _Animation> with HookVsync<void, _Animation> {
  @override
  void initHook() {
    registry.add(data);
  }

  @override
  void dispose() {
    registry.remove(data);
    super.dispose();
  }

  @override
  void build() {}
}

class _RefComputerHook<Result> extends Hook<Result, RefComputer<dynamic>>
    with HookVsync<Result, RefComputer<dynamic>>
    implements Ref {
  bool _needsDependencies = true;
  final _rootDependencies = <ValueListenable<Object?>>{};
  var _scopedDependencies = <ValueListenable<Object?>>{};
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

  (ValueListenable<Object?>, T) _read<T extends Object?>(
    ValueListenable<T> listenable, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    final (scoped, value) = context.read(listenable, useScope: useScope);
    if (listenable case final _Animation animation when _needsDependencies && autoVsync) {
      if (scoped is! _Animation) {
        assert(
          throw FlutterError.fromParts([
            ErrorSummary('An invalid substitution was made for an animation.'),
            ErrorDescription(
              'A ${listenable.runtimeType} was substituted with a ${scoped.runtimeType}.',
            ),
            if (Substitution.debugSubWidget(context, listenable) case final widget?) ...[
              ErrorDescription('The invalid substitution was made by the following widget:'),
              widget.toDiagnosticsNode(style: DiagnosticsTreeStyle.error),
            ],
          ]),
        );
        return (scoped, value);
      }
      _rootAnimations.add(animation);
      if (animation == scoped) {
        // If a substitution was made, the GetScope acts as the ticker provider.
        // Otherwise, this hook does it.
        _managedAnimations.add(animation);
        registry.add(animation);
      }
    }
    return (scoped, value);
  }

  @override
  T watch<T>(ValueListenable<T> get, {bool autoVsync = true, bool useScope = true}) {
    final (scoped, value) = _read(get, useScope: useScope);
    if (_needsDependencies) {
      _rootDependencies.add(get);
      _scopedDependencies.add(scoped);
    }
    return value;
  }

  @override
  R select<R, T>(
    ValueListenable<T> get,
    R Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    final (scoped, value) = _read(get, useScope: useScope, autoVsync: autoVsync);
    if (_needsDependencies) {
      _selections.add(ScopedSelection<R, T>(context, get, selector, markMayNeedRebuild));
    }
    return selector(value);
  }

  @override
  void didChangeDependencies() {
    final newDependencies = <ValueListenable<Object?>>{
      for (final get in _rootDependencies) GetScope.of(context, get),
    };
    if (!setEquals(newDependencies, _scopedDependencies)) {
      _listenable.removeListener(markMayNeedRebuild);
      _scopedDependencies = newDependencies;
      _listenable.addListener(markMayNeedRebuild);
    }

    final animations = <_Animation>{
      for (final _Animation animation in _rootAnimations)
        if (GetScope.maybeOf(context, animation) == null) animation,
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
      selection.deactivate();
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
