part of '../ref.dart';

/// Allows accessing the relevant value from an ancestor [GetScope] in a reasonably
/// concise manner.
extension GetFromContext on BuildContext {
  /// Allows accessing the relevant value from an ancestor [GetScope] in a reasonably
  /// concise manner.
  V get<V extends ValueListenable<Object?>>(
    V get, {
    bool createDependency = true,
    bool throwIfMissing = false,
  }) {
    return GetScope.of(
      this,
      get,
      createDependency: createDependency,
      throwIfMissing: throwIfMissing,
    );
  }
}

/// A widget that allows setting [Substitution]s for [Get] objects.
///
/// [Ref] static methods will point to the objects specified in the [substitutes]
/// by default.
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
  final Iterable<SubAny> substitutes;

  /// The widget below this one in the tree.
  final Widget child;

  /// Whether this [GetScope] should also include substitutes from an ancestor scope,
  /// if applicable.
  ///
  /// Ancestor substitutes are ignored if the same value is substituted in this scope.
  final bool inherit;

  /// If the [Get] object is overridden in an ancestor [Ref], returns that object.
  ///
  /// Returns `null` otherwise.
  static G? maybeOf<G extends ValueRef>(
    BuildContext context,
    G get, {
    bool createDependency = true,
  }) {
    final ScopeModel? model =
        createDependency
            ? context.dependOnInheritedWidgetOfExactType()
            : context.getInheritedWidgetOfExactType();

    assert(() {
      final ValueRef? scoped = model?.map[get];
      if (scoped is G?) return true;

      throw FlutterError.fromParts([
        ErrorSummary('An invalid substitution was made for a $G.'),
        ErrorDescription('A ${get.runtimeType} was substituted with a ${scoped.runtimeType}.'),
        if (Ref(get).debugSubWidget(context) case final widget?) ...[
          ErrorDescription('The invalid substitution was made by the following widget:'),
          widget.toDiagnosticsNode(style: DiagnosticsTreeStyle.error),
        ],
      ]);
    }());

    return model?._select(get);
  }

  /// Returns the [Get] object that overrides this one.
  ///
  /// If no such object is found, returns the object provided as input,
  /// or throws an error if [throwIfMissing] is true.
  ///
  /// See also:
  ///
  /// * [GetScope.maybeOf], which returns `null` if the relevant [Override]
  ///   is not found in the ancestor [Ref].
  static G of<G extends ValueRef>(
    BuildContext context,
    G get, {
    bool createDependency = true,
    bool throwIfMissing = false,
  }) {
    assert(() {
      if (!throwIfMissing || maybeOf(context, get) != null) return true;

      final GetScope? ancestor = context.getInheritedWidgetOfExactType();
      throw FlutterError.fromParts([
        if (ancestor == null)
          ErrorSummary('No ancestor Ref found.')
        else
          ErrorSummary('The $G was not found in the ancestor Ref.'),
        ErrorHint(
          'Double-check that the provided context contains an ancestor Ref '
          'with the appropriate Override.',
        ),
      ]);
    }());
    return maybeOf(context, get, createDependency: createDependency) ?? get;
  }

  /// Adds more substitutions to the existing ancestor [GetScope].
  ///
  /// These substitutes are automatically removed when the associated [BuildContext]
  /// is unmounted.
  static void add(
    BuildContext context, {
    Map<ValueRef, ValueRef> listenables = const {},
    bool throwIfMissing = true,
  }) {
    final _OverrideContainer? container = context.dependOnInheritedWidgetOfExactType(
      aspect: listenables,
    );

    assert(() {
      if (container == null && throwIfMissing) {
        throw FlutterError.fromParts([
          ErrorSummary('Ancestor GetScope not found.'),
          ErrorDescription(
            'GetScope.add() was called using a BuildContext '
            'that was unable to locate an ancestor GetScope.',
          ),
          ErrorDescription('The widget that attempted this call was:'),
          context.widget.toDiagnosticsNode(),
        ]);
      }
      return true;
    }());
  }

  @override
  State<GetScope> createState() => _GetScopeState();
}

