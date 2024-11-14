part of '../ref.dart';

/// A namespace for [Hook] functions that reference a [Get] object.
///
/// [Ref.new] (the class constructor) creates a widget containing a [GetScope].
class Ref extends StatefulWidget {
  /// Enables [Ref.watch] calls to point to new values,
  /// as specified by the [overrides].
  const Ref({super.key, required this.overrides, required this.child});

  /// An iterable (typically a [Set]) that points [Get] objects to new values.
  final Iterable<Override> overrides;

  /// The widget below this one in the tree.
  final Widget child;

  /// This hook function watches a [Get] object
  /// and triggers a rebuild when it sends a notification.
  ///
  /// {@template get_hooked.Ref.watch}
  /// Must be called inside a [HookWidget.build] method.
  ///
  /// Notifications are not sent when [watching] is `false`
  /// (changes to this value will apply the next time the [HookWidget]
  /// is built).
  ///
  /// If a [GetVsync] object is passed, this hook will check if the
  /// [Vsync] is attached to a [BuildContext] (which is typically achieved
  /// via [Ref.vsync]) and throws an error if it fails. The check can be
  /// bypassed by setting [checkVsync] to `false`.
  ///
  /// By default, if an ancestor [GetScope] overrides the [Get] object's
  /// value, the new object is used instead. Setting [useScope] to `false`
  /// will ignore any overrides.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  /// * [Ref.select], which allows rebuilding only when a specified part
  ///   of the listenable's value changes.
  /// * [GetScope.of], for retrieving an [Override]'s new value outside of
  ///   a [HookWidget.build] method.
  static T watch<T>(
    Get<T, ValueListenable<T>> get, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    return Ref.select(
      get,
      _selectAll<T>,
      watching: watching,
      checkVsync: checkVsync,
      useScope: useScope,
    );
  }

  /// Selects a value from a complex [Get] object and triggers a rebuild when
  /// the selected value changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Out select<In, Out>(
    Get<In, ValueListenable<In>> get,
    Out Function(In value) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    final BuildContext context = useContext();
    if (useScope) get = GetScope.of(context, get);

    assert(
      useMemoized(() {
        if (!checkVsync) return true;
        // ignore: strict_raw_type, too verbose!
        if (get case final GetVsyncAny getVsync when getVsync.vsync.context == null) {
          final method = 'Ref.${selector == (_selectAll<In>) ? 'watch' : 'select'}';
          throw FlutterError.fromParts([
            ErrorSummary('$method() called with a non-attached Vsync.'),
            ErrorDescription(
              '$method() is intended to listen to an existing value, '
              'but the $getVsync has not been set up.',
            ),
            ErrorHint(
              'Consider setting up an ancestor widget with Ref.vsync(), '
              'or calling Ref.vsync() here instead of $method().',
            ),
            ErrorHint('Alternatively, call $method(checkVsync: false) to ignore this warning.'),
          ]);
        }
        return true;
      }, [get, checkVsync]),
    );

    return use(_SelectHook(get.hooked, selector, watching));
  }

  /// Provides an interface for controlling a [GetVsync] animation,
  /// and optionally rebuilds when the animation sends a notification.
  ///
  ///  * If [watch] is true, each notification sent by the animation
  ///    triggers a rebuild.
  ///  * If a callback for [onStatusChange] is provided, it will run each time
  ///    the [AnimationStatus] changes.
  static Controls vsync<Controls extends GetVsyncAny>(
    Controls get, {
    bool watch = false,
    AnimationStatusListener? onStatusChange,
  }) {
    final Animation<Object?> animation = get.hooked;
    useListenable(watch ? animation : null);

    onStatusChange != null
        ? useAnimationStatus(animation, onStatusChange)
        : useAnimationStatus(null, _emptyListener);

    use(_VsyncAttachHook(get));

    return get;
  }

  @override
  State<Ref> createState() => _RefState();
}

/// Enables [Ref.watch] to point to a new value.
@immutable
class Override<V extends ValueRef> {
  /// Creates an object that enables [Ref.watch] to point to a new value.
  Override(
    Get<Object?, V> get, {
    required ValueGetter<Get<Object?, V>> overrideWith,
    this.autoDispose,
  }) : key = get.hooked,
       factory = overrideWith as ValueGetter<V>;

  /// Creates an object that enables [Ref.watch] to point to a new value.
  ///
  /// This constructor allows passing a [ValueListenable] constructor
  /// as the [overrideWith] argument, rather than needing to wrap it
  /// with [Get.custom] or something similar.
  Override.listenable(
    Get<Object?, V> get, {
    required ValueGetter<V> overrideWith,
    this.autoDispose,
  }) : key = get.hooked,
       factory = overrideWith;

