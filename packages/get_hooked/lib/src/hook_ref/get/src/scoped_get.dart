part of '../get.dart';

/// Allows accessing the relevant value from an ancestor [SubScope] in a reasonably
/// concise manner.
extension GetFromContext on BuildContext {
  /// Allows accessing the relevant value from an ancestor [SubScope] in a reasonably
  /// concise manner.
  V get<V extends ValueListenable<Object?>>(
    V listenable, {
    bool createDependency = true,
    bool throwIfMissing = false,
  }) {
    return GetScope.of(
      this,
      listenable,
      createDependency: createDependency,
      throwIfMissing: throwIfMissing,
    );
  }
}

/// Allows [Substitution]s for [Get] objects.
class GetScope extends SubScope<_V> {
  /// Creates a widget that allows [Substitution]s for [Get] objects.
  const GetScope({super.key, super.substitutes, super.inherit = true, required super.child});

  /// Returns the [ValueListenable] object relevant to .
  ///
  /// If no such object is found, returns the object provided as input,
  /// or throws an error if [throwIfMissing] is true.
  ///
  /// See also:
  ///
  /// * [SubScope.maybeOf], which returns `null` if the relevant [Substitution]
  ///   is not found in the ancestor [ref].
  static V of<V extends ValueListenable<Object?>>(
    BuildContext context,
    V listenable, {
    bool createDependency = true,
    bool throwIfMissing = false,
  }) {
    return SubScope.of<_V, V>(
      context,
      listenable,
      createDependency: createDependency,
      throwIfMissing: throwIfMissing,
    );
  }

  /// If the [ValueListenable] object is subbed in an ancestor scope, returns that object.
  ///
  /// Returns `null` otherwise.
  static V? maybeOf<V extends ValueListenable<Object?>>(
    BuildContext context,
    V get, {
    bool createDependency = true,
    bool throwIfMissing = false,
  }) {
    return SubScope.maybeOf<_V, V>(context, get, createDependency: createDependency);
  }
}

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

  /// Placeholder for a [ComputedNotifier].
  @factory
  static GetComputed<Result> compute<Result>() => GetComputed._(_ScopeComputed());
}

class _ScopeValue<T> extends ScopedGet<T> implements ValueNotifier<T>, ValueAnimation<T> {}

class _ScopeList<E> extends ScopedGet<List<E>> implements ListNotifier<E> {}

class _ScopeSet<E> extends ScopedGet<Set<E>> implements SetNotifier<E> {}

class _ScopeMap<K, V> extends ScopedGet<Map<K, V>> implements MapNotifier<K, V> {}

class _ScopeVsync extends ScopedGet<double> implements VsyncDouble {}

class _ScopeAsync<T> extends ScopedGet<T?> implements AsyncNotifier<T> {}

class _ScopeComputed<Result> extends ScopedGet<Result> implements ComputedNoScope<Result> {}
