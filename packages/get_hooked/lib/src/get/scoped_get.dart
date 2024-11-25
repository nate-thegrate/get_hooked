part of '../get.dart';

/// Might as well use a fun little class for the scope errors!
class GetScopeError extends UnsupportedError {
  /// Might as well use a fun little class for the scope errors!
  GetScopeError(super.message);
}

/// Creates pseudo-[Get] objects that throw when properties are accessed.
///
/// `ScopedGet` can be used to define a top-level Get object, to ensure that it's only used
/// in the correct scope.
class ScopedGet<T> implements ValueListenable<T> {
  /// [ScopedGet] "implements" any interface by throwing an error
  /// any time an attempt is made to access an instance member.
  @override
  Never noSuchMethod(Invocation invocation) {
    throw GetScopeError('Attempted to access ${invocation.memberName} on $this');
  }

  @override
  String toString() => describeIdentity(this);

  /// Placeholder for a [ValueNotifier].
  @factory
  static GetValue<T> it<T>([_]) => GetValue._(_ScopeValue());

  /// Placeholder for a [ListNotifier] that can be used as a [List] directly.
  @factory
  static GetList<E> list<E>([_]) => GetList._(_ScopeList());

  /// Placeholder for a [SetNotifier] that can be used as a [Set] directly.
  @factory
  static GetSet<E> set<E>([_]) => GetSet._(_ScopeSet());

  /// Placeholder for a [MapNotifier] that can be used as a [Map] directly.
  @factory
  static GetMap<K, V> map<K, V>([_]) => GetMap._(_ScopeMap());

  /// Placeholder for an [AnimationController].
  @factory
  static GetVsyncDouble vsync() => GetVsyncDouble._(_ScopeVsync());

  /// Placeholder for a [ValueAnimation].
  @factory
  static GetVsyncValue<T> vsyncValue<T>() => GetVsyncValue._(_ScopeValue());

  /// Placeholder for an [AsyncController].
  @factory
  static GetAsync<T> async<T>() => GetAsync._(_ScopeAsync());

  /// Placeholder for an [AsyncController].
  @factory
  static GetAsync<T> stream<T>() => GetAsync._(_ScopeAsync());

  /// Placeholder for a [ProxyNotifier].
  @factory
  static GetProxy<T, L> proxy<T, L extends Listenable>() => GetProxy._(_ScopeProxy());

  // dart format off
  /// Placeholder for a [ProxyNotifier2].
  @factory
  static GetProxy2<T, L1, L2> proxy2<T, L1, L2>() => GetProxy2._(_ScopeProxy2());
  /// Placeholder for a [ProxyNotifier3].
  @factory
  static GetProxy3<T, L1, L2, L3> proxy3<T, L1, L2, L3>() => GetProxy3._(_ScopeProxy3());
  /// Placeholder for a [ProxyNotifier4].
  @factory
  static GetProxy4<T, L1, L2, L3, L4> proxy4<T, L1, L2, L3, L4>() => GetProxy4._(_ScopeProxy4());
  /// Placeholder for a [ProxyNotifier5].
  @factory
  static GetProxy5<T, L1, L2, L3, L4, L5> proxy5<T, L1, L2, L3, L4, L5>() => GetProxy5._(_ScopeProxy5());
  /// Placeholder for a [ProxyNotifier6].
  @factory
  static GetProxy6<T, L1, L2, L3, L4, L5, L6> proxy6<T, L1, L2, L3, L4, L5, L6>() => GetProxy6._(_ScopeProxy6());
  /// Placeholder for a [ProxyNotifier7].
  @factory
  static GetProxy7<T, L1, L2, L3, L4, L5, L6, L7> proxy7<T, L1, L2, L3, L4, L5, L6, L7>() => GetProxy7._(_ScopeProxy7());
  /// Placeholder for a [ProxyNotifier8].
  @factory
  static GetProxy8<T, L1, L2, L3, L4, L5, L6, L7, L8> proxy8<T, L1, L2, L3, L4, L5, L6, L7, L8>() => GetProxy8._(_ScopeProxy8());
  /// Placeholder for a [ProxyNotifier9].
  @factory
  static GetProxy9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9> proxy9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9>() => GetProxy9._(_ScopeProxy9());
  // dart format on
}

class _ScopeValue<T> extends ScopedGet<T> implements ValueNotifier<T>, ValueAnimation<T> {}

class _ScopeList<E> extends ScopedGet<List<E>> implements ListNotifier<E> {}

class _ScopeSet<E> extends ScopedGet<Set<E>> implements SetNotifier<E> {}

class _ScopeMap<K, V> extends ScopedGet<Map<K, V>> implements MapNotifier<K, V> {}

class _ScopeVsync extends ScopedGet<double> implements AnimationController {}

class _ScopeAsync<T> extends ScopedGet<AsyncSnapshot<T>> implements AsyncController<T> {}

class _ScopeProxy<T, L extends Listenable> extends ScopedGet<T> implements ProxyNotifier<T, L> {}

// dart format off
class _ScopeProxy2<T, L1, L2> extends ScopedGet<T> implements ProxyNotifier2<T, L1, L2> {}
class _ScopeProxy3<T, L1, L2, L3> extends ScopedGet<T> implements ProxyNotifier3<T, L1, L2, L3> {}
class _ScopeProxy4<T, L1, L2, L3, L4> extends ScopedGet<T> implements ProxyNotifier4<T, L1, L2, L3, L4> {}
class _ScopeProxy5<T, L1, L2, L3, L4, L5> extends ScopedGet<T> implements ProxyNotifier5<T, L1, L2, L3, L4, L5> {}
class _ScopeProxy6<T, L1, L2, L3, L4, L5, L6> extends ScopedGet<T> implements ProxyNotifier6<T, L1, L2, L3, L4, L5, L6> {}
class _ScopeProxy7<T, L1, L2, L3, L4, L5, L6, L7> extends ScopedGet<T> implements ProxyNotifier7<T, L1, L2, L3, L4, L5, L6, L7> {}
class _ScopeProxy8<T, L1, L2, L3, L4, L5, L6, L7, L8> extends ScopedGet<T> implements ProxyNotifier8<T, L1, L2, L3, L4, L5, L6, L7, L8> {}
class _ScopeProxy9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9> extends ScopedGet<T> implements ProxyNotifier9<T, L1, L2, L3, L4, L5, L6, L7, L8, L9> {}
// dart format on
