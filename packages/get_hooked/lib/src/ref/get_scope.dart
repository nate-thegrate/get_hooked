part of '../ref.dart';

/// A namespace for [Hook] functions that reference a [Get] object.
///
/// [Ref.new] (the class constructor) creates a widget containing a [GetScope].
class GetScope extends StatefulWidget {
  /// Enables [Ref.watch] calls to point to new values,
  /// as specified by the [overrides].
  const GetScope({super.key, this.overrides = const {}, required this.child});

  /// An iterable (typically a [Set]) that points [Get] objects to new values.
  final Iterable<AnyOverride> overrides;

  /// The widget below this one in the tree.
  final Widget child;

  /// If the [Get] object is overridden in an ancestor [Ref], returns that object.
  ///
  /// Returns `null` otherwise.
  static G? maybeOf<G extends GetAny>(
    BuildContext context,
    G get, {
    bool createDependency = true,
  }) {
    final Ref? ref =
        createDependency
            ? context.dependOnInheritedWidgetOfExactType()
            : context.getInheritedWidgetOfExactType();

    return ref?._select(get);
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

  /// Adds additional overrides to the ancestor [GetScope].
  ///
  /// Rather than an [Override] object, this method uses a [Map].
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

class _GetScopeState extends State<GetScope> {
  late _Overrides overrides = _Overrides(widget.overrides)..validateKeys(context);

  late Map<ValueRef, ValueRef> map = {
    for (final override in overrides) override.key: override.factory(),
  };

  late final VoidCallback rebuild = (context as Element).markNeedsBuild;
  late final clientOverrides = Get.map(<Element, Map<ValueRef, ValueRef>>{})
    ..hooked.addListener(rebuild);

  @override
  void didUpdateWidget(GetScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    final _Overrides newOverrides = _Overrides(widget.overrides)..validateKeys(context);
    if (setEquals(overrides, newOverrides)) return;

    final _Overrides removedOverrides = _Overrides(overrides.difference(newOverrides));
    Set<ValueRef>? removedNotifiers;
    for (final Override(:key, :autoDispose) in removedOverrides) {
      assert(() {
        if (map[key] case final notifier?) {
          (removedNotifiers ??= {}).add(notifier);
          return true;
        }
        throw StateError('Override not found for $key');
      }());

      final ValueRef? removed = map.remove(key);
      if (!autoDispose && removed is! AutoDispose?) {
        removed._dispose();
      }
      if (newOverrides[key] case final factory?) {
        map[key] = factory();
      }
    }
    final newMap = <ValueRef, ValueRef>{};
    for (final Override(:key, :factory, :autoDispose) in newOverrides) {
      if (overrides.contains(override)) {
        newMap[key] = map[key]!;
      } else {
        if (map[key] case final notifier?) {
          assert(() {
            (removedNotifiers ??= {}).add(notifier);
            return true;
          }());
          if (!autoDispose && notifier is! AutoDispose) notifier._dispose();
        }
        newMap[key] = factory();
      }
    }
    overrides = newOverrides;
    map = newMap;

    assert(() {
      final removed = removedNotifiers;
      if (removed == null) return true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final ValueRef notifier in removed) {
          // ignore: invalid_use_of_protected_member, we need to know!
          if (notifier case ChangeNotifier(hasListeners: true)) {
            final String type = notifier.runtimeType.toString().replaceAll('_', '');

            throw FlutterError.fromParts([
              ErrorSummary('$type not properly disposed.'),
              ErrorDescription(
                'Unlike most "Get" objects, the values passed as overrides in a Ref '
                "can be short-lived, if the scope's configuration changes.",
              ),
              ErrorHint(
                'Ensure that any listeners added to the object are removed '
                "when it's disposed of.",
              ),
              if (notifier is AutoDispose)
                ErrorHint(
                  'Alternatively, instead of using one of the "Get" constructors, '
                  'extend the $type type directly, and use an Override(autoDispose: false).',
                )
              else
                ErrorHint(
                  'Alternatively, use Override(autoDispose: false) to signify that '
                  'this $type should be manually disposed of by the Ref.',
                ),
            ]);
          }
        }
      });
      return true;
    }());
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
    for (final MapEntry(:key, :value) in this.map.entries) {
      map[key] ??= value;
    }
    if (context.dependOnInheritedWidgetOfExactType<Ref>() case final ref?) {
      for (final MapEntry(:key, :value) in ref.map.entries) {
        map[key] ??= value;
      }
    }

