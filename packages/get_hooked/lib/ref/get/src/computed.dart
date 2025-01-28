// ignore_for_file: public_member_api_docs, pro crastinate!

part of '../get.dart';

abstract interface class ComputeRef {
  T watch<T>(GetT<T> get, {bool autoVsync = true, bool useScope = true});

  G read<G extends GetAny>(G get, {bool autoVsync = true, bool useScope = true});

  Result select<Result, T>(
    GetT<T> get,
    Result Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  });
}

extension VsyncRef on ComputeRef {
  G vsync<G extends GetAny>(G get, {bool useScope = true}) => read(get, useScope: useScope);
}

abstract interface class HookRef implements ComputeRef {
  Result compute<Result>(RefComputer<Result> callback);
}

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
class ComputedNoScope<Result> extends _ComputeBase<Result> implements ComputeRef {
  ComputedNoScope(super.compute, {super.concurrent});

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
  G read<G extends GetAny>(G get, {bool autoVsync = true, bool useScope = false}) => get;

  @override
  T watch<T>(GetT<T> get, {bool autoVsync = true, bool useScope = false}) {
    if (_firstCompute) _dependencies.add(get.hooked);
    return get.value;
  }

  @override
  R select<R, T>(
    GetT<T> get,
    R Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = false,
  }) {
    if (_firstCompute) {
      final ValueListenable<T> valueListenable = get.hooked;
      _dependencies.add(ProxyNotifier(valueListenable, (v) => selector(v.value)));
    }
    return selector(get.value);
  }
}

class ComputedScoped<Result> extends _ComputeBase<Result> implements ComputeRef {
  ComputedScoped(super.compute, {super.concurrent});

  Map<ValueRef, ValueRef> get fullDependencyMap => _fullDependencyMap;
  var _fullDependencyMap = <ValueRef, ValueRef>{};
  set fullDependencyMap(Map<ValueRef, ValueRef> value) {
    assert(!identical(value, _dependencyMap));
    if (mapEquals(value, _fullDependencyMap)) return;

    _fullDependencyMap = value;
    dependencyMap = {for (final key in _dependencyMap.keys) key: _fullDependencyMap[key] ?? key};
  }

  Map<ValueRef, ValueRef> get dependencyMap => _dependencyMap;
  var _dependencyMap = <ValueRef, ValueRef>{};
  set dependencyMap(Map<ValueRef, ValueRef> value) {
    assert(!identical(value, _dependencyMap));
    if (mapEquals(value, _dependencyMap)) return;

    _listenable.removeListener(_scheduleUpdate);
    _dependencyMap = value;
    _listenable.addListener(_scheduleUpdate..call());
  }

  @override
  Iterable<Listenable> get _dependencies => _dependencyMap.values;

  @override
  ComputeRef get _ref => this;

  @override
  G read<G extends GetAny>(G get, {bool autoVsync = true, bool useScope = true}) {
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
    GetT<T> get,
    R Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    final GetT<T> g = read(get);
    return selector(g.value);
  }

  @override
  T watch<T>(GetT<T> get, {bool autoVsync = true, bool useScope = true}) {
    final GetT<T> g = read(get);
    return g.value;
  }
}
