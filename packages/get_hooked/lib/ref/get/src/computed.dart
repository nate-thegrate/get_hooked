part of '../get.dart';

/// The parameter used in a [RefComputer] callback.
abstract interface class ComputeRef {
  /// Returns the [ValueListenable.value], and triggers a re-computation when notifications
  /// are sent.
  T watch<T>(ValueListenable<T> get, {bool autoVsync = true, bool useScope = true});

  /// Returns the [selector]'s result and triggers a re-compute when that result changes.
  Result select<Result, T>(
    ValueListenable<T> get,
    Result Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  });
}

/// Soon I will turn [Ref] into a global constant that implements this interface, cause why not.
abstract interface class HookRef implements ComputeRef {
  /// TBD :)
  Result compute<Result>(RefComputer<Result> callback);
}

/// Signature for a callback that computes a result using a provided [ComputeRef].
typedef RefComputer<Result> = Result Function(ComputeRef ref);

abstract class _ComputeBase<Result> with ChangeNotifier implements ValueListenable<Result> {
  _ComputeBase(this.compute, {this.concurrent});

  ComputeRef get _ref;
  final RefComputer<Result> compute;
  Result _compute() {
    final Result result = this.compute(_ref);
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
    final Result newValue = this.compute(_ref);
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

// ignore: invalid_internal_annotation, my preference :)
@internal
class ComputedNoScope<Result> extends _ComputeBase<Result>
    implements ComputeRef, VsyncValue<Result> {
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
    if (vsync != Vsync.fallback) _animations?.forEach(vsync.registry.add);
  }

  Set<VsyncRef>? _animations;
  void _autoVsync(Listenable listenable) {
    if (listenable is! VsyncRef) return;
    (_animations ??= {}).add(listenable);

    if (_vsync != Vsync.fallback) _vsync.registry.add(listenable);
  }

  @override
  ComputeRef get _ref => this;

  bool _firstCompute = true;
  @override
  Result _compute() {
    final Result result = super._compute();
    _firstCompute = false;
    return result;
  }

  @override
  final Set<ValueRef> _dependencies = {};

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

/// A computed notifier that lives in a [GetScope].
class ComputedScoped<Result> extends _ComputeBase<Result> implements ComputeRef {
  /// Initializes superclass fields.
  ComputedScoped(super.compute, {super.concurrent});

  /// The scope's full notifier map.
  Map<ValueRef, ValueRef> get fullDependencyMap => _fullDependencyMap;
  var _fullDependencyMap = <ValueRef, ValueRef>{};
  set fullDependencyMap(Map<ValueRef, ValueRef> value) {
    assert(!identical(value, _dependencyMap));
    if (mapEquals(value, _fullDependencyMap)) return;

    _fullDependencyMap = value;
    dependencyMap = {for (final key in _dependencyMap.keys) key: _fullDependencyMap[key] ?? key};
  }

  /// The [ValueRef] objects that this notifier depends on.
  Map<ValueRef, ValueRef> get dependencyMap => _dependencyMap;
  var _dependencyMap = <ValueRef, ValueRef>{};
  set dependencyMap(Map<ValueRef, ValueRef> value) {
    assert(!identical(value, _dependencyMap));
    if (mapEquals(value, _dependencyMap)) return;

    _listenable.removeListener(_scheduleUpdate);
    _dependencyMap = value;
    _listenable.addListener(_scheduleUpdate);
    _scheduleUpdate();
  }

  @override
  Iterable<Listenable> get _dependencies => _dependencyMap.values;

  @override
  ComputeRef get _ref => this;

  G _read<G extends ValueRef>(G get, {bool autoVsync = true, bool useScope = true}) {
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
