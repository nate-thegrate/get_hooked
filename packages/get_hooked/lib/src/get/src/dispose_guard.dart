part of '../get.dart';

class _ValueNotifier<T> = ValueNotifier<T> with StrictNotifier, DisposeGuard;
class _ListNotifier<E> = ListNotifier<E> with StrictNotifier, DisposeGuard;
class _SetNotifier<E> = SetNotifier<E> with StrictNotifier, DisposeGuard;
class _MapNotifier<K, V> = MapNotifier<K, V> with StrictNotifier, DisposeGuard;
class _VsyncDouble = VsyncDouble with StrictNotifier, DisposeGuard;
class _ValueAnimation<T> = ValueAnimation<T> with StrictNotifier, DisposeGuard;
class _AsyncNotifier<T> = AsyncNotifier<T> with StrictNotifier, DisposeGuard;
class _MediaQueryNotifier<T> = MediaQueryNotifier<T> with StrictNotifier, DisposeGuard;
class _ProxyNotifier<T, L extends Listenable> = ProxyNotifier<T, L>
    with StrictNotifier, DisposeGuard;