    return _OverrideContainer(child: Ref._(map, child: widget.child));
  }
}

/// Shorthand for [Override] with generic type arguments.
typedef AnyOverride = Override<Object?, ValueListenable<Object?>>;

/// Enables [Ref.watch] to point to a new value.
@immutable
final class Override<T, V extends ValueListenable<T>> with Diagnosticable {
  /// Creates an object that enables [Ref.watch] to point to a new value.
  Override(
    Get<T, V> get, {
    required ValueGetter<Get<T, V>> overrideWith,
    this.autoDispose = false,
  }) : key = get.hooked,
       factory = overrideWith as ValueGetter<V>;

  /// Creates an object that enables [Ref.watch] to point to a new value.
  ///
  /// This constructor allows passing a [ValueListenable] constructor
  /// as the [overrideWith] argument, rather than needing to wrap it
  /// with [Get.custom] or something similar.
  Override.listenable(
    Get<T, V> get, {
    required ValueGetter<V> overrideWith,
    this.autoDispose = false,
  }) : key = get.hooked,
       factory = overrideWith;

  /// The original [ValueListenable] object
  /// (i.e. the [Get] object's "representation field").
  final V key;

  /// A callback (usually a constructor) that returns a modified value.
  final ValueGetter<V> factory;

  /// Whether the [GetScope] widget should skip disposing the modified value.
  ///
  /// If the [factory]'s output is a subtype of [AutoDispose], this value is ignored
  /// and disposing is always skipped.
  final bool autoDispose;

  /// [autoDispose] is intentionally ignored :)
  @override
  bool operator ==(Object other) {
    return other is Override && other.key == key && other.factory == factory;
  }

  @override
  int get hashCode => Object.hash(key, factory);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('key', key));
    properties.add(DiagnosticsProperty.lazy('factory', factory));
    properties.add(FlagProperty('autoDispose', value: autoDispose, defaultValue: false));
  }
}

extension type _Overrides._(Set<AnyOverride> set) implements Set<AnyOverride> {
  _Overrides(Iterable<AnyOverride> set) : set = HashSet.of(set);

  Set<ValueRef> get gets => {for (final item in set) item.key};
  Set<ValueGetter<ValueRef>> get factories => {for (final item in set) item.factory};

  ValueGetter<ValueRef>? operator [](ValueRef key) {
    for (final AnyOverride item in set) {
      if (item.key == key) return item.factory;
    }
    return null;
  }

  bool containsKey(ValueRef key) {
    for (final AnyOverride item in set) {
      if (item.key == key) return true;
    }
    return false;
  }

  bool validateKeys([BuildContext? context]) {
    assert(() {
      final keys = <ValueRef>{};
      for (final override in this) {
        final ValueRef key = override.key;
        if (!keys.add(key)) {
          throw FlutterError.fromParts([
            ErrorSummary('Duplicate overrides found for the same Get object.'),
            for (final override in this)
              if (override.key == key) override.toDiagnosticsNode(),
            ErrorDescription(
              'A Get object representing a ${key.runtimeType} '
              'was assigned multiple overrides in this collection.',
            ),
            if (context != null) ...[
              ErrorDescription('These overrides were added by the following widget:'),
              context.widget.toDiagnosticsNode(),
            ],
          ]);
        }
      }
      return true;
    }());
    return true;
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

extension on ValueRef {
  void _dispose() {
    switch (this) {
      case AutoDispose():
        assert(() {
          final String suggestion = switch (this) {
            ValueAnimation() => 'a ValueAnimation instance',
            AnimationController() => 'an AnimationController instance',
            ValueNotifier() => 'a ValueNotifier instance',
            _ => 'a class that mixes in ChangeNotifier (but not AutoDispose)',
          };

          throw FlutterError.fromParts([
            ErrorSummary(
              'Override(autoDispose: false) set for a listenable with the AutoDispose mixin.',
            ),
            ErrorHint('Consider using $suggestion instead.'),
          ]);
        }());
      case final ChangeNotifier notifier:
        notifier.dispose();
      case final AnimationController controller:
        controller.dispose();
      case final ValueAnimation<Object?> animation:
        animation.dispose();
    }
  }
}
