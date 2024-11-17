import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../utils/proxy_notifier.dart';
import '../utils/value_animation.dart';
import 'get.dart';

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
  static Result select<Result, T>(
    Get<T, ValueListenable<T>> get,
    Result Function(T value) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'Ref.select';
    final BuildContext context = useContext();
    if (useScope) get = GetScope.of(context, get);

    _useVsyncValidation(get, checkVsync, label);

    return HookData.use(
      _Select1<Result, T>(get.hooked, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 2 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select2<Result, L1, L2>(
    L1 l1,
    L2 l2,
    Result Function(L1 l1, L2 l2) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select2';

    final BuildContext context = useContext();
    if (useScope) {
      if (l1 is GetAny) l1 = GetScope.of(context, l1);
      if (l2 is GetAny) l2 = GetScope.of(context, l2);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);

    return HookData.use(
      _Select2<Result, L1, L2>(l1, l2, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 3 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select3<Result, L1, L2, L3>(
    L1 l1,
    L2 l2,
    L3 l3,
    Result Function(L1 l1, L2 l2, L3 l3) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select3';

    final BuildContext context = useContext();
    if (useScope) {
      if (l1 is GetAny) l1 = GetScope.of(context, l1);
      if (l2 is GetAny) l2 = GetScope.of(context, l2);
      if (l3 is GetAny) l3 = GetScope.of(context, l3);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);

    return HookData.use(
      _Select3<Result, L1, L2, L3>(l1, l2, l3, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 4 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select4<Result, L1, L2, L3, L4>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    Result Function(L1 l1, L2 l2, L3 l3, L4 l4) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select4';

    final BuildContext context = useContext();
    if (useScope) {
      if (l1 is GetAny) l1 = GetScope.of(context, l1);
      if (l2 is GetAny) l2 = GetScope.of(context, l2);
      if (l3 is GetAny) l3 = GetScope.of(context, l3);
      if (l4 is GetAny) l4 = GetScope.of(context, l4);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);
    _useVsyncValidation(l4, checkVsync, label);

    return HookData.use(
      _Select4(l1, l2, l3, l4, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 5 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select5<Result, L1, L2, L3, L4, L5>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select5';

    final BuildContext context = useContext();
    if (useScope) {
      if (l1 is GetAny) l1 = GetScope.of(context, l1);
      if (l2 is GetAny) l2 = GetScope.of(context, l2);
      if (l3 is GetAny) l3 = GetScope.of(context, l3);
      if (l4 is GetAny) l4 = GetScope.of(context, l4);
      if (l5 is GetAny) l5 = GetScope.of(context, l5);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);
    _useVsyncValidation(l4, checkVsync, label);
    _useVsyncValidation(l5, checkVsync, label);

    return HookData.use(
      _Select5(l1, l2, l3, l4, l5, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 6 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select6<Result, L1, L2, L3, L4, L5, L6>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    L6 l6,
    Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select6';

    final BuildContext context = useContext();
    if (useScope) {
      if (l1 is GetAny) l1 = GetScope.of(context, l1);
      if (l2 is GetAny) l2 = GetScope.of(context, l2);
      if (l3 is GetAny) l3 = GetScope.of(context, l3);
      if (l4 is GetAny) l4 = GetScope.of(context, l4);
      if (l5 is GetAny) l5 = GetScope.of(context, l5);
      if (l6 is GetAny) l6 = GetScope.of(context, l6);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);
    _useVsyncValidation(l4, checkVsync, label);
    _useVsyncValidation(l5, checkVsync, label);
    _useVsyncValidation(l6, checkVsync, label);

    return HookData.use(
      _Select6(l1, l2, l3, l4, l5, l6, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 7 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select7<Result, L1, L2, L3, L4, L5, L6, L7>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    L6 l6,
    L7 l7,
    Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select7';

    final BuildContext context = useContext();
    if (useScope) {
      if (l1 is GetAny) l1 = GetScope.of(context, l1);
      if (l2 is GetAny) l2 = GetScope.of(context, l2);
      if (l3 is GetAny) l3 = GetScope.of(context, l3);
      if (l4 is GetAny) l4 = GetScope.of(context, l4);
      if (l5 is GetAny) l5 = GetScope.of(context, l5);
      if (l6 is GetAny) l6 = GetScope.of(context, l6);
      if (l7 is GetAny) l7 = GetScope.of(context, l7);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);
    _useVsyncValidation(l4, checkVsync, label);
    _useVsyncValidation(l5, checkVsync, label);
    _useVsyncValidation(l6, checkVsync, label);
    _useVsyncValidation(l7, checkVsync, label);

    return HookData.use(
      _Select7(l1, l2, l3, l4, l5, l6, l7, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 8 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select8<Result, L1, L2, L3, L4, L5, L6, L7, L8>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    L6 l6,
    L7 l7,
    L8 l8,
    Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7, L8 l8) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select8';

    final BuildContext context = useContext();
    if (useScope) {
      if (l1 is GetAny) l1 = GetScope.of(context, l1);
      if (l2 is GetAny) l2 = GetScope.of(context, l2);
      if (l3 is GetAny) l3 = GetScope.of(context, l3);
      if (l4 is GetAny) l4 = GetScope.of(context, l4);
      if (l5 is GetAny) l5 = GetScope.of(context, l5);
      if (l6 is GetAny) l6 = GetScope.of(context, l6);
      if (l7 is GetAny) l7 = GetScope.of(context, l7);
      if (l8 is GetAny) l8 = GetScope.of(context, l8);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);
    _useVsyncValidation(l4, checkVsync, label);
    _useVsyncValidation(l5, checkVsync, label);
    _useVsyncValidation(l6, checkVsync, label);
    _useVsyncValidation(l7, checkVsync, label);
    _useVsyncValidation(l8, checkVsync, label);

    return HookData.use(
      _Select8(l1, l2, l3, l4, l5, l6, l7, l8, selector, watching: watching),
      debugLabel: label,
    );
  }

  /// Computes a value by selecting from 9 complex objects,
  /// and triggers a rebuild when the result changes.
  ///
  /// Multiple values can be selected by returning a [Record] type.
  ///
  /// {@macro get_hooked.Ref.watch}
  static Result select9<Result, L1, L2, L3, L4, L5, L6, L7, L8, L9>(
    L1 l1,
    L2 l2,
    L3 l3,
    L4 l4,
    L5 l5,
    L6 l6,
    L7 l7,
    L8 l8,
    L9 l9,
    Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7, L8 l8, L9 l9) selector, {
    bool watching = true,
    bool checkVsync = true,
    bool useScope = true,
  }) {
    const label = 'select8';

    final BuildContext context = useContext();
    if (useScope) {
      if (l1 is GetAny) l1 = GetScope.of(context, l1);
      if (l2 is GetAny) l2 = GetScope.of(context, l2);
      if (l3 is GetAny) l3 = GetScope.of(context, l3);
      if (l4 is GetAny) l4 = GetScope.of(context, l4);
      if (l5 is GetAny) l5 = GetScope.of(context, l5);
      if (l6 is GetAny) l6 = GetScope.of(context, l6);
      if (l7 is GetAny) l7 = GetScope.of(context, l7);
      if (l8 is GetAny) l8 = GetScope.of(context, l8);
      if (l9 is GetAny) l9 = GetScope.of(context, l9);
    }

    _useVsyncValidation(l1, checkVsync, label);
    _useVsyncValidation(l2, checkVsync, label);
    _useVsyncValidation(l3, checkVsync, label);
    _useVsyncValidation(l4, checkVsync, label);
    _useVsyncValidation(l5, checkVsync, label);
    _useVsyncValidation(l6, checkVsync, label);
    _useVsyncValidation(l7, checkVsync, label);
    _useVsyncValidation(l8, checkVsync, label);
    _useVsyncValidation(l9, checkVsync, label);

    return HookData.use(
      _Select9(l1, l2, l3, l4, l5, l6, l7, l8, l9, selector, watching: watching),
      debugLabel: label,
    );
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
        : useAnimationStatus(const AlwaysStoppedAnimation(null), _emptyListener);

    use(_VsyncAttachHook<Controls>.new, data: get, key: get, debugLabel: 'Ref.vsync');
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

void _useVsyncValidation(Object? get, bool checkVsync, String debugLabel) {
  assert(
    useMemoized(() {
      if (!checkVsync) return true;
      // ignore: strict_raw_type, too verbose!
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
