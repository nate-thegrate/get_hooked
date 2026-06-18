part of '../substitution.dart';

/// Allows accessing the relevant value from an ancestor [GetScope] in a reasonably
/// concise manner.
extension GetScopeRead on BuildContext {
  /// Returns the [ValueListenable] object relevant to the provided `placeholder`.
  ///
  /// If no such object is found, the placeholder is returned.
  V read<V extends ValueListenable<Object?>>(V placeholder) {
    return GetScope.of<V>(this, placeholder, createDependency: false);
  }
}

/// Allows [Substitution]s for [ValueListenable] objects.
///
/// [ref] methods will point to the objects specified in the substitutes
/// by default.
///
/// {@tool snippet}
///
/// In the following example, when the `child` widget (or its descendants)
/// calls `ref.watch(objectA)` or `ref.watch(objectB)`, it will be subscribed to
/// a different object, as defined by the [Substitution].
///
/// ```dart
/// Widget build(BuildContext context) {
///   // ...
///
///   return GetScope(
///     substitutes: {
///       Substitution(objectA, _objectA),
///       Substitution.factory(objectB, ValueNotifier<String>.new),
///     },
///     child: widget.child,
///   );
/// }
/// ```
///
/// {@end-tool}
class GetScope extends StatefulWidget {
  /// Enables [Ref.watch] calls to point to new values,
  /// as specified by the [substitutes].
  const GetScope({
    super.key,
    this.substitutes = const {},
    this.inherit = true,
    required this.child,
  });

  /// An iterable (typically a [Set]) that points [Get] objects to new values.
  final Iterable<Substitution<Object?>> substitutes;

  /// The widget below this one in the tree.
  final Widget child;

  /// Whether this [GetScope] should also include substitutes from an ancestor scope,
  /// if applicable.
  ///
  /// Ancestor substitutes are ignored if the same value is substituted in this scope.
  final bool inherit;

  /// Returns `true` or `false` depending on whether the provided `context`
  /// has a [GetScope] widget as its ancestor.
  static bool hasScope(BuildContext context) {
    return context.getInheritedWidgetOfExactType<SubstitutionModel>() != null;
  }

  /// If the [Get] object is overridden in an ancestor [GetScope], returns that object.
  ///
  /// Returns `null` otherwise.
  static T? maybeOf<T extends ValueListenable<Object?>>(
    BuildContext context,
    T placeholder, {
    bool? createDependency,
  }) {
    createDependency ??= WidgetsBinding.instance.building;
    final SubstitutionModel? model = createDependency
        ? context.dependOnInheritedWidgetOfExactType()
        : context.getInheritedWidgetOfExactType();

    late final _GetScopeState? scopeState = context.findAncestorStateOfType<_GetScopeState>();
    if (placeholder is ComputedNotifier || placeholder is ProxyNotifier) {
      if (model == null || scopeState == null) return null;

      final SubMap<_V> computers = scopeState.computers;
      if (computers.containsKey(placeholder)) return computers.get(placeholder);

      final Listenable result = switch (placeholder) {
        final ComputedNotifier<Object?> computed => computed.scopeWith(
          model.map,
          scopeState.context,
        ),
        final ProxyNotifier<Object?, Object?> selector => selector.proxyWith(
          of(context, selector.input),
        ),
        _ => throw StateError('Placeholder is a ${placeholder.runtimeType}'),
      };

      return computers[placeholder] = result as T;
    }

    if (kDebugMode) {
      final Object? scoped = model?.map[placeholder];
      if (scoped is! T?) {
        throw FlutterError.fromParts([
          ErrorSummary('An invalid substitution was made for a $T.'),
          ErrorDescription(
            'A ${placeholder.runtimeType} was substituted with a ${scoped.runtimeType}.',
          ),
          if (Substitution.debugSubWidget(context, placeholder) case final widget?) ...[
            ErrorDescription('The invalid substitution was made by the following widget:'),
            widget.toDiagnosticsNode(style: DiagnosticsTreeStyle.error),
          ],
        ]);
      }
    }

    return model?.map.maybeGet(placeholder);
  }

  /// Returns the [Get] object that overrides this one.
  ///
  /// If no such object is found, returns the object provided as input.
  ///
  /// If `createDependency` is true, the context will be notified to rebuild
  /// when a [Substitution] is made for the placeholder
  /// (it does not subscribe to the listenable itself).
  ///
  /// See also:
  ///
  /// * [GetScope.maybeOf], which returns `null` if the relevant [Substitution]
  ///   is not found in the ancestor [GetScope].
  static T of<T extends ValueListenable<Object?>>(
    BuildContext context,
    T placeholder, {
    bool? createDependency,
  }) {
    return maybeOf(context, placeholder, createDependency: createDependency) ?? placeholder;
  }

  @override
  StatefulElement createElement() => _VsyncStatefulElement(this);

  @override
  State<GetScope> createState() => _GetScopeState();
}

