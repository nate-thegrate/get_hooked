import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../utils/value_animation.dart';
import 'get_hooked.dart';

part 'ref/get_scope.dart';
part 'ref/ref_hooks.dart';

/// An [InheritedModel] used by [Ref] to store its [Override]s
/// and notify dependent widgets.
final class Ref extends InheritedModel<ValueRef> {
  /// Creates an [InheritedModel] that stores [Override]s
  // ignore: avoid_field_initializers_in_const_classes
  const Ref({super.key, required this.map, required super.child});

  const Ref._(this.map, {required super.child});

  /// The override map.
  ///
  /// The key is the original object; the value is the new object.
  final Map<ValueRef, ValueRef> map;

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
      }, [if (checkVsync) get]),
    );

    return use(_SelectHook(get.hooked, selector, watching));
  }

  /// Overrides the [Get] object accessed by [Ref.watch] with a new value
  /// using the object returned by calling the [factory].
  static G override<G extends GetAny>(
    G get,
    ValueGetter<Object> factory, {
    bool watching = false,
  }) {
    final BuildContext context = useContext();
    final G result = useMemoized(() {
      switch (factory()) {
        case final G g:
          assert(() {
            if (GetScope.maybeOf(context, get) != null) {
              return true;
            }
            throw FlutterError.fromParts([
              ErrorSummary(
                'Ref.override() called inside a BuildContext without an ancestor GetScope.',
              ),
              ErrorDescription(
                'Without a GetScope higher up in the widget tree, '
                'there is no place to store the override.',
              ),
              ErrorHint('Consider adding a GetScope widget, or removing this override.'),
            ]);
          }());
          GetScope.add(context, getObjects: {get: g});
          return g;

        case final Object invalid:
          throw ArgumentError(
            'Invalid factory passed to Ref.override() – '
            'expected $G, got ${invalid.runtimeType}',
          );
      }
    });
    useListenable(watching ? result.hooked : null);
    return result;
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

  G? _select<G extends GetAny>(G get) => switch (map[get.hooked]) {
    final G gotIt => gotIt,
    _ => null,
  };

  // ignore: annotate_overrides, name overlap
  bool updateShouldNotify(Ref oldWidget) {
    return !mapEquals(map, oldWidget.map);
  }

  // ignore: annotate_overrides, name overlap
  bool updateShouldNotifyDependent(Ref oldWidget, Set<ValueRef> dependencies) {
    for (final ValueRef dependency in dependencies) {
      final Get<Object?, ValueRef> get = Get.custom(dependency);
      if (_select(get) != oldWidget._select(get)) return true;
    }
    return false;
  }
}
