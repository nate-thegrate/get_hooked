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

  /// Placeholder for a [ListNotifier].
  @factory
  static GetList<E> list<E>([_]) => GetList._(_ScopeList());

  /// Placeholder for a [SetNotifier].
  @factory
  static GetSet<E> set<E>([_]) => GetSet._(_ScopeSet());

  /// Placeholder for a [MapNotifier].
  @factory
  static GetMap<K, V> map<K, V>([_]) => GetMap._(_ScopeMap());

  /// Placeholder for an [AnimationController].
  @factory
  static GetVsyncDouble vsync() => GetVsyncDouble._(_ScopeVsync());

  /// Placeholder for a [ValueAnimation].
  @factory
  static GetVsyncValue<T> vsyncValue<T>() => GetVsyncValue._(_ScopeValue());

  /// Placeholder for an [AsyncNotifier].
  @factory
  static GetAsync<T> async<T>() => GetAsync._(_ScopeAsync());

  /// Placeholder for an [AsyncNotifier].
  @factory
  static GetAsync<T> stream<T>() => GetAsync._(_ScopeAsync());

  /// Placeholder for a [ProxyNotifier].
  @factory
  static GetProxy<T, L> proxy<T, L extends Listenable>() => GetProxy._(_ScopeProxy());

  /// Placeholder for a [ComputedNotifier].
  @factory
  static GetComputed<Result> compute<Result>() => GetComputed._(_ScopeComputed());
}

class _ScopeValue<T> extends ScopedGet<T> implements ValueNotifier<T>, ValueAnimation<T> {}

class _ScopeList<E> extends ScopedGet<List<E>> implements ListNotifier<E> {}

class _ScopeSet<E> extends ScopedGet<Set<E>> implements SetNotifier<E> {}

class _ScopeMap<K, V> extends ScopedGet<Map<K, V>> implements MapNotifier<K, V> {}

class _ScopeVsync extends ScopedGet<double> implements AnimationControllerStyled {}

class _ScopeAsync<T> extends ScopedGet<T?> implements AsyncNotifier<T> {}

class _ScopeProxy<T, L extends Listenable> extends ScopedGet<T> implements ProxyNotifier<T, L> {}

class _ScopeComputed<Result> extends ScopedGet<Result> implements ComputedNoScope<Result> {}