extension<T> on Iterable<Substitution<T>> {
  bool debugCheckDuplicates([BuildContext? context]) {
    final refs = <Object>{};
    for (final Substitution(placeholder: ref) in this) {
      if (refs.add(ref)) continue;
      throw FlutterError.fromParts([
        ErrorSummary('Duplicate overrides found for the same Get object.'),
        for (final sub in this)
          if (sub.placeholder == ref) sub.toDiagnosticsNode(),
        ErrorDescription(
          'A Get object representing a ${ref.runtimeType} '
          'was assigned multiple overrides in this collection.',
        ),
        if (context != null) ...[
          ErrorDescription('These overrides were added by the following widget:'),
          context.widget.toDiagnosticsNode(),
        ],
      ]);
    }
    return true;
  }

  Substitution<T>? maybeLocate(Object? ref) {
    for (final sub in this) {
      if (sub.placeholder == ref) return sub;
    }
    return null;
  }

  Substitution<T> locate(Object? ref) => maybeLocate(ref)!;
}

extension on Object {
  void dispose() => switch (this) {
    DisposeGuard() => null,
    final ChangeNotifier changeNotifier => changeNotifier.dispose(),
    final AnimationController controller => controller.dispose(),
    _ => null,
  };
}

class _VsyncStatefulElement = StatefulElement with ElementVsync;

class _GetScopeState extends State<GetScope> {
  late Iterable<Substitution<Object?>> widgetSubs = widget.substitutes;
  late final widgetMap = <_V, _V>{
    for (final substitute in widgetSubs) substitute.placeholder: substitute.replacement,
  };

  @override
  late final VsyncContext context = super.context as VsyncContext;
  late final registry = context.registry;

  @override
  void initState() {
    super.initState();
    assert(widgetSubs.debugCheckDuplicates(context));
  }

  late final VoidCallback rebuild = (context as Element).markNeedsBuild;
  late final clientSubstitutes = MapNotifier(<Element, SubMap<_V>>{})..addListener(rebuild);
  late final computers = SubMap<_V>();

  @override
  void didUpdateWidget(GetScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Iterable<Substitution<Object?>> newSubs = widget.substitutes;
    assert(newSubs.debugCheckDuplicates(context));

    for (final Object ref in widgetMap.keys) {
      if (newSubs.maybeLocate(ref) == null) {
        final Object? oldReplacement = widgetMap.remove(ref);
        final Substitution<Object?> oldSub = widgetSubs.locate(ref);
        if (oldSub.autoDispose) oldReplacement?.dispose();
      }
    }

    for (final newSub in newSubs) {
      if (widgetMap[newSub.placeholder] case final oldReplacement?) {
        final Substitution<Object?> oldSub = widgetSubs.locate(newSub.placeholder);
        if ((oldSub, newSub) case (
          _SubFactory(:final factory),
          _SubFactory(factory: final newFactory),
        ) when factory == newFactory) {
          continue;
        }
        final _V newReplacement = newSub.replacement;
        if (newReplacement != oldReplacement) {
          widgetMap[newSub.placeholder] = newReplacement;
          if (oldSub.autoDispose) oldReplacement.dispose();
        }
      }
    }
  }

  @override
  void dispose() {
    clientSubstitutes.removeListener(rebuild);
    super.dispose();
  }

  Object tag = Object();
  SubMap<_V>? _map;

  @override
  Widget build(BuildContext context) {
    final map = SubMap<_V>();

    for (final Map<_V, _V> refMap in clientSubstitutes.values.toList().reversed) {
      for (final MapEntry(:key, :value) in refMap.entries) {
        map[key] ??= value;
      }
    }
    for (final MapEntry(:key, :value) in widgetMap.entries) {
      map[key] ??= value;
    }
    if (widget.inherit) {
      if (context.dependOnInheritedWidgetOfExactType<SubstitutionModel>() case final model?) {
        for (final MapEntry(:key, :value) in model.map.entries) {
          map[key] ??= value;
        }
      }
    }

    for (final Object value in map.values) {
      if (value is VsyncValue<Object?>) registry.add(value);
    }

    if (_map case final oldMap? when !mapEquals(map, oldMap)) tag = Object();

    return SubstitutionModel(map: _map = map, equalityTag: tag, child: widget.child);
  }
}

/// An [InheritedModel] used by [ref] to store its [Substitution]s
/// and notify dependent widgets.
///
/// [ref] contains methods which can be used in [Hook] functions
/// along with ___ render object stuff.
final class SubstitutionModel extends InheritedModel<_V> {
  /// Creates an [InheritedModel] that stores substitution data.
  const SubstitutionModel({
    super.key,
    required this.map,
    required this.equalityTag,
    required super.child,
  });

  /// The substitution map.
  ///
  /// The key is the original object; the value is the new object.
  final SubMap<ValueListenable<Object?>> map;

  /// Rather than calling [mapEquals] multiple times, the identity of this tag
  /// will change each time the model's map changes.
  ///
  /// This also helps clients determine how much work to perform,
  /// since a [GetScope] change might need a more thorough reset than a different dependency.
  final Object equalityTag;

  @override
  bool updateShouldNotify(SubstitutionModel oldWidget) => equalityTag != oldWidget.equalityTag;

  @override
  bool updateShouldNotifyDependent(
    SubstitutionModel oldWidget,
    Set<ValueListenable<Object?>> dependencies,
  ) {
    for (final _V dependency in dependencies) {
      if (map.maybeGet(dependency) != oldWidget.map.maybeGet(dependency)) return true;
    }
    return false;
  }
}
