part of '../get_hooked.dart';

/// Mixin for [Get] objects with a [dispose] method.
///
/// {@macro get_hooked.AutoDispose}
mixin AutoDispose {
  /// {@template get_hooked.AutoDispose}
  /// [Ref] will automatically free associated resources when its associated
  /// [HookWidget] is no longer in use, so the `dispose()` method of a
  /// [ValueNotifier] or [AnimationController] is unnecessary.
  /// {@endtemplate}
  @visibleForOverriding
  void dispose() {
    assert(
      throw FlutterError.fromParts([
        ErrorSummary('$runtimeType.dispose() was invoked.'),
        ErrorDescription(
          '"Get" objects, including this $runtimeType, persist throughout the app\'s lifecycle, '
          'and calling "dispose" renders them unable to function from that point onward.',
        ),
        ErrorHint('Consider removing the dispose() invocation.'),
      ]),
    );
  }
}

class _ValueNotifier<T> = ValueNotifier<T> with AutoDispose;
class _ListNotifier<E> = ListNotifier<E> with AutoDispose;
class _SetNotifier<E> = SetNotifier<E> with AutoDispose;
class _MapNotifier<K, V> = MapNotifier<K, V> with AutoDispose;
class _AnimationController = AnimationController with AutoDispose;
class _ValueAnimation<T> = ValueAnimation<T> with AutoDispose;
class _AsyncController<T> = AsyncController<T> with AutoDispose;

// dart format off
class _ProxyNotifier<T, L extends Listenable>                = ProxyNotifier<T, L> with AutoDispose;
class _ProxyNotifier2<T, L1, L2>                             = ProxyNotifier2<T, L1, L2> with AutoDispose;
class _ProxyNotifier3<T, L1, L2, L3>                         = ProxyNotifier3<T, L1, L2, L3> with AutoDispose;
class _ProxyNotifier4<T, L1, L2, L3, L4>                     = ProxyNotifier4<T, L1, L2, L3, L4> with AutoDispose;
class _ProxyNotifier5<T, L1, L2, L3, L4, L5>                 = ProxyNotifier5<T, L1, L2, L3, L4, L5> with AutoDispose;
class _ProxyNotifier6<T, L1, L2, L3, L4, L5, L6>             = ProxyNotifier6<T, L1, L2, L3, L4, L5, L6> with AutoDispose;
class _ProxyNotifier7<T, L1, L2, L3, L4, L5, L6, L7>         = ProxyNotifier7<T, L1, L2, L3, L4, L5, L6, L7> with AutoDispose;
class _ProxyNotifier8<T, L1, L2, L3, L4, L5, L6, L7, L8>     = ProxyNotifier8<T, L1, L2, L3, L4, L5, L6, L7, L8> with AutoDispose;
class _ProxyNotifier9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9> = ProxyNotifier9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9> with AutoDispose;
// dart format on
