// ignore_for_file: invalid_use_of_visible_for_testing_member, these hooks are meant to access internal stuff :)
// ignore_for_file: avoid_positional_boolean_parameters, private hook functions are more readable this way

part of '../ref.dart';

T _selectAll<T>(T value) => value;

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

class _VsyncHook extends Hook<void, GetVsyncAny> {
  late GetVsyncAny get = data;
  late Vsync vsync = get.vsync;

  @override
  void initHook() => vsync.context = context;

  @override
  void didUpdate(GetVsyncAny oldData) {
    final GetVsyncAny newGet = data;

    if (newGet != get) {
      dispose();
      get = newGet;
      vsync = get.vsync;
      initHook();
    }
  }

  @override
  void activate() => vsync.ticker?.updateNotifier(context);

  @override
  void dispose() {
    if (vsync.context == context) vsync.context = null;
  }

  @override
  void build() {}
}

class _RefComputerHook<Result> extends Hook<Result, RefComputer<Result>> implements ComputeRef {
  bool _needsDependencies = true;
  final _rootDependencies = <GetAny>{};
  final _scopedDependencies = <Listenable>{};
  late final _listenable = Listenable.merge(_scopedDependencies);
  late Result _result;
  bool _computed = false;
  bool _dirty = false;

  void _scheduleRecompute() {
    _dirty = true;
    markMayNeedRebuild();
  }

  Result compute() => data(this);

  @override
  bool shouldRebuild() {
    final Result newResult = compute();
    final bool changed = newResult != _result;
    _result = newResult;
    _computed = true;
    return changed;
  }

  @override
  void initHook() {
    _result = compute();
    _needsDependencies = false;
    _listenable.addListener(_scheduleRecompute);
  }

  @override
  T watch<T>(GetT<T> get, {bool useScope = true}) {
    final GetT<T> scoped = read(get, useScope: useScope);
    if (_needsDependencies) {
      _rootDependencies.add(get);
      _scopedDependencies.add(scoped.hooked);
    }
    return scoped.value;
  }

  @override
  G read<G extends GetAny>(G get, {bool useScope = true}) {
    return useScope ? GetScope.of(context, get) : get;
  }

  @override
  void didChangeDependencies() {
    final Set<Listenable> newDependencies = {
      for (final get in _rootDependencies) GetScope.of(context, get).hooked,
    };
    if (!setEquals(newDependencies, _scopedDependencies)) {
      _listenable.removeListener(_scheduleRecompute);
      _scopedDependencies
        ..clear()
        ..addAll(newDependencies);
      _listenable.addListener(_scheduleRecompute);
    }
  }

  @override
  Result build() {
    if (_computed) {
      _computed = false;
    } else if (_dirty) {
      _computed = false;
      _result = compute();
    }
    _dirty = false;
    return _result;
  }
}
