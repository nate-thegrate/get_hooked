import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../utils/proxy_notifier.dart';
import '../utils/value_animation.dart';
import 'get.dart';
import 'hooked/_hooked.dart';

part 'ref/get_scope.dart';
part 'ref/ref_hooks.dart';
part 'ref/substitute.dart';

extension<T> on T {
  T of(BuildContext context) {
    if (this case final GetAny get) {
      if (GetScope.of<GetAny>(context, get) case final T result) return result;
    }
    return this;
  }
}

typedef GetFactory<V extends ValueRef> = ValueGetter<Get<Object?, V>>;

extension type Ref<V extends ValueRef>(Get<Object?, V> _get) implements Object {
  Substitute<V> sub(Get<Object?, V> newGet) => subListenable(newGet.hooked);

  Substitute<V> subListenable(V newListenable) => _SubEager(_get.hooked, newListenable);

  Substitute<V> subFactory(GetFactory<V> factory) => _SubGetFactory(_get.hooked, factory);

  Substitute<V> subListenableFactory(ValueGetter<V> factory) => _SubFactory(_get.hooked, factory);

  /// This hook function returns a copy of the provided [Get] object,
  /// overriding it with any replacement in an ancestor [GetScope] if applicable.
  ///
  /// Unlike [Ref.watch], this method does not subscribe to any notifications
  /// from the object.
  static G read<G extends GetAny>(
    G get, {
    bool createDependency = true,
    bool throwIfMissing = false,
  }) {
    return GetScope.of(
      useContext(),
      get,
      createDependency: createDependency,
      throwIfMissing: throwIfMissing,
    );
  }

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
    const label = 'Ref.watch';
    if (useScope) get = GetScope.of(useContext(), get);
    if (Hooked.renderer case final hooked?) {
      return hooked.select(get.hooked, () => _selectAll(get.value));
    }

    _useVsyncValidation(get, checkVsync, label);

    return HookData.use(
      _Select1<T, T>(get.hooked, _selectAll<T>, watching: watching),
      debugLabel: label,
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
    if (Hooked.renderer case final hooked?) {
      return hooked.select(get.hooked, () => selector(get.value));
    }

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
      l1 = l1.of(context);
      l2 = l2.of(context);
    }
    if (Hooked.renderer case final hooked?) {
      return hooked.select(ProxyListenable(l1, l2), () => selector(l1, l2));
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
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
    }
    if (Hooked.renderer case final hooked?) {
      return hooked.select(ProxyListenable(l1, l2, l3), () => selector(l1, l2, l3));
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
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
      l4 = l4.of(context);
    }
    if (Hooked.renderer case final hooked?) {
      return hooked.select(ProxyListenable(l1, l2, l3, l4), () => selector(l1, l2, l3, l4));
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
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
      l4 = l4.of(context);
      l5 = l5.of(context);
    }
    if (Hooked.renderer case final hooked?) {
      return hooked.select(
        ProxyListenable(l1, l2, l3, l4, l5),
        () => selector(l1, l2, l3, l4, l5),
      );
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
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
      l4 = l4.of(context);
      l5 = l5.of(context);
      l6 = l6.of(context);
    }
    if (Hooked.renderer case final hooked?) {
      return hooked.select(
        ProxyListenable(l1, l2, l3, l4, l5, l6),
        () => selector(l1, l2, l3, l4, l5, l6),
      );
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
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
      l4 = l4.of(context);
      l5 = l5.of(context);
      l6 = l6.of(context);
      l7 = l7.of(context);
    }
    if (Hooked.renderer case final hooked?) {
      return hooked.select(
        ProxyListenable(l1, l2, l3, l4, l5, l6, l7),
        () => selector(l1, l2, l3, l4, l5, l6, l7),
      );
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
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
      l4 = l4.of(context);
      l5 = l5.of(context);
      l6 = l6.of(context);
      l7 = l7.of(context);
      l8 = l8.of(context);
    }
    if (Hooked.renderer case final hooked?) {
      return hooked.select(
        ProxyListenable(l1, l2, l3, l4, l5, l6, l7, l8),
        () => selector(l1, l2, l3, l4, l5, l6, l7, l8),
      );
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
      l1 = l1.of(context);
      l2 = l2.of(context);
      l3 = l3.of(context);
      l4 = l4.of(context);
      l5 = l5.of(context);
      l6 = l6.of(context);
      l7 = l7.of(context);
      l8 = l8.of(context);
      l9 = l9.of(context);
    }
    if (Hooked.renderer case final hooked?) {
      return hooked.select(
        ProxyListenable(l1, l2, l3, l4, l5, l6, l7, l8, l9),
        () => selector(l1, l2, l3, l4, l5, l6, l7, l8, l9),
      );
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

  /// Provides an interface for controlling a [GetVsync] animation,
  /// and optionally rebuilds when the animation sends a notification.
  ///
  /// If [watch] is true, each notification sent by the animation
  /// triggers a rebuild.
  static Controls vsync<Controls extends GetVsyncAny>(Controls get, {bool watch = false}) {
    final Controls scoped = GetScope.of(useContext(), get);
    if (Hooked.renderer case final hooked?) {
      hooked.vsync(scoped.vsync);
      return scoped;
    }
    useListenable(watch ? scoped.hooked : null);

    use(_VsyncHook.new, key: scoped, data: scoped, debugLabel: 'Ref.vsync');
    return scoped;
  }
}
