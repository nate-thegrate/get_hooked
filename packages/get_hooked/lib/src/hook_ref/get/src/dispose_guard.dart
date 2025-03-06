part of '../get.dart';

class _ValueNotifier<T> = ValueNotifier<T> with DisposeGuard;
class _ListNotifier<E> = ListNotifier<E> with DisposeGuard;
class _SetNotifier<E> = SetNotifier<E> with DisposeGuard;
class _MapNotifier<K, V> = MapNotifier<K, V> with DisposeGuard;
class _AnimationControllerStyled = AnimationControllerStyled with DisposeGuard;
class _ValueAnimationStyled<T> = ValueAnimationStyled<T> with DisposeGuard;
class _AsyncNotifier<T> = AsyncNotifier<T> with DisposeGuard;
class _MediaQueryNotifier<T> = MediaQueryNotifier<T> with DisposeGuard;
class _ProxyNotifier<T, L extends Listenable> = ProxyNotifier<T, L> with DisposeGuard;
