// ignore_for_file: public_member_api_docs, pro crastinate!

part of '../get.dart';

abstract interface class ComputeRef {
  T watch<T>(GetT<T> get, {bool useScope});

  G read<G extends GetAny>(G get, {bool useScope});
}

typedef RefComputer<Result> = Result Function(ComputeRef ref);

abstract class _ComputeBase<Result> with ChangeNotifier implements ValueListenable<Result> {
  _ComputeBase(this.compute, {required Set<Listenable> dependencies, this.concurrent})
    : _dependencies = dependencies;

  ComputeRef get _ref;
  final RefComputer<Result> compute;
  Result _compute() {
    final Result result = this.compute(_ref);
    assert(() {
      if (this is! Future) return true;
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

  final Set<Listenable> _dependencies;
  late final _listenable = Listenable.merge(_dependencies);

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
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

abstract class ComputedNotifier<Result> implements ComputeRef, ValueListenable<Result> {
  factory ComputedNotifier(RefComputer<Result> compute, {bool? concurrent}) =
      ComputedNoScope<Result>;

  Result resultOf(BuildContext context);

  void didChangeDependencies(BuildContext context, VoidCallback listener);
}

// ignore: invalid_internal_annotation, my preference :)
@internal
class ComputedNoScope<Result> extends _ComputeBase<Result> implements ComputedNotifier<Result> {
  ComputedNoScope(super.compute, {super.concurrent}) : super(dependencies: {});

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
  Result resultOf(BuildContext context) => _value;

  @override
  G read<G extends GetAny>(G get, {bool useScope = false}) => get;

  @override
  T watch<T>(GetT<T> get, {bool useScope = false}) {
    if (_firstCompute) _dependencies.add(get.hooked);
    return get.value;
  }

  @override
  void didChangeDependencies(BuildContext context, VoidCallback listener) {}
}

class _ComputedScopedMember<Result> extends _ComputeBase<Result> {
  _ComputedScopedMember(this._ref, {required super.dependencies})
    : super(_ref.compute, concurrent: _ref.concurrent);

  @override
  final ComputedScoped<Result> _ref;

  @override
  bool get hasListeners => super.hasListeners;
}

// ignore: invalid_internal_annotation, my preference :)
@internal
class ComputedScoped<Result> implements ComputedNotifier<Result> {
  ComputedScoped(this.compute, {this.concurrent});

  final RefComputer<Result> compute;

  final bool? concurrent;

  BuildContext? _context;

  final bool _collectedDependencies = false;
  final _dependencies = <GetAny>{};

  final _expando = Expando<Set<ValueRef>>();
  final _notifiers = HashMap<Set<ValueRef>, _ComputedScopedMember<Result>>(
    equals: setEquals<ValueRef>,
    hashCode: const SetEquality<ValueRef>().hash,
  );

  Result _compute() {
    final Result result = this.compute(this);
    assert(() {
      if (this is! Future) return true;
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
  Result resultOf(BuildContext context) {
    final BuildContext? oldContext = _context;
    _context = context;
    final Result result = value;
    _context = oldContext;
    return result;
  }

  _ComputedScopedMember<Result> get _notifier {
    Result? result;
    Set<ValueRef> scopedRefs;
    final Object expandoKey = _context ?? this;
    if (!_collectedDependencies) result = _compute();

    if (_expando[expandoKey] case final refs?) {
      scopedRefs = refs;
    } else {
      if (_context case final context?) {
        scopedRefs = {for (final get in _dependencies) GetScope.of(context, get).hooked};
      } else if (_dependencies case final Set<ValueRef> valueRefs) {
        scopedRefs = valueRefs;
      }
      _expando[expandoKey] = scopedRefs;
    }

    return _notifiers[scopedRefs] ??= _ComputedScopedMember<Result>(
      this,
      dependencies: scopedRefs,
    ).._value = result ?? _compute();
  }

  @override
  G read<G extends GetAny>(G get, {bool useScope = true}) => switch (_context) {
    final BuildContext context? when useScope => GetScope.of(context, get),
    _ => get,
  };

  @override
  T watch<T>(GetT<T> get, {bool useScope = true}) {
    if (!_collectedDependencies) {
      _dependencies.add(get);
    }
    return read(get, useScope: useScope).value;
  }

  @override
  void addListener(VoidCallback listener, {BuildContext? context}) {
    final BuildContext? oldContext = _context;
    _context = context;
    _notifier.addListener(listener);
    _context = oldContext;
  }

  @override
  void didChangeDependencies(BuildContext context, VoidCallback listener) {
    final BuildContext? oldContext = _context;
    _context = context;

    final Set<ValueRef>? oldRefs = _expando[context];
    if (oldRefs == null) {
      assert(oopsie('A "scoped computed notifier" is missing its scoped dependencies.', context));
      return;
    }
    final _ComputedScopedMember<Result>? notifier = _notifiers[oldRefs];
    if (notifier == null) {
      assert(
        oopsie(
          'A "scoped computed notifier" is missing '
          'its inner "single scoped computed notifier".',
          context,
        ),
      );
      return;
    }
    final Set<ValueRef> newScopedRefs = {
      for (final get in _dependencies) GetScope.of(context, get).hooked,
    };
    if (!setEquals(oldRefs, newScopedRefs)) {
      notifier.removeListener(listener);
      final _ComputedScopedMember<Result> newNotifier =
          this._notifiers[newScopedRefs] ??= _ComputedScopedMember<Result>(
            this,
            dependencies: newScopedRefs,
          );

      final Result newValue = newNotifier.value;
      newNotifier.addListener(listener);
      if (newValue != notifier.value) {
        listener();
      }
    }

    _context = oldContext;
  }

  @override
  void removeListener(VoidCallback listener, {BuildContext? context}) {
    final BuildContext? oldContext = _context;
    _context = context;
    final _ComputedScopedMember<Result> notifier = _notifier..removeListener(listener);
    if (!notifier.hasListeners) {
      _notifiers.remove(notifier._dependencies);
    }
    _context = oldContext;
  }

  @override
  Result get value => _notifier.value;

  static Never oopsie(String summary, [BuildContext? context]) {
    assert(
      throw FlutterError.fromParts([
        ErrorSummary(summary),
        if (context != null) ...[
          ErrorDescription('This error was encountered within the following widget:'),
          context.widget.toDiagnosticsNode(style: DiagnosticsTreeStyle.error),
        ],
        ErrorDescription(
          'With how convoluted a scoped computed notifier is, '
          'this is most likely a bug in the get_hooked package.',
        ),
        ErrorHint(
          'Consider filing a bug report at '
          'https://github.com/nate-thegrate/get_hooked/issues',
        ),
        ErrorHint(
          '(If you have a code sample that can reliably reproduce the error, '
          "that'd be amazing.)",
        ),
      ]),
    );
    throw Error();
  }
}
