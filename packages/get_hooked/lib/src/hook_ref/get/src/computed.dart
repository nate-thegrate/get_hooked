part of '../get.dart';

abstract class _ComputeBase<Result> with ChangeNotifier implements Ref, ValueListenable<Result> {
  _ComputeBase(this.compute, {this.concurrent});

  final RefComputer<Result> compute;
  Result _compute() {
    final Result result = this.compute(this);
    assert(() {
      if (result is! Future) return true;
      throw FlutterError.fromParts([
        ErrorSummary('A computed notifier returned a Future.'),
        ErrorDescription('Computed notifier callbacks should always be synchronous.'),
        ErrorHint(
          'Consider removing the `async` from the callback and/or '
          "double-checking whether the function's return value is a Future.",
        ),
      ]);
    }());

    return result;
  }

  @override
  Result get value => _value;
  late Result _value = _compute();

  final bool? concurrent;
  bool _updateInProgress = false;
  void _scheduleUpdate() {
    if (_updateInProgress) return;
    if (concurrent ?? SchedulerBinding.instance.building) {
      return _performUpdate();
    }
    _updateInProgress = true;
    Future.microtask(_performUpdate);
  }

  void _performUpdate() {
    _updateInProgress = false;
    final Result newValue = this.compute(this);
    if (_value == newValue) return;

    _value = newValue;
    notifyListeners();
  }

  abstract final Iterable<Listenable> _dependencies;
  Listenable get _listenable => Listenable.merge(_dependencies);

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      _value; // ignore: unnecessary_statements, resolves `late` value
      _listenable.addListener(_scheduleUpdate);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _listenable.removeListener(_scheduleUpdate);
    }
  }
}

typedef _Animation = VsyncValue<Object?>;

// ignore: invalid_internal_annotation, my preference :)
@internal
class ComputedNoScope<Result> extends _ComputeBase<Result> implements VsyncValue<Result> {
  /// If a vsync is specified, it will sync animations referenced via [watch] or [select].
  ComputedNoScope(super.compute, {super.concurrent, Vsync vsync = Vsync.fallback})
    : _vsync = vsync;

  @override
  Vsync get vsync => _vsync;
  Vsync _vsync;

  @override
  void resync(Vsync vsync) {
    if (vsync == _vsync) return;
    if (_vsync != Vsync.fallback) _animations?.forEach(_vsync.registry.remove);
    _vsync = vsync;
    if (vsync != Vsync.fallback) _animations?.forEach(_vsync.registry.add);
  }

  Set<_Animation>? _animations;
  void _autoVsync(Listenable listenable) {
    if (listenable is! _Animation) return;
    (_animations ??= {}).add(listenable);

    if (_vsync != Vsync.fallback) _vsync.registry.add(listenable);
  }

  bool _firstCompute = true;
  @override
  Result _compute() {
    final Result result = super._compute();
    _firstCompute = false;
    return result;
  }

  @override
  final Set<Listenable> _dependencies = {};

  @override
  T watch<T>(ValueListenable<T> get, {bool autoVsync = true, bool useScope = false}) {
    if (_firstCompute) {
      _dependencies.add(get);
      if (autoVsync) _autoVsync(get);
    }
    return get.value;
  }

  @override
  R select<R, T>(
    ValueListenable<T> get,
    R Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = false,
  }) {
    if (_firstCompute) {
      _dependencies.add(ProxyNotifier(get, (v) => selector(v.value)));
      if (autoVsync) _autoVsync(get);
    }
    return selector(get.value);
  }
}

/// A computed notifier that lives in a [SubScope].
class ComputedScoped<Result> extends _ComputeBase<Result> {
  /// Initializes superclass fields.
  ComputedScoped(super.compute, {super.concurrent});

  /// The scope's full notifier map.
  SubMap<ValueListenable<Object?>> get fullDependencyMap => _fullDependencyMap;
  var _fullDependencyMap = SubMap<_V>();
  set fullDependencyMap(SubMap<ValueListenable<Object?>> value) {
    assert(!identical(value, _dependencyMap));
    if (mapEquals(value, _fullDependencyMap)) return;

    _fullDependencyMap = SubMap(value);
    dependencyMap = SubMap({
      for (final key in _dependencyMap.keys) key: _fullDependencyMap[key] ?? key,
    });
  }

  /// The [ValueListenable] objects that this notifier depends on.
  SubMap<ValueListenable<Object?>> get dependencyMap => _dependencyMap;
  var _dependencyMap = SubMap<_V>();
  set dependencyMap(SubMap<ValueListenable<Object?>> value) {
    assert(!identical(value, _dependencyMap));
    if (mapEquals(value, _dependencyMap)) return;

    _listenable.removeListener(_scheduleUpdate);
    _dependencyMap = value;
    _listenable.addListener(_scheduleUpdate);
    _scheduleUpdate();
  }

  @override
  Iterable<Listenable> get _dependencies => _dependencyMap.values;

  G _read<G extends _V>(G get, {bool autoVsync = true, bool useScope = true}) {
    switch (_dependencyMap[get]) {
      case null:
      case _ when !useScope:
        break;
      case final G g:
        return g;
      default:
        assert(
          throw FlutterError.fromParts([
            ErrorSummary('Invalid substitution found in a "computed" callback.'),
            ErrorDescription('Original object: $get'),
            ErrorDescription('Substituted with: ${_dependencyMap[get]}'),
            ErrorHint('Consider changing or removing this substitution.'),
          ]),
        );
    }
    return get;
  }

  @override
  R select<R, T>(
    ValueListenable<T> get,
    R Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    final ValueListenable<T> g = _read(get);
    return selector(g.value);
  }

  @override
  T watch<T>(ValueListenable<T> get, {bool autoVsync = true, bool useScope = true}) {
    final ValueListenable<T> g = _read(get);
    return g.value;
  }
}
