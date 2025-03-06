part of '../substitution.dart';

/// A widget that allows setting [Substitution]s for [Get] objects.
///
/// [ref] static methods will point to the objects specified in the [substitutes]
/// by default.
class SubScope<Interface extends Object> extends StatefulWidget {
  /// Enables [ref.watch] calls to point to new values,
  /// as specified by the [substitutes].
  const SubScope({
    super.key,
    this.substitutes = const {},
    this.inherit = true,
    required this.child,
  });

  /// An iterable (typically a [Set]) that points [Get] objects to new values.
  final Iterable<Substitution<Interface>> substitutes;

  /// The widget below this one in the tree.
  final Widget child;

  /// Whether this [SubScope] should also include substitutes from an ancestor scope,
  /// if applicable.
  ///
  /// Ancestor substitutes are ignored if the same value is substituted in this scope.
  final bool inherit;

  /// If the [Get] object is overridden in an ancestor [ref], returns that object.
  ///
  /// Returns `null` otherwise.
  static T? maybeOf<Interface extends Object, T>(
    BuildContext context,
    T placeholder, {
    bool createDependency = true,
  }) {
    final SubModel<Interface>? model =
        createDependency
            ? context.dependOnInheritedWidgetOfExactType()
            : context.getInheritedWidgetOfExactType();

    assert(() {
      final Object? scoped = model?.map[placeholder];
      if (scoped is T?) return true;

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
    }());

    return model?._select(placeholder);
  }

  /// Returns the [Get] object that overrides this one.
  ///
  /// If no such object is found, returns the object provided as input,
  /// or throws an error if [throwIfMissing] is true.
  ///
  /// See also:
  ///
  /// * [SubScope.maybeOf], which returns `null` if the relevant [Override]
  ///   is not found in the ancestor [ref].
  static T of<Interface extends Object, T>(
    BuildContext context,
    T placeholder, {
    bool createDependency = true,
    bool throwIfMissing = false,
  }) {
    assert(() {
      if (!throwIfMissing || maybeOf(context, placeholder) != null) return true;

      final SubScope? ancestor = context.getInheritedWidgetOfExactType();
      throw FlutterError.fromParts([
        if (ancestor == null)
          ErrorSummary('No ancestor Ref found.')
        else
          ErrorSummary('The $T was not found in the ancestor Ref.'),
        ErrorHint(
          'Double-check that the provided context contains an ancestor Ref '
          'with the appropriate Override.',
        ),
      ]);
    }());
    return maybeOf(context, placeholder, createDependency: createDependency) ?? placeholder;
  }