extension on Iterable<SubAny> {
  bool debugCheckDuplicates([BuildContext? context]) {
    final refs = <ValueRef>{};
    assert(debugCheckDuplicates(context));
    for (final SubAny(:ref) in this) {
      if (refs.add(ref)) continue;
      throw FlutterError.fromParts([
        ErrorSummary('Duplicate overrides found for the same Get object.'),
        for (final sub in this)
          if (sub.ref == ref) sub.toDiagnosticsNode(),
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

  SubAny? maybeLocate(ValueRef ref) {
    for (final sub in this) {
      if (sub.ref == ref) return sub;
    }
    return null;
  }

  SubAny locate(ValueRef ref) => maybeLocate(ref)!;
}

extension on ValueRef {
  void dispose() => switch (this) {
    DisposeGuard() => null,
    final ChangeNotifier changeNotifier => changeNotifier.dispose(),
    final AnimationController controller => controller.dispose(),
    final ValueAnimation<Object?> animation => animation.dispose(),
    _ => null,
  };
}

class _GetScopeState extends State<GetScope> with TickerProviderStateMixin, _AnimationProvider {
  late Iterable<SubAny> widgetSubs = widget.substitutes;
  late final widgetMap = <ValueRef, ValueRef>{
    for (final substitute in widgetSubs) substitute.ref: substitute.replacement,
  };

  @override
  void initState() {
    super.initState();
    assert(widgetSubs.debugCheckDuplicates(context));
  }

  late final VoidCallback rebuild = (context as Element).markNeedsBuild;
  late final clientSubstitutes = Get.map(<Element, Map<ValueRef, ValueRef>>{})
    ..hooked.addListener(rebuild);

  @override
  void didUpdateWidget(GetScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Iterable<SubAny> newSubs = widget.substitutes;
    assert(newSubs.debugCheckDuplicates(context));

    for (final ValueRef ref in widgetMap.keys) {
      if (newSubs.maybeLocate(ref) == null) {
        final ValueRef oldReplacement = widgetMap.remove(ref)!;
        final SubAny oldSub = widgetSubs.locate(ref);
        if (oldSub.autoDispose) oldReplacement.dispose();
      }
    }

    for (final SubAny newSub in newSubs) {
      if (widgetMap[newSub.ref] case final oldReplacement?) {
        final SubAny oldSub = widgetSubs.locate(newSub.ref);
        switch ((oldSub, newSub)) {
          case (_SubFactory(:final factory), _SubFactory(factory: final newFactory))
              when factory == newFactory:
          case (_SubGetFactory(:final factory), _SubGetFactory(factory: final newFactory))
              when factory == newFactory:
            continue;
        }
        final ValueRef newReplacement = newSub.replacement;
        if (newReplacement != oldReplacement) {
          widgetMap[newSub.ref] = newReplacement;
          if (oldSub.autoDispose) oldReplacement.dispose();
        }
      }
    }
  }

  @override
  void dispose() {
    clientSubstitutes.hooked.removeListener(rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = <ValueRef, ValueRef>{};

    for (final Map<ValueRef, ValueRef> refMap
        in clientSubstitutes.values.toList(growable: false).reversed) {
      for (final MapEntry(:key, :value) in refMap.entries) {
        map[key] ??= value;
      }
    }
    for (final MapEntry(:key, :value) in widgetMap.entries) {
      map[key] ??= value;
    }
    if (widget.inherit) {
      if (context.dependOnInheritedWidgetOfExactType<ScopeModel>() case final model?) {
        for (final MapEntry(:key, :value) in model.map.entries) {
          map[key] ??= value;
        }
      }
    }

    for (final Listenable value in map.values) {
      if (value is VsyncRef) registry.add(value);
    }

    return _OverrideContainer(child: ScopeModel(map: map, child: widget.child));
  }
}

typedef _StyleNotifier = ValueListenable<AnimationStyle>;
typedef _AnimationSet = Set<StyledAnimation<Object?>>;

mixin _AnimationProvider on State<GetScope>, TickerProvider implements Vsync {
  _AnimationSet? _animations;
  _StyleNotifier? _styleNotifier;

  void _updateStyles() {
    final _AnimationSet? animations = _animations;
    final AnimationStyle? style = _styleNotifier?.value;
    if (animations == null || style == null) {
      assert(throw StateError('animation set is $animations; style is $style\n$bugReport'));
      return;
    }

    for (final StyledAnimation<Object?> animation in animations) {
      animation.updateStyle(style);
    }
  }

  @override
  void registerAnimation(StyledAnimation<Object?> animation) {
    final _StyleNotifier notifier =
        _styleNotifier ??= DefaultAnimationStyle.getNotifier(context)..addListener(_updateStyles);

    (_animations ??= {}).add(animation);
    animation.updateStyle(notifier.value);
  }

  @override
  void unregisterAnimation(StyledAnimation<Object?> animation) {
    _animations?.remove(animation);
  }

  @override
  void activate() {
    super.activate();
    final _StyleNotifier newNotifier = DefaultAnimationStyle.getNotifier(context);
    if (newNotifier == _styleNotifier) return;

    _styleNotifier?.removeListener(_updateStyles);
    _styleNotifier = newNotifier..addListener(_updateStyles);
    _updateStyles();
  }

  @override
  void dispose() {
    _styleNotifier?.removeListener(_updateStyles);
    super.dispose();
  }
}

class _OverrideContainer extends InheritedWidget {
  const _OverrideContainer({required super.child});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  @override
  InheritedElement createElement() => _OverrideContainerElement(this);
}

class _OverrideContainerElement extends InheritedElement {
  _OverrideContainerElement(_OverrideContainer super.widget);

  @override
  void setDependencies(Element dependent, Object? value) {
    super.setDependencies(dependent, value);
    if (value is! Map<ValueRef, ValueRef>) {
      assert(
        throw ArgumentError(
          'GetScope expected a map of substitutions, got ${value.runtimeType}',
          'value',
        ),
      );
      return;
    }
    final Map<ValueRef, ValueRef> map = {...?clientSubstitutes.remove(dependent), ...value};
    clientSubstitutes[dependent] = map;
  }

  @override
  void removeDependent(Element dependent) {
    clientSubstitutes.remove(dependent);
    super.removeDependent(dependent);
  }

  late final clientSubstitutes = findAncestorStateOfType<_GetScopeState>()!.clientSubstitutes;
}

/// An [InheritedModel] used by [Ref] to store its [Override]s
/// and notify dependent widgets.
///
/// [Ref] contains methods which can be used in [Hook] functions
/// along with ___ render object stuff.
final class ScopeModel extends InheritedModel<ValueRef> {
  /// Creates an [InheritedModel] that stores [Override]s
  const ScopeModel({super.key, required this.map, required super.child});

  /// The override map.
  ///
  /// The key is the original object; the value is the new object.
  final Map<ValueRef, ValueRef> map;

  V? _select<V extends ValueRef>(V get) => switch (map[get]) {
    final V gotIt => gotIt,
    _ => null,
  };

  @override
  bool updateShouldNotify(ScopeModel oldWidget) {
    return !mapEquals(map, oldWidget.map);
  }

  @override
  bool updateShouldNotifyDependent(ScopeModel oldWidget, Set<ValueRef> dependencies) {
    for (final ValueRef dependency in dependencies) {
      if (_select(dependency) != oldWidget._select(dependency)) return true;
    }
    return false;
  }
}