  /// The original [ValueListenable] object
  /// (i.e. the [Get] object's "representation field").
  final V key;

  /// A callback (usually a constructor) that returns a modified value.
  final ValueGetter<V> factory;

  /// Whether the [Ref] widget should skip disposing the modified value.
  ///
  /// If `null`, it's determined by whether the [factory]'s output
  /// is a subtype of [AutoDispose].
  final bool? autoDispose;

  @override
  bool operator ==(Object other) {
    return other is Override && other.key == key && other.factory == factory;
  }

  @override
  int get hashCode => Object.hash(key, factory);
}

extension type _Overrides._(HashSet<Override<ValueRef>> set) implements Set<Override<ValueRef>> {
  _Overrides(Iterable<Override<ValueRef>> set) : set = HashSet.of(set);

  factory _Overrides._fromState(_RefState state) {
    return _Overrides(state.widget.overrides.toSet()).mergeWith(state.context);
  }

  Set<ValueRef> get gets => {for (final item in set) item.key};
  Set<ValueGetter<ValueRef>> get factories => {for (final item in set) item.factory};

  ValueGetter<ValueRef>? operator [](ValueRef key) {
    for (final Override<ValueRef> item in set) {
      if (item.key == key) return item.factory;
    }
    return null;
  }

  bool containsKey(ValueRef key) {
    for (final Override<ValueRef> item in set) {
      if (item.key == key) return true;
    }
    return false;
  }

  _Overrides mergeWith(BuildContext context) {
    final GetScope? scope = context.dependOnInheritedWidgetOfExactType();
    final _RefState? ancestor = scope?._state ?? context.findAncestorStateOfType();
    if (ancestor == null) return this;

    return _Overrides(union(ancestor.overrides));
  }
}

class _RefState extends State<Ref> {
  late _Overrides overrides = _Overrides._fromState(this);

  late Map<ValueRef, ValueRef> map = {
    for (final override in overrides) override.key: override.factory(),
  };

  @override
  void didUpdateWidget(Ref oldWidget) {
    super.didUpdateWidget(oldWidget);
    final _Overrides newOverrides = _Overrides._fromState(this);
    if (setEquals(overrides, newOverrides)) return;

    final _Overrides removedOverrides = _Overrides(overrides.difference(newOverrides));
    Set<ValueRef>? removedNotifiers;
    for (final node in removedOverrides) {
      assert(() {
        if (map[node.key] case final notifier?) {
          (removedNotifiers ??= {}).add(notifier);
          return true;
        }
        throw StateError('Override not found for ${node.key}');
      }());

      final ValueRef? removed = map.remove(node.key);
      switch (node.autoDispose) {
        case true:
        case null when removed is AutoDispose:
          break;
        case false || null:
          removed?._dispose();
      }
      if (newOverrides[node.key] case final factory?) {
        map[node.key] = factory();
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
          if (!(autoDispose ?? notifier is AutoDispose)) notifier._dispose();
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
  Widget build(BuildContext context) => GetScope._(this, map, child: widget.child);
}

/// An [InheritedModel] used by [Ref] to store its [Override]s
/// and notify dependent widgets.
final class GetScope extends InheritedModel<ValueRef> {
  /// Creates an [InheritedModel] that stores [Override]s
  // ignore: avoid_field_initializers_in_const_classes
  const GetScope({super.key, required this.map, required super.child}) : _state = null;

  const GetScope._(this._state, this.map, {required super.child});

  /// The override map.
  ///
  /// The key is the original object; the value is the new object.
  final Map<ValueRef, ValueRef> map;

  final _RefState? _state;

  /// If the [Get] object is overridden in an ancestor [Ref], returns that object.
  ///
  /// Returns `null` otherwise.
  static G? maybeOf<G extends GetAny>(
    BuildContext context,
    G get, {
    bool createDependency = true,
  }) {
    final GetScope? scope =
        createDependency
            ? context.dependOnInheritedWidgetOfExactType()
            : context.getInheritedWidgetOfExactType();

    return scope?._select(get);
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

  G? _select<G extends GetAny>(G get) => switch (map[get.hooked]) {
    final G gotIt => gotIt,
    _ => null,
  };

  @override
  bool updateShouldNotify(GetScope oldWidget) {
    return !mapEquals(map, oldWidget.map);
  }

  @override
  bool updateShouldNotifyDependent(GetScope oldWidget, Set<ValueRef> dependencies) {
    for (final ValueRef dependency in dependencies) {
      final Get<Object?, ValueRef> get = Get.custom(dependency);
      if (_select(get) != oldWidget._select(get)) return true;
    }
    return false;
  }
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