  /// Adds more substitutions to the existing ancestor [SubScope].
  ///
  /// These substitutes are automatically removed when the associated [BuildContext]
  /// is unmounted.
  static void add<Interface extends Object>(
    BuildContext context, {
    Map<Interface, Interface> map = const {},
    bool throwIfMissing = true,
  }) {
    final _OverrideContainer? container = context.dependOnInheritedWidgetOfExactType(aspect: map);

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
  State<SubScope> createState() => _SubScopeState();
}

extension<Interface extends Object> on Iterable<Substitution<Interface>> {
  bool debugCheckDuplicates([BuildContext? context]) {
    final refs = <Object>{};
    assert(debugCheckDuplicates(context));
    for (final Substitution(:ref) in this) {
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

  Substitution<Interface>? maybeLocate(Object? ref) {
    for (final sub in this) {
      if (sub.ref == ref) return sub;
    }
    return null;
  }

  Substitution<Interface> locate(Object? ref) => maybeLocate(ref)!;
}

extension on Object {
  void dispose() => switch (this) {
    DisposeGuard() => null,
    final ChangeNotifier changeNotifier => changeNotifier.dispose(),
    final AnimationController controller => controller.dispose(),
    final ValueAnimation<Object?> animation => animation.dispose(),
    _ => null,
  };
}

class _SubScopeState<Interface extends Object> extends State<SubScope<Interface>>
    with TickerProviderStateMixin, _AnimationProvider {
  late Iterable<Substitution<Interface>> widgetSubs = widget.substitutes;
  late final widgetMap = <Interface, Interface>{
    for (final substitute in widgetSubs) substitute.ref: substitute.replacement,
  };

  @override
  void initState() {
    super.initState();
    assert(widgetSubs.debugCheckDuplicates(context));
  }

  late final VoidCallback rebuild = (context as Element).markNeedsBuild;
  late final clientSubstitutes = MapNotifier(<Element, SubMap<Interface>>{})
    ..addListener(rebuild);

  @override
  void didUpdateWidget(SubScope<Interface> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Iterable<Substitution<Interface>> newSubs = widget.substitutes;
    assert(newSubs.debugCheckDuplicates(context));

    for (final Object ref in widgetMap.keys) {
      if (newSubs.maybeLocate(ref) == null) {
        final Object? oldReplacement = widgetMap.remove(ref);
        final Substitution<Interface> oldSub = widgetSubs.locate(ref);
        if (oldSub.autoDispose) oldReplacement?.dispose();
      }
    }

    for (final newSub in newSubs) {
      if (widgetMap[newSub.ref] case final oldReplacement?) {
        final Substitution<Interface> oldSub = widgetSubs.locate(newSub.ref);
        switch ((oldSub, newSub)) {
          case (_SubFactory(:final factory), _SubFactory(factory: final newFactory))
              when factory == newFactory:
            continue;
        }
        final Interface newReplacement = newSub.replacement;
        if (newReplacement != oldReplacement) {
          widgetMap[newSub.ref] = newReplacement;
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

  @override
  Widget build(BuildContext context) {
    final map = SubMap<Interface>();

    for (final Map<Interface, Interface> refMap
        in clientSubstitutes.values.toList(growable: false).reversed) {
      for (final MapEntry(:key, :value) in refMap.entries) {
        map[key] ??= value;
      }
    }
    for (final MapEntry(:key, :value) in widgetMap.entries) {
      map[key] ??= value;
    }
    if (widget.inherit) {
      if (context.dependOnInheritedWidgetOfExactType<SubModel<Interface>>() case final model?) {
        for (final MapEntry(:key, :value) in model.map.entries) {
          map[key] ??= value;
        }
      }
    }

    for (final Object value in map.values) {
      if (value is VsyncValue<Object?>) registry.add(value);
    }

    return _OverrideContainer(child: SubModel(map: map, child: widget.child));
  }
}

typedef _StyleNotifier = ValueListenable<AnimationStyle>;
typedef _AnimationSet = Set<StyledAnimation<Object?>>;

mixin _AnimationProvider<T extends Object> on State<SubScope<T>>, TickerProvider
    implements Vsync {
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

class _OverrideContainer<Interface extends Object> extends InheritedWidget {
  const _OverrideContainer({required super.child});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  @override
  InheritedElement createElement() => _OverrideContainerElement<Interface>(this);
}

class _OverrideContainerElement<Interface extends Object> extends InheritedElement {
  _OverrideContainerElement(_OverrideContainer super.widget);

  @override
  void setDependencies(Element dependent, Object? value) {
    super.setDependencies(dependent, value);
    if (value is! Map<Interface, Interface>) {
      assert(
        throw ArgumentError(
          'GetScope expected a map of substitutions, got ${value.runtimeType}',
          'value',
        ),
      );
      return;
    }
    final map = SubMap<Interface>({...?clientSubstitutes.remove(dependent), ...value});
    clientSubstitutes[dependent] = map;
  }

  @override
  void removeDependent(Element dependent) {
    clientSubstitutes.remove(dependent);
    super.removeDependent(dependent);
  }

  late final clientSubstitutes =
      findAncestorStateOfType<_SubScopeState<Interface>>()!.clientSubstitutes;
}

/// An [InheritedModel] used by [ref] to store its [Override]s
/// and notify dependent widgets.
///
/// [ref] contains methods which can be used in [Hook] functions
/// along with ___ render object stuff.
final class SubModel<Interface extends Object> extends InheritedModel<Interface> {
  /// Creates an [InheritedModel] that stores [Override]s
  const SubModel({super.key, required this.map, required super.child});

  /// The override map.
  ///
  /// The key is the original object; the value is the new object.
  final SubMap<Interface> map;

  V? _select<V>(V get) => switch (map[get]) {
    final V gotIt => gotIt,
    _ => null,
  };

  @override
  bool updateShouldNotify(SubModel oldWidget) => !mapEquals(map, oldWidget.map);

  @override
  bool updateShouldNotifyDependent(SubModel<Interface> oldWidget, Set<Interface> dependencies) {
    for (final Interface dependency in dependencies) {
      if (_select(dependency) != oldWidget._select(dependency)) return true;
    }
    return false;
  }
}
