part of '../ref.dart';

/// A widget that allows setting [Override]s for [Get] objects.
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
  static G? maybeOf<G extends GetAny>(
    BuildContext context,
    G get, {
    bool createDependency = true,
  }) {
    final ScopeModel? model =
        createDependency
            ? context.dependOnInheritedWidgetOfExactType()
            : context.getInheritedWidgetOfExactType();

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
  static G of<G extends GetAny>(
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
    Map<GetAny, GetAny> getObjects = const {},
    Map<GetAny, ValueRef> listenables = const {},
    bool throwIfMissing = true,
  }) {
    final _OverrideContainer? container = context.dependOnInheritedWidgetOfExactType(
      aspect: {
        for (final MapEntry(:key, :value) in getObjects.entries) key: value.hooked,
        ...listenables,
      },
    );

    assert(() {
      if (container != null || !throwIfMissing) return true;

      throw FlutterError.fromParts([
        ErrorSummary('Ancestor GetScope not found.'),
        ErrorDescription(
          'GetScope.add() was called using a BuildContext '
          'that was unable to locate an ancestor GetScope.',
        ),
        ErrorDescription('The widget that attempted this call was:'),
        context.widget.toDiagnosticsNode(),
      ]);
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

class _GetScopeState extends State<GetScope> {
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
  late final clientOverrides = Get.map(<Element, Map<ValueRef, ValueRef>>{})
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

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   for (final ValueRef notifier in removed) {
    //     // ignore: invalid_use_of_protected_member, we need to know!
    //     if (notifier case ChangeNotifier(hasListeners: true)) {
    //       final String type = notifier.runtimeType.toString().replaceAll('_', '');
    //
    //       throw FlutterError.fromParts([
    //         ErrorSummary('$type not properly disposed.'),
    //         ErrorDescription(
    //           'Unlike most "Get" objects, the values passed as overrides in a Ref '
    //           "can be short-lived, if the scope's configuration changes.",
    //         ),
    //         ErrorHint(
    //           'Ensure that any listeners added to the object are removed '
    //           "when it's disposed of.",
    //         ),
    //         if (notifier is DisposeGuard)
    //           ErrorHint(
    //             'Alternatively, instead of using one of the "Get" constructors, '
    //             'extend the $type type directly, and use an Override(autoDispose: false).',
    //           )
    //         else
    //           ErrorHint(
    //             'Alternatively, use Override(autoDispose: false) to signify that '
    //             'this $type should be manually disposed of by the Ref.',
    //           ),
    //       ]);
    //     }
    //   }
    // });
  }

  @override
  void dispose() {
    clientOverrides.hooked.removeListener(rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = <ValueRef, ValueRef>{};

    for (final Map<ValueRef, ValueRef> refMap
        in clientOverrides.values.toList(growable: false).reversed) {
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

    return _OverrideContainer(child: ScopeModel(map: map, child: widget.child));
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
          'GetScope expected a map of overrides, got ${value.runtimeType}',
          'value',
        ),
      );
      return;
    }
    final Map<ValueRef, ValueRef> map = {...?clientOverrides.remove(dependent), ...value};
    clientOverrides[dependent] = map;
  }

  @override
  void removeDependent(Element dependent) {
    clientOverrides.remove(dependent);
    super.removeDependent(dependent);
  }

  late final clientOverrides = findAncestorStateOfType<_GetScopeState>()!.clientOverrides;
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

  G? _select<G extends GetAny>(G get) => switch (map[get.hooked]) {
    final G gotIt => gotIt,
    _ => null,
  };

  // ignore: annotate_overrides, name overlap
  bool updateShouldNotify(ScopeModel oldWidget) {
    return !mapEquals(map, oldWidget.map);
  }

  // ignore: annotate_overrides, name overlap
  bool updateShouldNotifyDependent(ScopeModel oldWidget, Set<ValueRef> dependencies) {
    for (final ValueRef dependency in dependencies) {
      final Get<Object?, ValueRef> get = Get.custom(dependency);
      if (_select(get) != oldWidget._select(get)) return true;
    }
    return false;
  }
}

void _useVsyncValidation(Object? get, bool checkVsync, String debugLabel) {
  assert(
    useMemoized(() {
      if (!checkVsync) return true;
      if (get case final GetVsyncAny getVsync when getVsync.vsync.context == null) {
        throw FlutterError.fromParts([
          ErrorSummary('$debugLabel() called with a non-attached Vsync.'),
          ErrorDescription(
            '$debugLabel() is intended to listen to an existing value, '
            'but the $getVsync has not been set up.',
          ),
          ErrorHint(
            'Consider setting up an ancestor widget with Ref.vsync(), '
            'or calling Ref.vsync() here instead of $debugLabel().',
          ),
          ErrorHint('Alternatively, call $debugLabel(checkVsync: false) to ignore this warning.'),
        ]);
      }
      return true;
    }, key: checkVsync ? get : null),
  );
}
