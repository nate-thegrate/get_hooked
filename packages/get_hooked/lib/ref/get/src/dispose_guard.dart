part of '../get.dart';

/// Mixin for [Get] objects with a [dispose] method.
///
/// {@macro get_hooked.DisposeGuard}
mixin DisposeGuard {
  /// {@template get_hooked.DisposeGuard}
  /// [Ref] will automatically free associated resources when its associated
  /// [HookWidget] is no longer in use, so the `dispose()` method of a
  /// [ValueNotifier] or [AnimationController] is unnecessary.
  ///
  /// The [DisposeGuard.dispose] method throws an error.
  /// {@endtemplate}
  @protected
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

class _ValueNotifier<T> = ValueNotifier<T> with DisposeGuard;
class _ListNotifier<E> = ListNotifier<E> with DisposeGuard;
class _SetNotifier<E> = SetNotifier<E> with DisposeGuard;
class _MapNotifier<K, V> = MapNotifier<K, V> with DisposeGuard;
class _AnimationControllerStyled = AnimationControllerStyled with DisposeGuard;
class _ValueAnimationStyled<T> = ValueAnimationStyled<T> with DisposeGuard;
class _AsyncNotifier<T> = AsyncNotifier<T> with DisposeGuard;
class _MediaQueryNotifier<T> = MediaQueryNotifier<T> with DisposeGuard;

// dart format off
class _ProxyNotifier<T, L extends Listenable>                = ProxyNotifier<T, L> with DisposeGuard;
class _ProxyNotifier2<T, L1, L2>                             = ProxyNotifier2<T, L1, L2> with DisposeGuard;
class _ProxyNotifier3<T, L1, L2, L3>                         = ProxyNotifier3<T, L1, L2, L3> with DisposeGuard;
class _ProxyNotifier4<T, L1, L2, L3, L4>                     = ProxyNotifier4<T, L1, L2, L3, L4> with DisposeGuard;
class _ProxyNotifier5<T, L1, L2, L3, L4, L5>                 = ProxyNotifier5<T, L1, L2, L3, L4, L5> with DisposeGuard;
class _ProxyNotifier6<T, L1, L2, L3, L4, L5, L6>             = ProxyNotifier6<T, L1, L2, L3, L4, L5, L6> with DisposeGuard;
class _ProxyNotifier7<T, L1, L2, L3, L4, L5, L6, L7>         = ProxyNotifier7<T, L1, L2, L3, L4, L5, L6, L7> with DisposeGuard;
class _ProxyNotifier8<T, L1, L2, L3, L4, L5, L6, L7, L8>     = ProxyNotifier8<T, L1, L2, L3, L4, L5, L6, L7, L8> with DisposeGuard;
class _ProxyNotifier9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9> = ProxyNotifier9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9> with DisposeGuard;
// dart format on
