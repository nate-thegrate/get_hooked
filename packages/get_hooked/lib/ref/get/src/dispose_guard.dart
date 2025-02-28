part of '../get.dart';

/// Mixin for [Get] objects with a [dispose] method.
///
/// {@macro get_hooked.DisposeGuard}
mixin DisposeGuard on Listenable {
  @protected
  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
  }

  @protected
  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
  }

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
          'This $runtimeType uses the "dispose guard" mixin, which is meant for '
          "Listenable objects that persist throughout the app's lifecycle.",
        ),
        ErrorDescription(
          'Calling the `dispose()` method renders the object unable to function '
          'from that point onward.',
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
// dart format on
