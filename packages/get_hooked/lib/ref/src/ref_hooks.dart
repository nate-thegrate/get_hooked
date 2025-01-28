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

class _VsyncHook extends Hook<void, GetVsyncAny> {
  late GetVsyncAny get = data;
  late Vsync? vsync = get.maybeVsync;

  @override
  void initHook() {
    if (vsync case final vsync? when vsync.context == null) {
      vsync.context = context;
    }
  }

  @override
  void activate() {
    vsync
      ?..ticker?.updateNotifier(context)
      ..updateStyleNotifier(context);
  }

  @override
  void dispose() {
    if (vsync case final vsync? when vsync.context == context) {
      vsync.context = null;
    }
  }

  @override
  void build() {}
}

class _RefComputerHook<Result> extends Hook<Result, RefComputer<Result>> implements ComputeRef {
  bool _needsDependencies = true;
  final _rootDependencies = <GetAny>{};
  final _rootVsyncs = <GetVsyncAny>{};
  final _scopedDependencies = <Listenable>{};
  final _scopedVsyncs = <Vsync>{};
  late final _listenable = Listenable.merge(_scopedDependencies);
  late Result _result;
  bool _computed = false;
  bool _dirty = false;

  // void vsync() {
  //   assert(_needsDependencies);
  //   final Iterable<GetVsyncAny> scopedVsyncs = _rootVsyncs.map((get) => GetScope.of(context, get)).followedBy(_scopedDependencies.whereType());
  //   for (final getVsync in scopedVsyncs) {
  //     if (getVsync.maybeVsync case final vsync? when vsync.context == null) {
  //       _scopedVsyncs.add(vsync..context = context);
  //     }
  //   }
  // }

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
  G read<G extends GetAny>(G get, {bool autoVsync = true, bool useScope = true}) {
    final G scoped = useScope ? GetScope.of(context, get) : get;
    if (_needsDependencies && autoVsync && get is GetVsyncAny) {
      if (scoped is! GetVsyncAny) {
        assert(() {
          // An invalid substitution was made, so throw the FlutterError from GetScope.
          GetScope.of<GetVsyncAny>(context, get);
          throw StateError(
            'That GetScope.of(context) method should have thrown an error.\n'
            "If somehow you've managed to trigger this message, that's wild! "
            '$bugReport',
          );
        }());
        return scoped;
      }
      _rootVsyncs.add(get);
      if (scoped.maybeVsync case final vsync?
          when vsync.context == null || vsync.context == context) {
        _scopedVsyncs.add(vsync);
      }
    }
    return scoped;
  }

  @override
  T watch<T>(GetT<T> get, {bool autoVsync = true, bool useScope = true}) {
    final GetT<T> scoped = read(get, useScope: useScope);
    if (_needsDependencies) {
      _rootDependencies.add(get);
      _scopedDependencies.add(scoped.hooked);
    }
    return scoped.value;
  }

  @override
  R select<R, T>(
    GetT<T> get,
    R Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    final GetT<T> scoped = read(get, useScope: useScope);
    if (_needsDependencies) {
      final GetProxy<R, GetT<T>> rootProxy, scopedProxy;
      rootProxy = Get.proxy(get, (g) => selector(g.value));
      scopedProxy = get == scoped ? rootProxy : Get.proxy(scoped, (s) => selector(s.value));

      _rootDependencies.add(rootProxy);
      _scopedDependencies.add(scopedProxy);
    }
    return selector(scoped.value);
  }

  @override
  void didChangeDependencies() {
    final newDependencies = <Listenable>{
      for (final get in _rootDependencies) GetScope.of(context, get).hooked,
    };
    if (!setEquals(newDependencies, _scopedDependencies)) {
      _listenable.removeListener(_scheduleRecompute);
      _scopedDependencies
        ..clear()
        ..addAll(newDependencies);
      _listenable.addListener(_scheduleRecompute);
    }

    final newVsyncs = <Vsync>{
      for (final getVsync in _rootVsyncs)
        if (GetScope.of(context, getVsync).maybeVsync case final vsync?) vsync,
    };
    if (!setEquals(newVsyncs, _scopedVsyncs)) {
      for (final Vsync vsync in _scopedVsyncs.difference(newVsyncs)) {
        if (vsync.context == context) vsync.context = null;
      }
      for (final Vsync vsync in newVsyncs.difference(_scopedVsyncs)) {
        assert(
          vsync.context != context,
          'Somehow a Vsync is already registered to this context. $bugReport',
        );
        vsync.context ??= context;
      }
    }
  }

  @override
  void dispose() {
    for (final Vsync vsync in _scopedVsyncs) {
      if (vsync.context == context) vsync.context = null;
    }
    _listenable.removeListener(_scheduleRecompute);
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
